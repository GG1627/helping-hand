#pragma once

#include "firmware_config.h"

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

