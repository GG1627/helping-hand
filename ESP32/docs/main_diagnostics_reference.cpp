#include <Arduino.h>
#include <BLEDevice.h>
#include <Wire.h>

// Board variant-defined I2C pins (Feather ESP32-S3 => SDA=3, SCL=4).
constexpr int I2C_SDA_PIN = SDA;
constexpr int I2C_SCL_PIN = SCL;

constexpr uint8_t MPU_ADDR_LOW = 0x68;   // AD0 tied LOW/GND
constexpr uint8_t MPU_ADDR_HIGH = 0x69;  // AD0 tied HIGH/VCC
constexpr uint8_t MPU_REG_WHO_AM_I = 0x75;
constexpr uint8_t KNOWN_IMU_ADDRS[] = {0x68, 0x69, 0x6A, 0x6B};

bool wireReady = false;
bool mpuReady = false;
uint8_t activeMpuAddress = 0x00;
uint8_t activeWhoAmI = 0x00;
unsigned long lastDiagMs = 0;

const char* i2cErrorToText(uint8_t error) {
  switch (error) {
    case 0: return "OK";
    case 1: return "DATA_TOO_LONG";
    case 2: return "NACK_ON_ADDRESS";
    case 3: return "NACK_ON_DATA";
    case 4: return "OTHER_ERROR";
    case 5: return "TIMEOUT";
    default: return "UNKNOWN";
  }
}

void printDivider(const char* label) {
  Serial.println();
  Serial.println("==================================================");
  Serial.printf("%s\n", label);
  Serial.println("==================================================");
}

void printSystemInfo() {
  printDivider("SYSTEM INFO");
  Serial.printf("Chip Model: %s\n", ESP.getChipModel());
  Serial.printf("Chip Rev: %d\n", ESP.getChipRevision());
  Serial.printf("CPU Freq: %lu MHz\n", ESP.getCpuFreqMHz());
  Serial.printf("SDK: %s\n", ESP.getSdkVersion());
  Serial.printf("Free Heap: %u bytes\n", ESP.getFreeHeap());
}

void printI2CPinInfo() {
  printDivider("I2C PIN CONFIG");
  Serial.printf("Configured SDA: GPIO %d\n", I2C_SDA_PIN);
  Serial.printf("Configured SCL: GPIO %d\n", I2C_SCL_PIN);
  Serial.printf("SDA valid: %s\n", digitalPinIsValid(I2C_SDA_PIN) ? "yes" : "no");
  Serial.printf("SCL valid: %s\n", digitalPinIsValid(I2C_SCL_PIN) ? "yes" : "no");
#if defined(PIN_I2C_POWER)
  Serial.printf("I2C power pin: GPIO %d\n", PIN_I2C_POWER);
#else
  Serial.println("I2C power pin: not defined on this board variant");
#endif
}

void printLineState(const char* modeLabel, int sdaPin, int sclPin, uint8_t pinModeValue) {
  pinMode(sdaPin, pinModeValue);
  pinMode(sclPin, pinModeValue);
  delay(2);
  const int sda = digitalRead(sdaPin);
  const int scl = digitalRead(sclPin);
  Serial.printf("%s -> SDA=%d SCL=%d\n", modeLabel, sda, scl);
}

void electricalLineDiagnostics(int sdaPin, int sclPin) {
  printDivider("I2C LINE ELECTRICAL CHECK");
  if (!digitalPinIsValid(sdaPin) || !digitalPinIsValid(sclPin)) {
    Serial.println("Skipping line check: invalid pin(s).");
    return;
  }

  Serial.println("Expected healthy idle bus: SDA=1 and SCL=1.");
  printLineState("INPUT mode", sdaPin, sclPin, INPUT);
  printLineState("INPUT_PULLUP mode", sdaPin, sclPin, INPUT_PULLUP);
  Serial.println("If either line stays LOW in INPUT_PULLUP, bus is likely shorted/stuck or over-driven.");
}

bool waitForPinLevel(int pin, int expectedLevel, uint32_t timeoutMs) {
  const uint32_t start = millis();
  while (millis() - start < timeoutMs) {
    if (digitalRead(pin) == expectedLevel) {
      return true;
    }
    delay(10);
  }
  return false;
}

void flushSerialInput() {
  while (Serial.available() > 0) {
    Serial.read();
  }
}

