#pragma once

#include "sensor_types.h"

bool setupClassifier();
bool classifyFlex(const FlexReadings& flex, const char*& outLabel, float& outConfidence);
// Optional demo vectors; returns the expected label, or "-" for live input.
const char* applyClassifierTestInput(FlexReadings& flex);
