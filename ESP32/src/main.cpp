#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <Wire.h>

constexpr int I2C_SDA_PIN = SDA;
constexpr int I2C_SCL_PIN = SCL;
constexpr uint8_t MPU_ADDR_LOW = 0x68;
constexpr uint8_t MPU_ADDR_HIGH = 0x69;
constexpr uint8_t MPU_REG_WHO_AM_I = 0x75;

// Nordic UART Service (matches the Flutter BLE testing tab UUIDs).
static const char* BLE_DEVICE_NAME = "HelpingHand-Glove";
static const char* BLE_SERVICE_UUID = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
static const char* BLE_RX_UUID = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E";  // app -> ESP32
static const char* BLE_TX_UUID = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E";  // ESP32 -> app

BLECharacteristic* txCharacteristic = nullptr;
bool bleClientConnected = false;

bool imuReady = false;
uint8_t imuAddress = 0x00;
uint8_t imuWhoAmI = 0x00;
uint32_t lastImuPacketMs = 0;
uint32_t lastImuRetryMs = 0;

struct ImuSample {
  float axG;
  float ayG;
  float azG;
  float gxDps;
  float gyDps;
  float gzDps;
};

class ServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* server) override {
    bleClientConnected = true;
    Serial.println("BLE client connected");
  }

  void onDisconnect(BLEServer* server) override {
    bleClientConnected = false;
    Serial.println("BLE client disconnected; restarting advertising");
    server->getAdvertising()->start();
  }
};

class RxCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* characteristic) override {
    const std::string value = characteristic->getValue();
    if (!value.empty()) {
      Serial.print("BLE RX: ");
      Serial.println(value.c_str());
    }
  }
};

bool readRegister8(uint8_t addr, uint8_t reg, uint8_t& outValue) {
  Wire.beginTransmission(addr);
  Wire.write(reg);
  if (Wire.endTransmission(false) != 0) return false;

  const uint8_t received = Wire.requestFrom(static_cast<int>(addr), 1, static_cast<int>(true));
  if (received != 1) return false;
  outValue = Wire.read();
  return true;
}

bool readRegisters(uint8_t addr, uint8_t startReg, uint8_t* buffer, uint8_t len) {
  Wire.beginTransmission(addr);
  Wire.write(startReg);
  if (Wire.endTransmission(false) != 0) return false;

  const uint8_t received = Wire.requestFrom(static_cast<int>(addr), static_cast<int>(len), static_cast<int>(true));
  if (received != len) return false;
  for (uint8_t i = 0; i < len; i++) {
    buffer[i] = Wire.read();
  }
  return true;
}

bool writeRegister8(uint8_t addr, uint8_t reg, uint8_t value) {
  Wire.beginTransmission(addr);
  Wire.write(reg);
  Wire.write(value);
  return Wire.endTransmission(true) == 0;
}

bool initImuAtAddress(uint8_t addr) {
  uint8_t whoAmI = 0;
  if (!readRegister8(addr, MPU_REG_WHO_AM_I, whoAmI)) return false;

  // Common init sequence for MPU6050/6500 class parts.
  if (!writeRegister8(addr, 0x6B, 0x00)) return false;  // PWR_MGMT_1: wake
  delay(10);
  if (!writeRegister8(addr, 0x1C, 0x00)) return false;  // ACCEL_CONFIG: +/-2g
  if (!writeRegister8(addr, 0x1B, 0x00)) return false;  // GYRO_CONFIG: +/-250 dps
  if (!writeRegister8(addr, 0x1A, 0x03)) return false;  // CONFIG DLPF

  imuAddress = addr;
  imuWhoAmI = whoAmI;
  imuReady = true;
  Serial.printf("IMU ready at 0x%02X (WHO_AM_I=0x%02X)\n", imuAddress, imuWhoAmI);
  return true;
}

bool discoverAndInitImu() {
  if (initImuAtAddress(MPU_ADDR_LOW)) return true;
  if (initImuAtAddress(MPU_ADDR_HIGH)) return true;
  imuReady = false;
  return false;
}

