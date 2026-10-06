#pragma once

#include "sensor_types.h"

void setupFlexSensors();
FlexReadings readFlexReadings();
float readFlexNormalized(int raw);
// ADC-equivalent value before the classifier's training standardization.
// Raw acquisition/telemetry and hardcoded regression vectors stay untouched.
float flexModelInput(size_t sensorIndex, int raw);
