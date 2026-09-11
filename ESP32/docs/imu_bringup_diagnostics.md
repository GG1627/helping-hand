# IMU Bring-Up Diagnostics (Feather ESP32-S3)

## Summary
This project hit an IMU bring-up issue where the sensor was powered but not initially detected over I2C.
After deep diagnostics, the final working state is:
- Feather ESP32-S3 I2C bus is healthy.
- Onboard MAX17048 appears at `0x36` (expected).
- External IMU appears at `0x68`.
- IMU `WHO_AM_I` reads `0x70` (MPU6500/9250-class behavior), not classic MPU6050 `0x68`.

Because of that, runtime was moved to a register-level IMU reader that supports MPU60x0/65x0 class parts without depending on a single device library assumption.

## Board/Environment
- PlatformIO env: `adafruit_feather_esp32s3`
- Board: Adafruit Feather ESP32-S3
- I2C pins from board variant:
  - `SDA = GPIO3`
  - `SCL = GPIO4`
- Onboard fuel gauge:
  - `0x36` (MAX17048)

## What Was Diagnosed
1. Pin-mapping errors:
   - Early tests used invalid/default ESP32 assumptions for S3.
   - Fixed by using board variant pins (`SDA/SCL` constants).

2. Bus-level health:
   - Wire init and scans verified bus health.
   - `0x36` always present confirmed I2C controller and lines were active.

3. Interactive pin tests:
   - Added quick and manual poke checks (short SDA/SCL to GND and verify MCU observes LOW).
   - Used to isolate physical path/contact issues.

4. Device profiling:
   - Added register probes for discovered I2C addresses.
   - Confirmed external IMU eventually responded at `0x68`.
   - `WHO_AM_I=0x70` identified non-6050 variant behavior.

5. Library mismatch risk:
   - MPU6050-only assumptions were too strict for this module.
   - Moved to direct register path for robust compatibility.

## Key Findings
- Power LED on IMU does not guarantee I2C response.
- Consistent ACK at `0x68` + `WHO_AM_I=0x70` means the module is likely MPU6500/9250-class.
- The old module likely had hardware/path issues; replacement module responded reliably.

## Final Runtime Design
Current runtime in `src/main.cpp` now:
- Initializes I2C on board-correct pins.
- Detects IMU at `0x68`/`0x69`.
- Reads `WHO_AM_I`.
- Applies common init registers (`PWR_MGMT_1`, accel/gyro config, DLPF).
- Reads accel/gyro data directly from raw registers (`0x3B` block).
- Streams packets over BLE Nordic UART profile.
- Targets a configurable 25–50 Hz sensor stream (`40 Hz` by default) and adds
  a device sequence number plus monotonic device timestamp to every packet.

## BLE Interface (for Flutter app)
Service/characteristics used:
- Service: `6E400001-B5A3-F393-E0A9-E50E24DCCA9E`
- RX (app -> ESP32): `6E400002-B5A3-F393-E0A9-E50E24DCCA9E`
- TX (ESP32 -> app notify): `6E400003-B5A3-F393-E0A9-E50E24DCCA9E`

Packet format:
- `seq=...,t_ms=...,who=0xNN,ax=...,ay=...,az=...,gx=...,gy=...,gz=...,...`

The existing static-classifier and flex fields remain after the IMU values.
Actual delivered rate, packet loss/order, and full-notification receipt at the
40 Hz default have not yet been verified on the target phone.

## Optional magnetometer identity probe

`WHO_AM_I=0x70` cannot distinguish an MPU-6500 from MPU-9250-class module and
does not confirm a magnetometer. The normal runtime remains accel/gyro-only.

For a diagnostic build only, add this flag under `build_flags` in
`platformio.ini`:

```text
-D HH_ENABLE_AK8963_PROBE=1
```

At IMU initialization the firmware briefly enables auxiliary-I2C bypass, reads
the MPU-9250-style AK8963 `WIA` register at `0x0C`, prints the result, and then
restores the accel/gyro-only configuration. A `WIA=0x48` response is evidence
that the identity register is accessible, but usable calibrated magnetometer
data and the exact physical part still require hardware verification. No
response is consistent with an MPU-6500 or an inaccessible/miswired auxiliary
sensor; record the module marking and probe output before deciding.

## Archived Diagnostic Script
The full deep-diagnostics script used during bring-up is saved as:
- `docs/main_diagnostics_reference.cpp`

This file is intentionally outside `src/` so it is not compiled in normal firmware builds.