bool readImuSample(ImuSample& sample) {
  uint8_t raw[14] = {0};
  if (!readRegisters(imuAddress, 0x3B, raw, sizeof(raw))) return false;

  const int16_t axRaw = static_cast<int16_t>((raw[0] << 8) | raw[1]);
  const int16_t ayRaw = static_cast<int16_t>((raw[2] << 8) | raw[3]);
  const int16_t azRaw = static_cast<int16_t>((raw[4] << 8) | raw[5]);
  const int16_t gxRaw = static_cast<int16_t>((raw[8] << 8) | raw[9]);
  const int16_t gyRaw = static_cast<int16_t>((raw[10] << 8) | raw[11]);
  const int16_t gzRaw = static_cast<int16_t>((raw[12] << 8) | raw[13]);

  sample.axG = static_cast<float>(axRaw) / 16384.0f;
  sample.ayG = static_cast<float>(ayRaw) / 16384.0f;
  sample.azG = static_cast<float>(azRaw) / 16384.0f;
  sample.gxDps = static_cast<float>(gxRaw) / 131.0f;
  sample.gyDps = static_cast<float>(gyRaw) / 131.0f;
  sample.gzDps = static_cast<float>(gzRaw) / 131.0f;
  return true;
}

void setupBle() {
  BLEDevice::init(BLE_DEVICE_NAME);
  BLEServer* server = BLEDevice::createServer();
  server->setCallbacks(new ServerCallbacks());

  BLEService* service = server->createService(BLE_SERVICE_UUID);
  txCharacteristic = service->createCharacteristic(
    BLE_TX_UUID,
    BLECharacteristic::PROPERTY_NOTIFY
  );
  txCharacteristic->addDescriptor(new BLE2902());

  BLECharacteristic* rxCharacteristic = service->createCharacteristic(
    BLE_RX_UUID,
    BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_WRITE_NR
  );
  rxCharacteristic->setCallbacks(new RxCallbacks());

  service->start();
  BLEAdvertising* advertising = server->getAdvertising();
  advertising->addServiceUUID(BLE_SERVICE_UUID);
  advertising->start();
}

void setup() {
  Serial.begin(115200);
  while (!Serial) delay(10);
  delay(500);

  Serial.println("\n=== HelpingHand IMU + BLE Runtime ===");
  Serial.printf("I2C pins SDA=%d SCL=%d\n", I2C_SDA_PIN, I2C_SCL_PIN);

#if defined(PIN_I2C_POWER)
  pinMode(PIN_I2C_POWER, OUTPUT);
  digitalWrite(PIN_I2C_POWER, HIGH);
  delay(120);
#endif

  const bool wireOk = Wire.begin(I2C_SDA_PIN, I2C_SCL_PIN);
  Wire.setClock(100000);
  Serial.printf("Wire.begin: %s\n", wireOk ? "ok" : "fail");

  if (!discoverAndInitImu()) {
    Serial.println("IMU not found at boot (0x68/0x69). Will retry in loop.");
  }

  setupBle();
  Serial.println("BLE ready and advertising");
}

void loop() {
  if (!imuReady) {
    if (millis() - lastImuRetryMs >= 2000) {
      lastImuRetryMs = millis();
      if (discoverAndInitImu()) {
        Serial.println("IMU hot-plug detected and initialized.");
      } else {
        Serial.println("IMU still not found; retrying...");
      }
    }
    delay(20);
    return;
  }

  if (millis() - lastImuPacketMs < 100) {  // 10 Hz
    delay(5);
    return;
  }
  lastImuPacketMs = millis();

  ImuSample sample{};
  if (!readImuSample(sample)) {
    Serial.println("IMU read failed; marking IMU offline.");
    imuReady = false;
    return;
  }

  char payload[160];
  snprintf(
    payload,
    sizeof(payload),
    "who=0x%02X,ax=%.3f,ay=%.3f,az=%.3f,gx=%.3f,gy=%.3f,gz=%.3f",
    imuWhoAmI,
    sample.axG,
    sample.ayG,
    sample.azG,
    sample.gxDps,
    sample.gyDps,
    sample.gzDps
  );

  Serial.println(payload);
  if (bleClientConnected && txCharacteristic != nullptr) {
    txCharacteristic->setValue(reinterpret_cast<const uint8_t*>(payload), strlen(payload));
    txCharacteristic->notify();
  }
}
