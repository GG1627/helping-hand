#pragma once

#include <Arduino.h>

// Order matches PIEZO_PINS in firmware_config.h. These are buzzer outputs,
// not sensor inputs. The dorsal names match the schematic resistor names.
enum class Piezo : uint8_t {
  Thumb, Index, Middle, Ring, Pinky,
  HandLeft, HandRight, HandCenter, HandUp, HandDown,
  Count
};

// Initializes all outputs LOW; does not sound a startup cue.
void setupPiezos();
// Call from loop() so a pulse ends without blocking sensor/BLE work.
void updatePiezos();
void stopPiezos();
// One passive-piezo tone at a time. Busy/invalid requests return false.
// Frequency must be chosen for the actual buzzer/driver before use.
// Call only from the main Arduino task, after setupPiezos().
bool startPiezo(Piezo output, uint32_t frequencyHz, uint32_t durationMs);
