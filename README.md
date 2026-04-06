# Helping Hand

Helping Hand is a wearable-assisted ASL learning project built around an ESP32 glove and a Flutter app.  
The system currently demonstrates a full sensor-to-app path: embedded IMU capture, BLE transport, and live visualization on mobile.

Repository: https://github.com/GG1627/helping-hand

## Project goals

- Build a practical ASL learning workflow that combines wearable sensing and guided mobile practice.
- Capture motion/sensor signals from glove hardware.
- Process and transmit device data in real time.
- Present learner progress and live sensor state in a clean, modular app.
- Evolve toward cloud-backed persistence and ML-assisted sign classification.

## Repository layout

- `ESP32/`  
  PlatformIO firmware for Adafruit Feather ESP32-S3, including BLE runtime and IMU integration.

- `flutter_app/`  
  Flutter app with modular tab-based UI and BLE client functionality.

- `backend/`  
  Data generation + ML experimentation (training notebooks and model artifacts).

- `embedded/`  
  Additional embedded prototyping area.

## System architecture

### 1) Embedded runtime (`ESP32/src/main.cpp`)

- Board target: `adafruit_feather_esp32s3`
- I2C sensor bus initialized from board-defined pins (`SDA=GPIO3`, `SCL=GPIO4`).
- IMU discovery attempts addresses `0x68` and `0x69`.
- Runtime reads raw accel/gyro registers and converts to engineering units.
- BLE service advertises as `HelpingHand-Glove`.
- Sensor packets are sent as BLE notifications.

Resilience behavior:
- retries IMU discovery if not found at boot
- recovers when IMU appears later (hot-plug flow)
- restarts advertising after client disconnect

### 2) Mobile runtime (`flutter_app/lib/`)

- App shell is split into independent screens/tabs:
  - Start screen
  - Dashboard
  - Alphabet
  - Numbers
  - BLE Testing
- BLE Testing tab handles:
  - adapter state monitoring
  - permission checks
  - scan/connect/disconnect
  - characteristic discovery and notify subscription
  - packet parsing and live metric updates
  - debug event logging in-app
- Basic Firebase persistence path is integrated for app-side data flow.

### 3) Data + ML workspace (`backend/`)

- Synthetic ASL data generation script
- Training notebooks
- Saved model artifacts:
  - `backend/models/asl_model.keras`
  - `backend/models/asl_model.tflite`
  - `backend/models/scaler_params.json`

## BLE protocol details

BLE transport uses Nordic UART-style UUIDs shared by firmware and app:

- Service: `6E400001-B5A3-F393-E0A9-E50E24DCCA9E`
- RX (app -> ESP32): `6E400002-B5A3-F393-E0A9-E50E24DCCA9E`
- TX (ESP32 -> app notify): `6E400003-B5A3-F393-E0A9-E50E24DCCA9E`

Packet format:

```text
who=0xNN,ax=...,ay=...,az=...,gx=...,gy=...,gz=...
```

Example:

```text
who=0x70,ax=0.020,ay=0.008,az=1.029,gx=-5.947,gy=1.435,gz=-0.260
```

## Current implementation status

Working:
- ESP32 BLE advertising and live IMU packet transmission
- BLE receive verification on phone tools (nRF Connect)
- Flutter BLE screen parsing + live value display
- Modular Flutter app structure and progress UI flow
- Basic Firebase-backed persistence path connected

In progress:
- Flex sensor hardware integration (sensors not available before current build cutoff)
- Sign classification runtime integration with embedded/mobile flow
- Additional data integrity controls (packet checksum/CRC, stronger validation)

## Setup and run

## ESP32 firmware

```bash
cd ESP32
python -m platformio run --target upload
python -m platformio device monitor --baud 115200
```

Expected runtime output:
- `BLE ready and advertising`
- continuous IMU packets beginning with `who=...`

## Flutter app

```bash
cd flutter_app
flutter pub get
flutter run
```

## Hardware and platform notes

- BLE testing should be done on real hardware.
- Android emulator BLE scanning is not representative for real-device discovery.
- iOS deployment requires Apple signing and a macOS build path (local Mac or cloud Mac workflow).

## Testing and debugging workflow

Primary validation flow used:
- verify ESP32 serial stream
- verify BLE advertisement + notify with nRF Connect
- verify Flutter app scan/connect/parse/render on physical Android device

Deep IMU bring-up diagnostics were developed during integration and preserved for reproducibility:
- `ESP32/docs/main_diagnostics_reference.cpp`
- `ESP32/docs/imu_bringup_diagnostics.md`

These diagnostics include:
- I2C scans and address probing
- register reads and sensor profiling
- line-state checks
- bus recovery experiments
- failure logs and recovery outcomes

## Known limitations

- Packet-level integrity checks (CRC/checksum) are not yet enabled.
- Full production cloud data model is still evolving.
- Flex-sensor-dependent features remain pending hardware availability.

## Key files

- Firmware runtime: `ESP32/src/main.cpp`
- Firmware diagnostics archive: `ESP32/docs/main_diagnostics_reference.cpp`
- Firmware diagnostics notes: `ESP32/docs/imu_bringup_diagnostics.md`
- Flutter BLE screen: `flutter_app/lib/screens/tabs/ble_testing_tab.dart`
- Flutter app shell: `flutter_app/lib/screens/main_shell.dart`
- Flutter start screen: `flutter_app/lib/screens/start_screen.dart`
- ML training notebook: `backend/asl_train.ipynb`
