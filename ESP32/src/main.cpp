#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <Wire.h>
#include <math.h>

#include "asl_model_data.h"
#include "tensorflow/lite/c/common.h"
#include "tensorflow/lite/micro/all_ops_resolver.h"
#include "tensorflow/lite/micro/micro_error_reporter.h"
#include "tensorflow/lite/micro/micro_interpreter.h"
#include "tensorflow/lite/schema/schema_generated.h"

constexpr int I2C_SDA_PIN = SDA;
constexpr int I2C_SCL_PIN = SCL;
constexpr size_t FLEX_SENSOR_COUNT = 5;
constexpr int FLEX_SENSOR_PINS[FLEX_SENSOR_COUNT] = {A0, A1, A2, A3, A4};
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

constexpr int kModelInputSize = 5;
constexpr int kModelClassCount = 36;
constexpr size_t kTensorArenaSize = 70 * 1024;
alignas(16) uint8_t tensorArena[kTensorArenaSize];
constexpr bool kUseHardcodedMlTest = true;

const tflite::Model* mlModel = nullptr;
tflite::AllOpsResolver mlResolver;
tflite::MicroErrorReporter mlMicroErrorReporter;
tflite::ErrorReporter* mlErrorReporter = &mlMicroErrorReporter;
tflite::MicroInterpreter* mlInterpreter = nullptr;
TfLiteTensor* mlInputTensor = nullptr;
TfLiteTensor* mlOutputTensor = nullptr;
bool mlReady = false;

const float kFeatureMean[kModelInputSize] = {
  294.58229166666666f,
  416.1657986111111f,
  345.5805555555556f,
  260.7661458333333f,
  260.40746527777776f
};

const float kFeatureScale[kModelInputSize] = {
  111.92435518526472f,
  164.16211005855075f,
  178.97278299358564f,
  154.56913119757505f,
  185.51501168995773f
};

const char* kClassLabels[kModelClassCount] = {
  "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
  "A", "B", "C", "D", "E", "F", "G", "H", "I", "J",
  "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T",
  "U", "V", "W", "X", "Y", "Z"
};

struct MlTestCase {
  const char* expected;
  int flex[kModelInputSize];
};

const MlTestCase kMlTestCases[] = {
  {"N", {145, 135, 130, 125, 95}},      // fist-like sample from demo calibration range
  {"5", {550, 550, 550, 550, 560}},     // all fingers extended
  {"1/Z", {145, 550, 130, 125, 95}},    // index up family (ambiguous with Z in flex-only)
};

struct ImuSample {
  float axG;
  float ayG;
  float azG;
  float gxDps;
  float gyDps;
  float gzDps;
};

