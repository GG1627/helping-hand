#include "piezo_demo.h"

#include <Arduino.h>
#include <cstring>

#include "ble_transport.h"
#include "firmware_config.h"
#include "piezo.h"

namespace {
constexpr char kPrefix[] = "HP1,";
constexpr uint32_t kMaximumCommandAgeMs = 150;

enum class CommandType { None, Enable, Play, Stop };
struct Command {
  CommandType type = CommandType::None;
  uint16_t id = 0;
  uint8_t slot = 0;
  uint32_t receivedMs = 0;
};

portMUX_TYPE commandLock = portMUX_INITIALIZER_UNLOCKED;
Command pending;
bool connected = false;
bool armed = false;
uint16_t lastCommandId = 0;
uint32_t connectionEpoch = 0;

// Only the Arduino loop owns output state.
uint32_t loopEpoch = 0;
uint16_t activeRequest = 0;

bool parseNumber(const char*& next, const char* end, uint16_t& result) {
  uint32_t value = 0;
  const char* start = next;
  while (next != end && *next >= '0' && *next <= '9') {
    value = value * 10 + static_cast<uint32_t>(*next++ - '0');
    if (value > UINT16_MAX) return false;
  }
  result = static_cast<uint16_t>(value);
  return next != start;
}

void sendEvent(char event, uint16_t id, int slot = -1) {
  char payload[20];
  if (slot < 0) {
    snprintf(payload, sizeof(payload), "HP1,%c,%u", event, static_cast<unsigned>(id));
  } else {
    snprintf(payload, sizeof(payload), "HP1,%c,%u,%d", event, static_cast<unsigned>(id), slot);
  }
  sendBlePayload(payload);
}

bool isCurrentAndArmed(uint32_t epoch) {
  portENTER_CRITICAL(&commandLock);
  const bool current = connected && armed && connectionEpoch == epoch;
  portEXIT_CRITICAL(&commandLock);
  return current;
}

}

void setPiezoDemoConnected(bool value) {
  portENTER_CRITICAL(&commandLock);
  connected = value;
  armed = false;
  lastCommandId = 0;
  pending = Command{};
  ++connectionEpoch;
  portEXIT_CRITICAL(&commandLock);
}

bool receivePiezoDemoCommand(const char* value, size_t size) {
  if (size < sizeof(kPrefix) - 1 || memcmp(value, kPrefix, sizeof(kPrefix) - 1) != 0) {
    return false;
  }
  if (size < 7 || size > 16 || value[5] != ',') return true;
  const char* next = value + 6;
  const char* end = value + size;
  Command command;
  if (!parseNumber(next, end, command.id) || command.id == 0) return true;
  command.receivedMs = millis();
  switch (value[4]) {
    case 'Q':
      command.type = CommandType::Enable;
      break;
    case 'P': {
      uint16_t slot = 0;
      if (next == end || *next++ != ',' || !parseNumber(next, end, slot) || slot >= PIEZO_COUNT) {
        return true;
      }
      command.type = CommandType::Play;
      command.slot = static_cast<uint8_t>(slot);
      break;
    }
    case 'S':
      command.type = CommandType::Stop;
      break;
    default:
      return true;
  }
  if (next != end) return true;

  portENTER_CRITICAL(&commandLock);
  if (connected && command.type == CommandType::Stop) {
    armed = false;
    pending = command;
    if (command.id > lastCommandId) lastCommandId = command.id;
  } else if (connected && pending.type == CommandType::None &&
             command.id > lastCommandId) {
    pending = command;
    lastCommandId = command.id;
  }
  portEXIT_CRITICAL(&commandLock);
  return true;
}

void updatePiezoDemo() {
  portENTER_CRITICAL(&commandLock);
  const uint32_t epoch = connectionEpoch;
  const bool clientPresent = connected;
  const Command command = pending;
  pending = Command{};
  portEXIT_CRITICAL(&commandLock);

  if (loopEpoch != epoch) {
    stopPiezos();
    activeRequest = 0;
    loopEpoch = epoch;
  }
  if (!clientPresent) return;
  if (activeRequest && (!piezoOutputActive() || !isCurrentAndArmed(epoch))) {
    stopPiezos();
    sendEvent('E', activeRequest);
    activeRequest = 0;
  }

  switch (command.type) {
    case CommandType::None:
      return;
    case CommandType::Stop:
      stopPiezos();
      activeRequest = 0;
      sendEvent('E', command.id);
      return;
    case CommandType::Enable: {
      portENTER_CRITICAL(&commandLock);
      const bool enable = HH_ENABLE_PIEZO_DEMO_OUTPUT && connected &&
          connectionEpoch == epoch && pending.type != CommandType::Stop;
      if (enable) armed = true;
      portEXIT_CRITICAL(&commandLock);
      sendEvent(enable ? 'R' : 'U', command.id);
      return;
    }
    case CommandType::Play:
      if (activeRequest || !isCurrentAndArmed(epoch) ||
          millis() - command.receivedMs > kMaximumCommandAgeMs ||
          !startPiezo(static_cast<Piezo>(command.slot), kPiezoTestFrequencyHz, kPiezoTestDurationMs)) {
        sendEvent('X', command.id);
        return;
      }
      if (!isCurrentAndArmed(epoch)) {
        stopPiezos();
        sendEvent('X', command.id);
        return;
      }
      activeRequest = command.id;
      sendEvent('A', command.id, command.slot);
      return;
  }
}
