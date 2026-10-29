#include "imu_sensor.h"
#include <Wire.h>
using namespace std;

namespace {
constexpr uint8_t MPU_ADDR_LOW = 0x68;
constexpr uint8_t MPU_ADDR_HIGH = 0x69;
constexpr uint8_t MPU_REG_WHO_AM_I = 0x75;

constexpr uint8_t AK8963_ADDR = 0x0C;
constexpr uint8_t AK8963_REG_WIA = 0x00;
constexpr uint8_t AK8963_EXPECTED_WIA = 0x48;

bool imuReady = false;
uint8_t imuAddress = 0;
uint8_t imuWhoAmI = 0;
uint32_t lastImuRetryMs = 0;
bool magnetometerProbeCompleted = false;
bool usingIcm20948 = false;
bool ak09916Ready = false;

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

void maybeProbeAk8963Magnetometer() {
#if HH_ENABLE_AK8963_PROBE
  if (!imuReady || usingIcm20948 || magnetometerProbeCompleted) return;
  magnetometerProbeCompleted = true;

  if (!writeRegister8(imuAddress, 0x37, 0x02)) {
    Serial.println("MAG PROBE: unable to enable auxiliary-I2C bypass.");
    return;
  }
  delay(10);

  uint8_t wia = 0;
  const bool readable = readRegister8(AK8963_ADDR, AK8963_REG_WIA, wia);
  if (readable && wia == AK8963_EXPECTED_WIA) {
    Serial.println(
      "MAG PROBE: AK8963 WIA=0x48 responded; physical part and usable data still require verification."
    );
  } else if (readable) {
    Serial.printf("MAG PROBE: device at 0x0C returned unexpected WIA=0x%02X.\n", wia);
  } else {
    Serial.println("MAG PROBE: no readable AK8963 WIA at 0x0C.");
  }
  writeRegister8(imuAddress, 0x37, 0x00);
#endif
}

bool initAk09916(uint8_t addr) {
  // Bank 0: disable internal I2C master and expose the compass via bypass.
  if (!writeRegister8(addr, 0x03, 0x00) ||
      !writeRegister8(addr, 0x0F, 0x02)) return false;
  uint8_t id[2] = {};
  if (!readRegisters(0x0C, 0x00, id, 2) || id[0] != 0x48 || id[1] != 0x09) return false;
  if (!writeRegister8(0x0C, 0x31, 0x00)) return false;  // Power down before mode change.
  delay(1);
  return writeRegister8(0x0C, 0x31, 0x08);  // Continuous 100 Hz, no fusion.
}

bool initIcm20948(uint8_t addr) {
  // ICM register map differs from MPU: bank 0 WHO_AM_I is 0x00, value 0xEA.
  uint8_t id = 0;
  if (!writeRegister8(addr, 0x7F, 0x00) ||
      !readRegister8(addr, 0x00, id) || id != 0xEA) return false;
  if (!writeRegister8(addr, 0x06, 0x80)) return false;  // Device reset.
  delay(100);
  if (!writeRegister8(addr, 0x7F, 0x00) ||
      !writeRegister8(addr, 0x06, 0x01) ||  // Wake, automatic clock selection.
      !writeRegister8(addr, 0x07, 0x00)) return false;  // Enable accel/gyro axes.
  delay(30);
  // Bank 2, +/-250 dps and +/-2 g. DLPF config 3, enabled (0x19).
  if (!writeRegister8(addr, 0x7F, 0x20) ||
      !writeRegister8(addr, 0x01, 0x19) ||
      !writeRegister8(addr, 0x14, 0x19) ||
      !writeRegister8(addr, 0x00, 0x00) ||  // Gyro sample divider.
      !writeRegister8(addr, 0x10, 0x00) ||
      !writeRegister8(addr, 0x11, 0x00) ||  // Accel sample divider.
      !writeRegister8(addr, 0x7F, 0x00)) return false;
  delay(30);
  ak09916Ready = initAk09916(addr);
  imuAddress = addr;
  imuWhoAmI = id;
  usingIcm20948 = true;
  imuReady = true;
  Serial.printf("ICM-20948 ready at 0x%02X; AK09916=%s (uncalibrated).\n",
                addr, ak09916Ready ? "ready" : "unavailable");
  return true;
}

bool initImuAtAddress(uint8_t addr) {
  uint8_t whoAmI = 0;
  const bool legacy = readRegister8(addr, MPU_REG_WHO_AM_I, whoAmI) &&
    (whoAmI == 0x68 || whoAmI == 0x70 || whoAmI == 0x71 || whoAmI == 0x73);
  if (!legacy) return initIcm20948(addr);

  // INIT SEQUENCE FOR MPU6050/6500 CLASS PARTS.
  if (!writeRegister8(addr, 0x6B, 0x00)) return false;  // PWR_MGMT_1: wake
  delay(10);
  if (!writeRegister8(addr, 0x1C, 0x00)) return false;  // ACCEL_CONFIG: +/-2g
  if (!writeRegister8(addr, 0x1B, 0x00)) return false;  // GYRO_CONFIG: +/-250 dps
  if (!writeRegister8(addr, 0x1A, 0x03)) return false;  // CONFIG DLPF

  imuAddress = addr;
  imuWhoAmI = whoAmI;
  usingIcm20948 = false;
  ak09916Ready = false;
  magnetometerProbeCompleted = false;
  imuReady = true;
  Serial.printf("IMU ready at 0x%02X (WHO_AM_I=0x%02X)\n", imuAddress, imuWhoAmI);
  return true;
}

bool discoverAndInitImu() {
  ak09916Ready = false;
  if (initImuAtAddress(MPU_ADDR_LOW)) return true;
  if (initImuAtAddress(MPU_ADDR_HIGH)) return true;
  imuReady = false;
  return false;
}

} 