bool waitForEnterOrTimeout(uint32_t timeoutMs) {
  const uint32_t start = millis();
  while (millis() - start < timeoutMs) {
    if (Serial.available() > 0) {
      const int ch = Serial.read();
      if (ch == '\n' || ch == '\r') {
        flushSerialInput();
        return true;
      }
    }
    delay(10);
  }
  return false;
}

bool runManualPokeStep(const char* label, int targetPin, int otherPin) {
  printDivider(label);
  Serial.println("Do this now: touch a jumper from GND directly to the TARGET MCU pin.");
  Serial.println("Tip: test at the Feather header pin first (not at breadboard rail).");
  Serial.println("You have 20 seconds. Optional: press Enter in monitor when done.");

  const uint32_t stepStart = millis();
  bool sawLow = false;
  while (millis() - stepStart < 20000) {
    const int target = digitalRead(targetPin);
    const int other = digitalRead(otherPin);
    if (target == LOW) {
      sawLow = true;
    }
    if ((millis() - stepStart) % 2000 < 20) {
      Serial.printf("  live state -> target=%d other=%d\n", target, other);
    }
    if (Serial.available() > 0) {
      const int ch = Serial.read();
      if (ch == '\n' || ch == '\r') {
        flushSerialInput();
        break;
      }
    }
    delay(20);
  }

  if (!sawLow) {
    Serial.println("RESULT: FAIL (target pin never went LOW)");
    return false;
  }

  const bool recovered = waitForPinLevel(targetPin, HIGH, 8000);
  Serial.printf("RESULT: %s (target observed LOW, recovery=%s)\n",
                recovered ? "PASS" : "WARN",
                recovered ? "PASS" : "FAIL");
  return recovered;
}

void interactivePinPokeTest(int sdaPin, int sclPin) {
  printDivider("INTERACTIVE PIN POKE TEST");
  Serial.println("This verifies your physical wiring reaches the exact MCU pins.");
  Serial.println("Follow prompts in order. Quick test first, then manual deep test.");

  if (!digitalPinIsValid(sdaPin) || !digitalPinIsValid(sclPin)) {
    Serial.println("Cannot run poke test: invalid SDA/SCL pin(s).");
    return;
  }

  pinMode(sdaPin, INPUT_PULLUP);
  pinMode(sclPin, INPUT_PULLUP);
  delay(5);

  Serial.printf("Idle check before test: SDA=%d SCL=%d (expect both 1)\n", digitalRead(sdaPin), digitalRead(sclPin));

  Serial.println("\nStep 1: Briefly short SDA pin to GND now...");
  const bool sdaLowSeen = waitForPinLevel(sdaPin, LOW, 8000);
  const bool sclStayedHigh1 = digitalRead(sclPin) == HIGH;
  if (sdaLowSeen && sclStayedHigh1) {
    Serial.println("PASS: SDA transitioned LOW while SCL stayed HIGH.");
  } else {
    Serial.println("FAIL: Did not observe expected SDA behavior.");
    Serial.println("  -> If you shorted but no change: wrong wire/path or bad contact to SDA.");
  }

  Serial.println("Release SDA (both lines should return HIGH)...");
  const bool sdaRecovered = waitForPinLevel(sdaPin, HIGH, 8000);
  Serial.printf("SDA recovery: %s\n", sdaRecovered ? "PASS" : "FAIL");

  Serial.println("\nStep 2: Briefly short SCL pin to GND now...");
  const bool sclLowSeen = waitForPinLevel(sclPin, LOW, 8000);
  const bool sdaStayedHigh2 = digitalRead(sdaPin) == HIGH;
  if (sclLowSeen && sdaStayedHigh2) {
    Serial.println("PASS: SCL transitioned LOW while SDA stayed HIGH.");
  } else {
    Serial.println("FAIL: Did not observe expected SCL behavior.");
    Serial.println("  -> If you shorted but no change: wrong wire/path or bad contact to SCL.");
  }

  Serial.println("Release SCL (both lines should return HIGH)...");
  const bool sclRecovered = waitForPinLevel(sclPin, HIGH, 8000);
  Serial.printf("SCL recovery: %s\n", sclRecovered ? "PASS" : "FAIL");

  Serial.printf("\nFinal line state: SDA=%d SCL=%d\n", digitalRead(sdaPin), digitalRead(sclPin));
  Serial.println("If any FAIL appears, focus on wiring path before sensor/library changes.");

  printDivider("MANUAL DEEP POKE MODE");
  Serial.println("We will now run long-window direct pin checks.");
  Serial.println("Press Enter within 5 seconds to start now, or wait to auto-start.");
  waitForEnterOrTimeout(5000);

  pinMode(sdaPin, INPUT_PULLUP);
  pinMode(sclPin, INPUT_PULLUP);
  const bool sdaManual = runManualPokeStep("MANUAL STEP A (TARGET: SDA/GPIO3)", sdaPin, sclPin);
  const bool sclManual = runManualPokeStep("MANUAL STEP B (TARGET: SCL/GPIO4)", sclPin, sdaPin);

  printDivider("MANUAL POKE SUMMARY");
  Serial.printf("SDA manual step: %s\n", sdaManual ? "PASS" : "FAIL");
  Serial.printf("SCL manual step: %s\n", sclManual ? "PASS" : "FAIL");
  if (!sdaManual || !sclManual) {
    Serial.println("At least one direct pin test failed. This confirms a physical wiring/contact/path issue.");
  } else {
    Serial.println("Both direct pin tests passed. If MPU still missing, suspect module/device issue.");
  }
}

