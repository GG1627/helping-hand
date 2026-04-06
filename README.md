# Helping Hand (CEN3907C M1 Pre-Alpha)

Helping Hand is a wearable-assisted ASL learning system with an ESP32-based glove and a Flutter mobile app.  
This repository contains the current pre-alpha architecture and implementation for milestone M1.

Repository: https://github.com/GG1627/helping-hand

---

## 1) Project Summary

Helping Hand currently supports:
- Embedded firmware on Adafruit Feather ESP32-S3 that reads IMU data and streams it over BLE.
- Flutter mobile app with a structured multi-tab UI (Dashboard, Alphabet, Numbers, BLE Testing).
- BLE testing screen that scans/connects to the glove and renders live IMU values.
- Early ML pipeline artifacts for ASL classification experimentation.

The pre-alpha focus was architecture validation, communications reliability, and end-to-end data flow for one major use case.

---

## 2) M1 Requirement Mapping (Specification Coverage)

### Effort (20 hours/member equivalent)
- Completed hardware bring-up, firmware architecture revisions, BLE integration, UI architecture refactor, and diagnostic tooling.
- Extensive experimentation and failed attempts were captured and retained in project docs:
  - `ESP32/docs/main_diagnostics_reference.cpp`
  - `ESP32/docs/imu_bringup_diagnostics.md`

### Architectural Elements
- Clear layered architecture is implemented:
  - Hardware layer (Feather ESP32-S3 + IMU sensor bus)
  - Firmware runtime layer (I2C sensor ingest + BLE transport)
  - Mobile interface layer (Flutter tabs and BLE client)
  - Data/ML experimentation layer (backend training notebooks and model outputs)

### External Interface (major use case)
- Mobile BLE Testing tab receives sensor data from ESP32 and displays live values.
- Interface files:
  - `flutter_app/lib/screens/tabs/ble_testing_tab.dart`
  - `flutter_app/lib/screens/main_shell.dart`
  - `flutter_app/lib/screens/start_screen.dart`

### Persistent State (major use case)
- Current pre-alpha persistent state exists in:
  - Model artifacts and parameters:
    - `backend/models/asl_model.keras`
    - `backend/models/asl_model.tflite`
    - `backend/models/scaler_params.json`
  - Dataset artifact:
    - `backend/data/asl_synthetic.csv`
- App-level local state is maintained in Flutter and wired between tabs for user progress and BLE-session visualization:
  - `flutter_app/lib/screens/main_shell.dart`
  - `flutter_app/lib/screens/tabs/dashboard_tab.dart`
  - `flutter_app/lib/screens/tabs/ble_testing_tab.dart`
- Data strategy for pre-alpha is local-first to validate architecture quickly; Firebase integration is an active next-step extension of this state pipeline.

### Internal Systems (major use case)
- Firmware internal processing pipeline:
  1. Detect and initialize IMU
  2. Sample accel/gyro values
  3. Format packet
  4. Transmit over BLE notify
- Implemented in:
  - `ESP32/src/main.cpp`

### Information Handling
- Structured packet format over BLE:
  - `who=0xNN,ax=...,ay=...,az=...,gx=...,gy=...,gz=...`
- Flutter parser validates packets and only updates UI when required fields are present and parseable.
- Relevant files:
  - `ESP32/src/main.cpp`
  - `flutter_app/lib/screens/tabs/ble_testing_tab.dart`

### Communication
- BLE transport implemented with Nordic UART-style service:
  - Service: `6E400001-B5A3-F393-E0A9-E50E24DCCA9E`
  - RX: `6E400002-B5A3-F393-E0A9-E50E24DCCA9E`
  - TX notify: `6E400003-B5A3-F393-E0A9-E50E24DCCA9E`
- Firmware and app UUIDs are aligned and tested.

### Integrity & Resilience
- Firmware includes resilience behavior:
  - IMU discovery retry if missing on boot
  - hot-plug detection/recovery in runtime loop
  - re-advertising on BLE disconnect
- Diagnostic hardening work was completed and archived:
  - bus scan, address probing, line checks, and profiling tools in archived diagnostic script
- Evidence:
  - `ESP32/docs/main_diagnostics_reference.cpp`
  - `ESP32/docs/imu_bringup_diagnostics.md`

---

## 3) Current Architecture

### Hardware/Firmware Path
- Board: Adafruit Feather ESP32-S3 (`ESP32/platformio.ini`)
- Sensor bus: I2C on board-defined pins (`SDA=GPIO3`, `SCL=GPIO4`)
- Runtime firmware:
  - `ESP32/src/main.cpp`

