#pragma once

#include "sensor_types.h"

bool setupClassifier();
struct ClassPrediction {
  ClassPrediction(const char* classLabel = "NA", float score = 0.0f)
    : label(classLabel), confidence(score) {}
  const char* label;
  float confidence;
};
struct FlexPrediction {
  ClassPrediction overall;
  ClassPrediction letter;
  ClassPrediction number;
};
bool classifyFlex(const FlexReadings& flex, FlexPrediction& prediction);
// Optional demo vectors; returns the expected label, or "-" for live input.
const char* applyClassifierTestInput(FlexReadings& flex);