void tryBusRecovery(int sdaPin, int sclPin) {
  printDivider("I2C BUS RECOVERY");
  if (!digitalPinIsValid(sdaPin) || !digitalPinIsValid(sclPin)) {
    Serial.println("Skipping bus recovery: invalid pin(s).");
    return;
  }

  pinMode(sdaPin, INPUT_PULLUP);
  pinMode(sclPin, INPUT_PULLUP);
  delay(2);

  if (digitalRead(sdaPin) == HIGH && digitalRead(sclPin) == HIGH) {
    Serial.println("Bus lines already idle/high. No recovery pulses needed.");
    return;
  }

  Serial.println("Bus appears stuck; pulsing SCL 16 times to release a held SDA...");
  pinMode(sclPin, OUTPUT_OPEN_DRAIN);
  pinMode(sdaPin, INPUT_PULLUP);
  for (int i = 0; i < 16; i++) {
    digitalWrite(sclPin, HIGH);
    delayMicroseconds(20);
    digitalWrite(sclPin, LOW);
    delayMicroseconds(20);
  }
  digitalWrite(sclPin, HIGH);
  pinMode(sclPin, INPUT_PULLUP);
  delay(2);
  Serial.printf("Post-recovery lines: SDA=%d SCL=%d\n", digitalRead(sdaPin), digitalRead(sclPin));
}

void powerCycleI2CBusIfAvailable() {
#if defined(PIN_I2C_POWER)
  printDivider("I2C POWER CYCLE");
  Serial.println("Power cycling I2C rail...");
  pinMode(PIN_I2C_POWER, OUTPUT);
  digitalWrite(PIN_I2C_POWER, LOW);
  delay(500);
  digitalWrite(PIN_I2C_POWER, HIGH);
  delay(120);
  Serial.printf("I2C power pin state after restore: %d\n", digitalRead(PIN_I2C_POWER));
#else
  Serial.println("No I2C power control pin; skipping power cycle.");
#endif
}

void beginI2C(uint32_t clockHz) {
  printDivider("I2C INIT");
  Serial.printf("Initializing Wire on SDA=%d SCL=%d @ %lu Hz...\n", I2C_SDA_PIN, I2C_SCL_PIN, clockHz);
  wireReady = Wire.begin(I2C_SDA_PIN, I2C_SCL_PIN);
  Serial.printf("Wire.begin result: %s\n", wireReady ? "success" : "failure");
  if (wireReady) {
    Wire.setClock(clockHz);
  }
}

void quickKnownAddressProbe(const char* title) {
  Serial.printf("%s: ", title);
  bool any = false;
  for (uint8_t addr : KNOWN_IMU_ADDRS) {
    Wire.beginTransmission(addr);
    const uint8_t error = Wire.endTransmission(true);
    if (error == 0) {
      Serial.printf("0x%02X ", addr);
      any = true;
    }
  }
  if (!any) {
    Serial.print("none");
  }
  Serial.println();
}

