#pragma once

#include "sensor_types.h"

void setupFlexSensors();
FlexReadings readFlexReadings();
float readFlexNormalized(int raw);
