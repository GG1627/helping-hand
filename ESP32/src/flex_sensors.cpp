#include "flex_sensors.h"

using namespace std;

float readFlexNormalized(int raw) {
  // ESP32 ADC DEFAULT IS 12 BITS
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