bool i2cPing(uint8_t addr, bool verbose = true) {
  if (!wireReady) {
    if (verbose) Serial.println("i2cPing skipped: Wire not initialized");
    return false;
  }

  Wire.beginTransmission(addr);
  const uint8_t error = Wire.endTransmission(true);
  if (verbose) {
    Serial.printf("Ping 0x%02X -> %s (%u)\n", addr, i2cErrorToText(error), error);
  }
  return error == 0;
}

void scanI2CBus() {
  printDivider("I2C SCAN");
  if (!wireReady) {
    Serial.println("Cannot scan: Wire bus is not initialized.");
    return;
  }

  int found = 0;
  for (uint8_t addr = 1; addr < 127; addr++) {
    Wire.beginTransmission(addr);
    const uint8_t error = Wire.endTransmission(true);
    if (error == 0) {
      Serial.printf("  -> Found device at 0x%02X\n", addr);
      found++;
    }
  }
  if (found == 0) {
    Serial.println("  -> No I2C devices found.");
  } else {
    Serial.printf("Total devices found: %d\n", found);
  }
}

bool readRegister8(uint8_t addr, uint8_t reg, uint8_t& outValue) {
  if (!wireReady) return false;

  Wire.beginTransmission(addr);
  Wire.write(reg);
  uint8_t txError = Wire.endTransmission(false);  // repeated start
  if (txError != 0) {
    Serial.printf("Reg read prep failed: addr=0x%02X reg=0x%02X err=%s (%u)\n",
                  addr, reg, i2cErrorToText(txError), txError);
    return false;
  }

  const uint8_t requested = 1;
  const uint8_t received = Wire.requestFrom(static_cast<int>(addr), static_cast<int>(requested), static_cast<int>(true));
  if (received != requested) {
    Serial.printf("Reg read failed: addr=0x%02X reg=0x%02X requested=%u received=%u\n",
                  addr, reg, requested, received);
    return false;
  }

  outValue = Wire.read();
  return true;
}

void profileI2CDevice(uint8_t addr) {
  Serial.printf("Profiling 0x%02X\n", addr);

  uint8_t value = 0;
  if (readRegister8(addr, 0x75, value)) {
    Serial.printf("  reg 0x75 (MPU WHO_AM_I style): 0x%02X\n", value);
  }
  if (readRegister8(addr, 0x0F, value)) {
    Serial.printf("  reg 0x0F (common WHO_AM_I): 0x%02X\n", value);
  }
  if (readRegister8(addr, 0x00, value)) {
    Serial.printf("  reg 0x00: 0x%02X\n", value);
  }
  if (readRegister8(addr, 0x01, value)) {
    Serial.printf("  reg 0x01: 0x%02X\n", value);
  }
  if (readRegister8(addr, 0x02, value)) {
    Serial.printf("  reg 0x02: 0x%02X\n", value);
  }
  if (readRegister8(addr, 0x03, value)) {
    Serial.printf("  reg 0x03: 0x%02X\n", value);
  }

  if (addr == 0x36) {
    Serial.println("  note: 0x36 matches MAX17048 battery gauge on Feather ESP32-S3.");
  }
  if (addr == 0x1E) {
    Serial.println("  note: 0x1E is often magnetometer family (HMC5883/QMC5883/LIS3MDL variants).");
  }
}

void profileDiscoveredDevices() {
  printDivider("I2C DEVICE PROFILER");
  bool any = false;

  for (uint8_t addr = 1; addr < 127; addr++) {
    Wire.beginTransmission(addr);
    const uint8_t error = Wire.endTransmission(true);
    if (error == 0) {
      any = true;
      profileI2CDevice(addr);
    }
  }

  if (!any) {
    Serial.println("No devices to profile.");
  }
}

bool readRegisters(uint8_t addr, uint8_t startReg, uint8_t* buffer, uint8_t len) {
  if (!wireReady) return false;
  Wire.beginTransmission(addr);
  Wire.write(startReg);
  const uint8_t txError = Wire.endTransmission(false);
  if (txError != 0) return false;

  const uint8_t received = Wire.requestFrom(static_cast<int>(addr), static_cast<int>(len), static_cast<int>(true));
  if (received != len) return false;
  for (uint8_t i = 0; i < len; i++) {
    buffer[i] = Wire.read();
  }
  return true;
}