struct FlexReadings {
  int raw[FLEX_SENSOR_COUNT];
  float norm[FLEX_SENSOR_COUNT];
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

float readFlexNormalized(int raw) {
  // ESP32 ADC default is 12-bit => 0..4095
  return static_cast<float>(raw) / 4095.0f;
}

void setupFlexSensors() {
  analogReadResolution(12);
  for (size_t i = 0; i < FLEX_SENSOR_COUNT; i++) {
    pinMode(FLEX_SENSOR_PINS[i], INPUT);
    analogSetPinAttenuation(FLEX_SENSOR_PINS[i], ADC_11db);
  }
}

FlexReadings readFlexReadings() {
  FlexReadings readings{};
  for (size_t i = 0; i < FLEX_SENSOR_COUNT; i++) {
    const int raw = analogRead(FLEX_SENSOR_PINS[i]);
    readings.raw[i] = raw;
    readings.norm[i] = readFlexNormalized(raw);
  }
  return readings;
}

bool setupClassifier() {
  mlModel = tflite::GetModel(g_asl_model_tflite);
  if (mlModel == nullptr) {
    Serial.println("GetModel failed.");
    return false;
  }

  static tflite::MicroInterpreter staticInterpreter(
    mlModel,
    mlResolver,
    tensorArena,
    kTensorArenaSize,
    mlErrorReporter,
    nullptr,
    nullptr
  );
  mlInterpreter = &staticInterpreter;

  const TfLiteStatus allocStatus = mlInterpreter->AllocateTensors();
  if (allocStatus != kTfLiteOk) {
    Serial.println("AllocateTensors failed.");
    return false;
  }

  mlInputTensor = mlInterpreter->input(0);
  mlOutputTensor = mlInterpreter->output(0);
  if (mlInputTensor == nullptr || mlOutputTensor == nullptr) {
    Serial.println("TFLite tensors unavailable.");
    return false;
  }

  const int inputFeatures = mlInputTensor->dims->data[mlInputTensor->dims->size - 1];
  const int outputClasses = mlOutputTensor->dims->data[mlOutputTensor->dims->size - 1];
  if (inputFeatures != kModelInputSize || outputClasses != kModelClassCount) {
    Serial.printf(
      "Unexpected tensor shape. in=%d out=%d expected in=%d out=%d\n",
      inputFeatures,
      outputClasses,
      kModelInputSize,
      kModelClassCount
    );
    return false;
  }

  mlReady = true;
  Serial.printf("TFLite ready. Input type=%d Output type=%d\n", mlInputTensor->type, mlOutputTensor->type);
  return true;
}

void writeInputFeature(int index, float value) {
  if (mlInputTensor->type == kTfLiteFloat32) {
    mlInputTensor->data.f[index] = value;
    return;
  }

  if (mlInputTensor->type == kTfLiteInt8) {
    const float scale = mlInputTensor->params.scale;
    const int zeroPoint = mlInputTensor->params.zero_point;
    const int q = static_cast<int>(roundf(value / scale)) + zeroPoint;
    mlInputTensor->data.int8[index] = static_cast<int8_t>(constrain(q, -128, 127));
  }
}

float readOutputProbability(int index) {
  if (mlOutputTensor->type == kTfLiteFloat32) {
    return mlOutputTensor->data.f[index];
  }

  if (mlOutputTensor->type == kTfLiteInt8) {
    const float scale = mlOutputTensor->params.scale;
    const int zeroPoint = mlOutputTensor->params.zero_point;
    return (static_cast<int>(mlOutputTensor->data.int8[index]) - zeroPoint) * scale;
  }

  return 0.0f;
}

bool classifyFlex(const FlexReadings& flex, const char*& outLabel, float& outConfidence) {
  if (!mlReady || mlInterpreter == nullptr) return false;

  for (int i = 0; i < kModelInputSize; i++) {
    const float normalized = (static_cast<float>(flex.raw[i]) - kFeatureMean[i]) / kFeatureScale[i];
    writeInputFeature(i, normalized);
  }

  if (mlInterpreter->Invoke() != kTfLiteOk) {
    return false;
  }

  int bestIndex = 0;
  float bestProb = readOutputProbability(0);
  for (int i = 1; i < kModelClassCount; i++) {
    const float p = readOutputProbability(i);
    if (p > bestProb) {
      bestProb = p;
      bestIndex = i;
    }
  }

  outLabel = kClassLabels[bestIndex];
  outConfidence = bestProb * 100.0f;
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
  Serial.printf(
    "Flex sensor pins: A0=%d A1=%d A2=%d A3=%d A4=%d\n",
    FLEX_SENSOR_PINS[0],
    FLEX_SENSOR_PINS[1],
    FLEX_SENSOR_PINS[2],
    FLEX_SENSOR_PINS[3],
    FLEX_SENSOR_PINS[4]
  );
  setupFlexSensors();

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

  if (!setupClassifier()) {
    Serial.println("Classifier setup failed. Continuing without ML predictions.");
  }
  if (kUseHardcodedMlTest) {
    Serial.println("ML TEST MODE ON: using hardcoded flex vectors (not live sensor input).");
  } else {
    Serial.println("ML TEST MODE OFF: using live flex sensor input.");
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
    // Continue loop so flex sensor can still be tested even if IMU is offline.
  }

  if (millis() - lastImuPacketMs < 100) {  // 10 Hz
    delay(5);
    return;
  }
  lastImuPacketMs = millis();

  FlexReadings flex = readFlexReadings();
  const char* expectedLabel = "-";
  if (kUseHardcodedMlTest) {
    const size_t caseCount = sizeof(kMlTestCases) / sizeof(kMlTestCases[0]);
    const size_t caseIndex = (millis() / 2000) % caseCount;  // switch every 2s
    expectedLabel = kMlTestCases[caseIndex].expected;
    for (int i = 0; i < kModelInputSize; i++) {
      flex.raw[i] = kMlTestCases[caseIndex].flex[i];
      flex.norm[i] = readFlexNormalized(flex.raw[i]);
    }
  }
  const char* predictedLabel = "NA";
  float predictedConfidence = 0.0f;
  const bool predictionOk = classifyFlex(flex, predictedLabel, predictedConfidence);

  ImuSample sample{};
  bool imuSampleOk = imuReady;
  if (imuReady) {
    imuSampleOk = readImuSample(sample);
    if (!imuSampleOk) {
      Serial.println("IMU read failed; marking IMU offline.");
      imuReady = false;
    }
  }

  char payload[512];
  if (imuSampleOk) {
    snprintf(
      payload,
      sizeof(payload),
      "who=0x%02X,ax=%.3f,ay=%.3f,az=%.3f,gx=%.3f,gy=%.3f,gz=%.3f,expected=%s,pred=%s,pred_conf=%.1f,flex0_raw=%d,flex0_norm=%.3f,flex1_raw=%d,flex1_norm=%.3f,flex2_raw=%d,flex2_norm=%.3f,flex3_raw=%d,flex3_norm=%.3f,flex4_raw=%d,flex4_norm=%.3f",
      imuWhoAmI,
      sample.axG,
      sample.ayG,
      sample.azG,
      sample.gxDps,
      sample.gyDps,
      sample.gzDps,
      expectedLabel,
      predictionOk ? predictedLabel : "NA",
      predictionOk ? predictedConfidence : 0.0f,
      flex.raw[0],
      flex.norm[0],
      flex.raw[1],
      flex.norm[1],
      flex.raw[2],
      flex.norm[2],
      flex.raw[3],
      flex.norm[3],
      flex.raw[4],
      flex.norm[4]
    );
  } else {
    snprintf(
      payload,
      sizeof(payload),
      "imu=offline,expected=%s,pred=%s,pred_conf=%.1f,flex0_raw=%d,flex0_norm=%.3f,flex1_raw=%d,flex1_norm=%.3f,flex2_raw=%d,flex2_norm=%.3f,flex3_raw=%d,flex3_norm=%.3f,flex4_raw=%d,flex4_norm=%.3f",
      expectedLabel,
      predictionOk ? predictedLabel : "NA",
      predictionOk ? predictedConfidence : 0.0f,
      flex.raw[0],
      flex.norm[0],
      flex.raw[1],
      flex.norm[1],
      flex.raw[2],
      flex.norm[2],
      flex.raw[3],
      flex.norm[3],
      flex.raw[4],
      flex.norm[4]
    );
  }

  Serial.println(payload);
  if (bleClientConnected && txCharacteristic != nullptr) {
    txCharacteristic->setValue(reinterpret_cast<uint8_t*>(payload), strlen(payload));
    txCharacteristic->notify();
  }
}