void setupImu() {
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
  maybeProbeAk8963Magnetometer();

}

void updateImu() {
  if (!imuReady) {
    if (millis() - lastImuRetryMs >= 2000) {
      lastImuRetryMs = millis();
      if (discoverAndInitImu()) {
        Serial.println("IMU hot-plug detected and initialized.");
        maybeProbeAk8963Magnetometer();
      } else {
        Serial.println("IMU still not found; retrying...");
      }
    }
    // CONT LOOP
  }

}

bool readImuSample(ImuSample& sample) {
  if (!imuReady) return false;
  uint8_t raw[14] = {0};
  if ((usingIcm20948 && !writeRegister8(imuAddress, 0x7F, 0x00)) ||
      !readRegisters(imuAddress, usingIcm20948 ? 0x2D : 0x3B,
                     raw, usingIcm20948 ? 12 : sizeof(raw))) {
    Serial.println("IMU read failed; marking IMU offline.");
    imuReady = false;
    ak09916Ready = false;
    return false;
  }

  const int16_t axRaw = static_cast<int16_t>((raw[0] << 8) | raw[1]);
  const int16_t ayRaw = static_cast<int16_t>((raw[2] << 8) | raw[3]);
  const int16_t azRaw = static_cast<int16_t>((raw[4] << 8) | raw[5]);
  const uint8_t gyroOffset = usingIcm20948 ? 6 : 8;
  const int16_t gxRaw = static_cast<int16_t>((raw[gyroOffset] << 8) | raw[gyroOffset + 1]);
  const int16_t gyRaw = static_cast<int16_t>((raw[gyroOffset + 2] << 8) | raw[gyroOffset + 3]);
  const int16_t gzRaw = static_cast<int16_t>((raw[gyroOffset + 4] << 8) | raw[gyroOffset + 5]);

  sample.axG = static_cast<float>(axRaw) / 16384.0f;
  sample.ayG = static_cast<float>(ayRaw) / 16384.0f;
  sample.azG = static_cast<float>(azRaw) / 16384.0f;
  sample.gxDps = static_cast<float>(gxRaw) / 131.0f;
  sample.gyDps = static_cast<float>(gyRaw) / 131.0f;
  sample.gzDps = static_cast<float>(gzRaw) / 131.0f;
  return true;
}

bool readMagneticSample(MagneticSample& sample) {
  if (!imuReady || !usingIcm20948 || !ak09916Ready) return false;
  uint8_t status = 0;
  if (!readRegister8(0x0C, 0x10, status) || !(status & 0x01)) return false;
  uint8_t raw[8] = {};
  // Read through ST2 to release the sample latch; reject overflow.
  if (!readRegisters(0x0C, 0x11, raw, sizeof(raw)) || (raw[7] & 0x08)) return false;
  sample.mxUt = static_cast<int16_t>((raw[1] << 8) | raw[0]) * 0.15f;
  sample.myUt = static_cast<int16_t>((raw[3] << 8) | raw[2]) * 0.15f;
  sample.mzUt = static_cast<int16_t>((raw[5] << 8) | raw[4]) * 0.15f;
  return true;
}

uint8_t getImuWhoAmI() { return imuWhoAmI; }
