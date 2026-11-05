# Developer glove calibration

Implemented November 5, 2026. This workflow measures the assembled glove and
exports a versioned development profile. It does **not** change the deployed MLP,
TCN, firmware endpoints, live gyro readings, or magnetic calibration.

## Where to find it

Enable Developer Mode on Home, connect from **Developer → BLE Testing**, then
open **Developer → Glove calibration**. It is absent from learner navigation
when Developer Mode is off. Enter equipment identifiers for the glove, mounting
version, and firmware revision, plus the ranges/filter/rate settings in the notes.
Settings are operator declarations, not verified firmware readback. Do not enter
participant names or credentials.

Finish or discard an active sign trial before calibration. Opening calibration
clears the shell's static practice target, so calibration poses do not award
lesson completion. Calibration captures are kept separate from labeled signs.

## Capture and review

The first version guides **19 steady poses**, three seconds each:

1. Comfortably straight/open hand, repeated twice for all five fingers.
2. Each finger comfortably bent, repeated twice per finger.
3. Glove stationary on a supported surface for gyro bias/noise measurements.
4. Six supported orientations: each positive/negative accelerometer axis up.

Prepare and steady each pose before tapping Capture; the interval begins
immediately. Use another person to operate the phone if needed. Board axes must
be known from the hardware documentation; these checks do not automatically
discover the board-to-hand rotation. Check gyro directions separately in BLE
Testing, then acknowledge that check on the review screen.

Each capture needs at least 60 valid packets spanning three seconds of device
time. Invalid/stale packets, sequence gaps, sensor identity changes, clock
resets, disconnects, missing streams, backgrounding, or leaving the screen cancel
the current capture. Completed poses remain available within the app session.
Repeat previous pose or Start over to replace measurements; starting over
requires confirmation when measurements would be discarded. Unsaved captures
do not survive app termination. The prior saved profile stays active until a
new profile has been saved successfully.

Review shows per-finger median endpoints/span, gyro bias in degrees/s, and
quality messages. Full statistics and raw evidence are available in the export.
Saving requires completed poses, no blocking findings, valid equipment IDs,
settings notes, and the operator gyro-direction check.

## Initial quality checks

These are provisional engineering gates, not experimentally validated sensor
specifications, recognition accuracy thresholds, or a medical assessment:

| Finding | Current behavior |
| --- | --- |
| Flex span below 30 ADC counts | Blocks save |
| Repeated endpoint medians differ by more than max(30 counts, 25% of span) | Blocks save |
| Flex values reach ADC rails, 0 or 4095 | Blocks save |
| Flex hold standard deviation above max(10 counts, 10% of span) | Review warning |
| Straight value below bent value | Review warning; current firmware mapper needs adaptation |
| Stationary gyro SD above 3 degrees/s, or acceleration SD above 0.05 g | Blocks save |
| Stationary acceleration mean magnitude differs from 1 g by more than 0.25 g | Blocks save |
| Stationary gyro mean magnitude on any axis exceeds 5 degrees/s | Review warning |
| Axis pose differs by over 0.25 g per axis from its expected vector, or accel SD exceeds 0.05 g | Blocks save |

Investigate warnings before data collection. Do not change gates merely to make
a failed sensor pass. Changes to these gates require documentation and testing
with real captures. Magnetometer fitting, calibrated gravity/heading, full gyro
scale calibration, arbitrary axis remapping, and short routine fit checks are
not implemented by this first workflow.

## Profile and raw evidence

Saved files are app-private under `calibration/<profile_id>/`:

- `profile.json`: `glove-calibration-v1` metadata, endpoints/repeat statistics,
  gyro bias/noise, six-face checks, warnings, declared equipment/settings, and
  explicit `applied_to_inference=false` / magnetic calibration not performed.
- `captures.json`: exact packet text and receive timestamps for each pose.
- `calibration/active.json`: the last successfully saved profile, loaded on
  launch. A malformed profile produces a visible load-failure message rather
  than applying guessed calibration.

**Export saved profile** opens the Android share sheet with profile and capture
files. Profiles are local equipment data, not learner progress, and are not
uploaded to Firebase. Reinstalling/clearing app storage can remove them; export
and back up important profiles and raw captures in the team's approved location.

## Recording compatibility

New CSV exports append `calibration_profile_id`. The recording manifest embeds
the profile snapshot and ID and sets
`calibration_applied_to_recorded_values=false`. Raw flex and IMU readings remain
unchanged. A session freezes one snapshot when its first trial starts. Saving
a new profile requires exporting/starting a new sign-recording session before
additional trials; it cannot relabel earlier rows. Record Signs displays the
session profile ID or explicitly says no profile is attached.

Old packets, CSV files, manifests, and recordings without calibration remain
supported. The Python loader retains optional profile IDs and rejects linked
rows whose manifest/snapshot does not match. The deployed word tensor remains
the same 11 raw sensor features; a profile reference does not apply normalization.
Verify that a saved profile matches the physical glove/mount before collecting
new data; the app does not automatically identify a physical glove by its ID.

## Using the measurements for the next model

From the repository root, inspect a proposed set of firmware endpoints:

```powershell
python backend/calibration_profile.py path/to/profile.json
```

The helper validates five channels and prints measured straight/bent endpoints.
It writes no firmware/model files and applies no bias. It rejects reversed
polarity or inadequate spans that the current firmware mapper cannot support.
Retain the profile ID alongside any subsequent training/export configuration.

Next, review the ranges on real signs, update the measured endpoint arrays in
firmware, and retrain/export using matching calibration. The current recorded
MLP header has compile-time calibration guards: changing endpoints without a
matching model export intentionally fails compilation. Historical data collected
under different sensor/mount conditions needs its own reviewed preprocessing;
do not blindly reinterpret it with this new profile.

Do not subtract this profile's gyro bias in firmware alone while continuing to
use a TCN trained on uncorrected channels. Any selected correction must match
training and phone preprocessing and be checked on fresh recordings. See the
[IMU reference](../research/ICM20948_INTEGRATION_REFERENCE.md) and
[model optimization plan](DEMO_MODEL_OPTIMIZATION.md) for subsequent experiments.

## Verification boundary

November 5 software verification:

- Full Flutter unit/widget suite: **56 passed**.
- Targeted Flutter analysis across the calibration/recording UI and services:
  **Passed**, no issues.
- Backend calibration, recording, and dataset checks: **26 passed**.
- Android debug APK build: **Passed**.
- Rendered calibration flow: disconnected/connected capture, progression,
  review, and operator-confirmation controls exercised. Layout checks passed at
  390 × 844 and 320 × 720 with 1.6× text; the saved review image was inspected.

The app uses native Flutter and app-private file APIs. Visual QA used Flutter's
widget renderer and simulated BLE packets, rather than a web approximation.

Automated measurement/persistence/session-reference checks, rendered Flutter
interaction/layout checks, backend regressions, and Android compilation cover
software behavior. The rendered test uses simulated sensor packets and exports
`flutter_app/build/calibration-review.png`; it is not a calibration result.
Real glove calibration, physical phone export, repeated donning, and revised
model recognition remain **Not run**. No firmware flashing or model replacement
is part of this change.
