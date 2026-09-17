#include <Arduino.h>
#include <esp_timer.h>

#include "firmware_config.h"
#include "ble_transport.h"
#include "classifier.h"
#include "flex_sensors.h"
#include "imu_sensor.h"
#include "telemetry.h"
using namespace std;

namespace {
uint32_t lastSensorPacketUs = 0;
uint64_t sensorSequence = 0;
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

  setupImu();

  if (!setupClassifier()) {
    Serial.println("Classifier setup failed. Continuing without ML predictions.");
  }
  if (kUseHardcodedMlTest) {
    Serial.println("ML TEST MODE ON: using hardcoded flex vectors (not live sensor input).");
  } else {
    Serial.println("ML TEST MODE OFF: using live flex sensor input.");
  }

  setupBle();
  Serial.printf(
    "BLE ready and advertising; configured sensor stream=%lu Hz (%lu us interval)\n",
    static_cast<unsigned long>(kSensorRateHz),
    static_cast<unsigned long>(kSensorIntervalUs)
  );
}

void loop() {
  updateImu();

  const uint32_t nowUs = micros();
  if (static_cast<uint32_t>(nowUs - lastSensorPacketUs) < kSensorIntervalUs) {
    delay(1);
    return;
  }
  lastSensorPacketUs = nowUs;

  const uint64_t packetSequence = sensorSequence++;
  const uint64_t deviceTimestampMs =
    static_cast<uint64_t>(esp_timer_get_time()) / 1000ULL;

  FlexReadings flex = readFlexReadings();
  const char* expectedLabel = applyClassifierTestInput(flex);
  const char* predictedLabel = "NA";
  float predictedConfidence = 0.0f;
  const bool predictionOk = classifyFlex(flex, predictedLabel, predictedConfidence);

  ImuSample sample{};
  const bool imuSampleOk = readImuSample(sample);

  char payload[kTelemetryCapacity];
  formatTelemetry(payload, sizeof(payload), packetSequence, deviceTimestampMs,
                  getImuWhoAmI(), sample, imuSampleOk, flex, expectedLabel,
                  predictedLabel, predictedConfidence, predictionOk);
  Serial.println(payload);
  sendBlePayload(payload);
}
