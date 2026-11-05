#pragma once

#include "sensor_types.h"

void setupImu();
void updateImu();
// Returns false when offline; failed reads trigger discovery retries.
bool readImuSample(ImuSample& sample);
// ICM-20948 AK09916 only: false for unavailable, not-ready or overflow data.
// Values are uncalibrated microteslas in the magnetometer's native axes.
bool readMagneticSample(MagneticSample& sample);
uint8_t getImuWhoAmI();
