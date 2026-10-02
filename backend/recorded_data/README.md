# Static ASL pilot recording — 2026-09-17

This directory preserves an unedited, real-device pilot export from the
Flutter **Record Signs** flow. It is collection evidence, not a model-ready
training or evaluation set.

## Contents

- `trials.csv`: 5,518 raw BLE frames from 35 saved trials.
- `manifest.json`: session metadata and per-trial quality information.

## Collection summary

- Signer: `signer_01`
- Vocabulary version: `static-asl-v1`
- Labels: static `A`–`Y` (except `J`) and `0`–`9`; `Z` is also excluded.
  `J` and `Z` use motion and are outside this flex-pose pilot.
- Orientation: neutral
- Nominal sample rate: 40 Hz; observed per-trial rate was approximately
  39.7–40.5 Hz.
- Packet validity: all 5,518 saved frames are valid; no sequence gaps were
  observed during the export review.
- Hardware: all five flex channels and MPU data were present during this run.

## Limitations and intended use

Most labels have one independent trial (`2` has two), and the export contains
one signer at one orientation. Frames from a single held pose are correlated,
so they must not be randomly split into train/test sets or used to report
classifier accuracy. Collect multiple independent repetitions per label and
additional signers before training or evaluation.

Do not synthesize a failed sensor channel from the target label. If a future
sensor becomes unavailable, preserve its raw observation and use a
feature-only missing-data strategy fitted on training data only.