bool initializeMpuRegisters(uint8_t addr) {
  // Common MPU60x0/65x0 register map.
  // Wake device from sleep.
  Wire.beginTransmission(addr);
  Wire.write(0x6B);  // PWR_MGMT_1
  Wire.write(0x00);
  if (Wire.endTransmission(true) != 0) return false;
  delay(10);

  // Set accel +/-2g.
  Wire.beginTransmission(addr);
  Wire.write(0x1C);  // ACCEL_CONFIG
  Wire.write(0x00);
  if (Wire.endTransmission(true) != 0) return false;

  // Set gyro +/-250 dps.
  Wire.beginTransmission(addr);
  Wire.write(0x1B);  // GYRO_CONFIG
  Wire.write(0x00);
  if (Wire.endTransmission(true) != 0) return false;

  return true;
}

bool tryBringupMpu() {
  uint8_t whoAmI = 0;
  uint8_t candidateAddr = 0;

  if (readRegister8(MPU_ADDR_LOW, MPU_REG_WHO_AM_I, whoAmI)) {
    candidateAddr = MPU_ADDR_LOW;
  } else if (readRegister8(MPU_ADDR_HIGH, MPU_REG_WHO_AM_I, whoAmI)) {
    candidateAddr = MPU_ADDR_HIGH;
  } else {
    return false;
  }

  if (!initializeMpuRegisters(candidateAddr)) {
    Serial.println("MPU register init failed even though WHO_AM_I was readable.");
    return false;
  }

  activeMpuAddress = candidateAddr;
  activeWhoAmI = whoAmI;
  mpuReady = true;
  Serial.printf("MPU online at 0x%02X with WHO_AM_I=0x%02X\n", activeMpuAddress, activeWhoAmI);
  if (activeWhoAmI == 0x68) {
    Serial.println("Detected MPU6050-class device.");
  } else if (activeWhoAmI == 0x70) {
    Serial.println("Detected MPU6500/9250-class device (compatible raw read path enabled).");
  } else {
    Serial.println("Detected unknown MPU-family response; continuing with generic raw read path.");
  }
  return true;
}

void probeMpuAddress(uint8_t addr) {
  printDivider(addr == MPU_ADDR_LOW ? "PROBE MPU @ 0x68" : "PROBE MPU @ 0x69");
  const bool present = i2cPing(addr);
  if (!present) {
    Serial.println("Device did not ACK this address.");
    return;
  }

  uint8_t whoAmI = 0;
  if (readRegister8(addr, MPU_REG_WHO_AM_I, whoAmI)) {
    Serial.printf("WHO_AM_I (0x75) = 0x%02X\n", whoAmI);
    Serial.println("Expected for MPU6050 is typically 0x68.");
  } else {
    Serial.println("Could not read WHO_AM_I register.");
  }
}

void alternatePinPairSweep() {
  printDivider("ALTERNATE PIN-PAIR SWEEP");
  struct PinPair {
    int sda;
    int scl;
  };

  // Includes default board pins first, then a few common accidental mappings.
  const PinPair pairs[] = {
    {I2C_SDA_PIN, I2C_SCL_PIN},
    {3, 4},
    {8, 9},
    {21, 22},
    {1, 2},
    {11, 12},
  };

  for (const auto& pair : pairs) {
    if (!digitalPinIsValid(pair.sda) || !digitalPinIsValid(pair.scl)) {
      Serial.printf("Skip SDA=%d SCL=%d (invalid pin)\n", pair.sda, pair.scl);
      continue;
    }

    Wire.end();
    const bool ok = Wire.begin(pair.sda, pair.scl);
    Serial.printf("Test pair SDA=%d SCL=%d -> Wire.begin=%s\n", pair.sda, pair.scl, ok ? "ok" : "fail");
    if (!ok) continue;

    Wire.setClock(100000);
    quickKnownAddressProbe("  IMU address probe");
  }

  // Restore configured pair for normal flow.
  Wire.end();
  wireReady = Wire.begin(I2C_SDA_PIN, I2C_SCL_PIN);
  if (wireReady) {
    Wire.setClock(100000);
  }
}

bool tryInitMpuWithRetries() {
  printDivider("MPU INIT");

  // Multi-pass retry helps when power rails or pull-ups settle slowly.
  for (int attempt = 1; attempt <= 4; attempt++) {
    Serial.printf("MPU init attempt %d/4\n", attempt);
    scanI2CBus();
    probeMpuAddress(MPU_ADDR_LOW);
    probeMpuAddress(MPU_ADDR_HIGH);

    if (tryBringupMpu()) {
      return true;
    }

    Serial.println("MPU init failed this attempt. Retrying after 500ms...");
    delay(500);
  }

  return false;
}