### Mobile App Path
- Flutter app root:
  - `flutter_app/lib/main.dart`
- Screen modules:
  - `flutter_app/lib/screens/start_screen.dart`
  - `flutter_app/lib/screens/main_shell.dart`
  - `flutter_app/lib/screens/tabs/dashboard_tab.dart`
  - `flutter_app/lib/screens/tabs/alphabet_tab.dart`
  - `flutter_app/lib/screens/tabs/numbers_tab.dart`
  - `flutter_app/lib/screens/tabs/ble_testing_tab.dart`
- Shared style/components:
  - `flutter_app/lib/theme/warm_clay_theme.dart`
  - `flutter_app/lib/widgets/warm_components.dart`

### ML/Backend Path (Preliminary)
- Data generation and training notebooks/scripts:
  - `backend/generate_asl_data.py`
  - `backend/asl_train.ipynb`
  - `backend/demo.ipynb`

---

## 4) Major Use Case (Implemented End-to-End)

Use case: **Read glove IMU data and show it in mobile app**

1. ESP32 initializes BLE and advertises as `HelpingHand-Glove`.
2. ESP32 reads IMU samples and serializes packet text.
3. Flutter BLE tab scans and connects to the glove.
4. Flutter subscribes to notify characteristic.
5. Flutter parses packets and updates live metric cards.

---

## 5) Work Completed (Including Failed Attempts)

### Completed
- Modularized Flutter app structure with bottom-tab architecture.
- Implemented warm-clay design system and responsive UI shell.
- Built BLE testing screen with scan/connect/notify/send controls.
- Added live IMU value parsing/rendering in app.
- Implemented ESP32 BLE runtime with IMU streaming.
- Added Android/iOS BLE permission/usage config in Flutter app.

### Experiments + Failures (Documented)
- Initial IMU module repeatedly failed ACK on `0x68/0x69`.
- Multiple firmware/library attempts were tested:
  - Adafruit MPU6050 path
  - MPU6050_tockn path
  - direct register probing
- Deep diagnostics confirmed bus health and isolated module issues.
- Swapping to a different IMU board resolved detection; observed `WHO_AM_I=0x70` (MPU6500/9250-class behavior), so runtime was generalized accordingly.

Diagnostic references:
- `ESP32/docs/main_diagnostics_reference.cpp`
- `ESP32/docs/imu_bringup_diagnostics.md`

---

## 6) Setup & Run

## Firmware (ESP32)

1. Enter firmware project:
```bash
cd ESP32
```

2. Build and upload:
```bash
python -m platformio run --target upload
```

3. Monitor serial:
```bash
python -m platformio device monitor --baud 115200
```

Expected runtime lines include:
- `BLE ready and advertising`
- IMU packets beginning with `who=...`

## Flutter App

1. Enter app project:
```bash
cd flutter_app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run on physical Android device:
```bash
flutter run
```

Notes:
- BLE hardware scanning is not reliable on Android emulator.
- For BLE validation, use a real device.

---

## 7) Known Bugs / Limitations

- iOS testing is blocked on this Windows-first workflow unless a macOS build/sign step is used (local Mac or cloud Mac/TestFlight).
- BLE scan behavior on Android emulator is not representative of real hardware.
- IMU packet integrity currently relies on lightweight parse checks; no CRC/checksum is yet implemented.
- Full production cloud persistence is not yet integrated into runtime flow (Firebase path is in progress).
- Session-level data retention and historical analytics are still pre-alpha scope and not finalized.

---

## 8) Submission/Presentation Checklist (M1)

- [ ] Prepare 1-2 page PDF report that references this README sections.
- [ ] Include repository link in report: `https://github.com/GG1627/helping-hand`
- [ ] Present and defend pre-alpha architecture/work in stakeholder meeting.
- [ ] Keep all known bugs updated in this README before submission.
- [ ] Ensure time-stamped evidence exists in repository commit history and dated artifacts.

---

## 9) Quick File Guide

- Firmware runtime: `ESP32/src/main.cpp`
- Firmware diagnostics archive: `ESP32/docs/main_diagnostics_reference.cpp`
- Firmware diagnostics report: `ESP32/docs/imu_bringup_diagnostics.md`
- Flutter BLE screen: `flutter_app/lib/screens/tabs/ble_testing_tab.dart`
- Flutter shell/navigation: `flutter_app/lib/screens/main_shell.dart`
- ML training notebook: `backend/asl_train.ipynb`
