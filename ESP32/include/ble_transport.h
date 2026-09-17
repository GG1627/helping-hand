#pragma once

void setupBle();
// Sends one existing telemetry packet when a client is connected.
void sendBlePayload(char* payload);