void initBle() {
  printDivider("BLE INIT");
  BLEDevice::init("HelpingHand-Glove");
  Serial.println("BLE MAC: " + String(BLEDevice::getAddress().toString().c_str()));
  Serial.println("BLE initialized.");
}

void setup() {
  Serial.begin(115200);
  while (!Serial) delay(10);
  delay(1500);

  Serial.println("\n=== HelpingHand Comprehensive Boot Diagnostics ===");

  printSystemInfo();
  printI2CPinInfo();
  powerCycleI2CBusIfAvailable();
  electricalLineDiagnostics(I2C_SDA_PIN, I2C_SCL_PIN);
  interactivePinPokeTest(I2C_SDA_PIN, I2C_SCL_PIN);
  tryBusRecovery(I2C_SDA_PIN, I2C_SCL_PIN);

  beginI2C(100000);
  if (!wireReady) {
    Serial.println("FATAL: I2C failed to initialize. Check selected board + pin mapping.");
    return;
  }
  quickKnownAddressProbe("Known IMU probe on configured pins");
  alternatePinPairSweep();
  profileDiscoveredDevices();

  mpuReady = tryInitMpuWithRetries();
  if (mpuReady) {
    Serial.printf("MPU ready. Address=0x%02X WHO_AM_I=0x%02X\n", activeMpuAddress, activeWhoAmI);
  } else {
    Serial.println("FAILED: MPU6050 not found after comprehensive retries.");
    Serial.println("Checklist:");
    Serial.println("  1) SDA to GPIO 3, SCL to GPIO 4 on Feather ESP32-S3");
    Serial.println("  2) Shared GND between Feather and MPU");
    Serial.println("  3) AD0 tied LOW for 0x68 or HIGH for 0x69 (avoid floating)");
    Serial.println("  4) Verify module is truly MPU6050 and powered at 3.3V logic");
  }

  initBle();
  Serial.println("\nBoot diagnostics complete.");
}

void loop() {
  if (mpuReady) {
    uint8_t raw[14] = {0};
    if (!readRegisters(activeMpuAddress, 0x3B, raw, sizeof(raw))) {
      Serial.println("MPU read failed; marking sensor not ready and returning to diag mode.");
      mpuReady = false;
      delay(250);
      return;
    }

    const int16_t axRaw = static_cast<int16_t>((raw[0] << 8) | raw[1]);
    const int16_t ayRaw = static_cast<int16_t>((raw[2] << 8) | raw[3]);
    const int16_t azRaw = static_cast<int16_t>((raw[4] << 8) | raw[5]);
    const int16_t gxRaw = static_cast<int16_t>((raw[8] << 8) | raw[9]);
    const int16_t gyRaw = static_cast<int16_t>((raw[10] << 8) | raw[11]);
    const int16_t gzRaw = static_cast<int16_t>((raw[12] << 8) | raw[13]);

    const float ax = static_cast<float>(axRaw) / 16384.0f;
    const float ay = static_cast<float>(ayRaw) / 16384.0f;
    const float az = static_cast<float>(azRaw) / 16384.0f;
    const float gx = static_cast<float>(gxRaw) / 131.0f;
    const float gy = static_cast<float>(gyRaw) / 131.0f;
    const float gz = static_cast<float>(gzRaw) / 131.0f;

    Serial.printf("MPU@0x%02X WHO=0x%02X | Accel[g] X=%.3f Y=%.3f Z=%.3f | Gyro[dps] X=%.3f Y=%.3f Z=%.3f\n",
                  activeMpuAddress, activeWhoAmI, ax, ay, az, gx, gy, gz);
    delay(500);
    return;
  }

  // Keep reporting every few seconds instead of halting so live wiring changes are visible.
  if (millis() - lastDiagMs >= 3000) {
    lastDiagMs = millis();
    Serial.println("\n[DIAG LOOP] MPU not ready; re-probing bus...");
    scanI2CBus();
    profileDiscoveredDevices();
    probeMpuAddress(MPU_ADDR_LOW);
    probeMpuAddress(MPU_ADDR_HIGH);
    if (tryBringupMpu()) {
      Serial.println("Hot-plug recovery success: sensor is now ready.");
    }
  }

  delay(50);
}
