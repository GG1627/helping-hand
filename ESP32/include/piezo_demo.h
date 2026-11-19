#pragma once

#include <stddef.h>

void setPiezoDemoConnected(bool connected);
bool receivePiezoDemoCommand(const char* value, size_t size);
// Call from the Arduino loop, after updatePiezos().
void updatePiezoDemo();
