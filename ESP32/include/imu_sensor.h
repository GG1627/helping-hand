#pragma once

#include "sensor_types.h"

void setupImu();
void updateImu();
// Returns false when offline; failed reads trigger discovery retries.
bool readImuSample(ImuSample& sample);
uint8_t getImuWhoAmI();
