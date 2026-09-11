# Teach ML Words — Living Implementation Plan

**Issue:** #7
**Status:** Collection, preprocessing, and untrained model-code foundations implemented; physical-device validation and real data collection pending.
**Last updated:** 2026-09-10

## Goal

Extend Helping Hand from static 36-class hand-pose classification to lightweight,
word-level ASL recognition from complete sensor sequences. Preserve the existing
static MLP and its artifacts as a regression baseline while the sequence pipeline
is developed.

The first release will recognize a deliberately small word vocabulary from a
wearable session containing five flex values and six IMU axes per sample:

```text
flex_thumb, flex_index, flex_middle, flex_ring, flex_pinky,
ax, ay, az, gx, gy, gz
```

The repository previously streamed the IMU fields over BLE at 10 Hz; the
collection firmware now targets 40 Hz pending physical delivery tests. This plan
uses the term "feature" for each sensor value; the project wording
"five-channel IMU" must not be confused with the five flex sensors or the
six-axis IMU runtime.

Implementation note (2026-09-09): firmware now targets a configurable 25–50 Hz
rate (40 Hz default), and the recording/export plus backend validation
foundations are implemented. The 40 Hz delivery rate is not yet verified on a
physical phone, and no real word recording or word-model training has occurred.

Implementation note (2026-09-10): configurable TCN, CNN-GRU, and CNN-LSTM
builders plus shared split, training, evaluation, metadata, and float-TFLite
export code are implemented. Synthetic-only tests confirm shapes and built-in
TFLite conversion. No candidate has been trained on real data, benchmarked,
selected, or deployed, and no fixture-trained artifact is retained.

## Working principles

- Real, labeled sign recordings are the source of training and reported model
  performance. Synthetic data is for fixtures, smoke tests, and pipeline
  development only.
- A complete recording/trial is the unit of splitting. Windows from one trial
  must never be separated across training and test data.
- The initial solution must work without a magnetometer. Any yaw-stabilized
  quaternion feature is optional until hardware support is confirmed.
- Every candidate is evaluated with the same data version, word vocabulary,
  preprocessing configuration, and split manifest.
- Deployment suitability is measured along with accuracy: TFLite size,
  inference latency, and runtime compatibility are release criteria.

## Decision checkpoints

| Checkpoint | Decision | Evidence required |
| --- | --- | --- |
| D1 — Vocabulary | Which 6–10 words are in the first model? | A documented list of useful, safely performable, visibly distinct signs. |
| D2 — Hardware | Is a magnetometer accessible on the existing IMU? | Board label/photo and an I2C/firmware probe; `WHO_AM_I=0x70` alone is inconclusive. |
| D3 — Data readiness | Is there enough real data for model work? | Valid recordings from multiple signers, repetitions, and wrist-angle conditions. |
| D4 — Model selection | Which model is deployed? | Same-split benchmark for 1D CNN/TCN, CNN-GRU, and CNN-LSTM, including size/latency. |
| D5 — Orientation path | Which orientation preprocessing is retained? | Comparison of raw/augmented features and gravity-relative or quaternion-derived features on held-out orientations. |

## Phase 0 — Finalize the collection contract

### Tasks

- [ ] Select the initial 6–10-word vocabulary and define an immutable
  `vocabulary_version` (for example, `words-v1`). Avoid words whose distinction
  requires sensors the glove does not have.
- [ ] Agree on a collection protocol: starting pose, a short still lead-in,
  one complete sign, a short still tail, and a rest interval between trials.
- [ ] Set target data coverage: at least 3 signers, 20+ clean repetitions per
  word/signer/orientation condition for a pilot. More signers are more valuable
  than many nearly identical repetitions from one signer.
- [x] Use four initial orientation conditions: `neutral`, `pitch_up`,
  `roll_left`, and `yaw_right`. Add mirrored directions only after the pilot is
  reliable.
- [x] Define participant IDs that are pseudonymous (for example `signer_01`),
  not names or email addresses.
- [ ] Decide where recordings are exported and backed up. Do not commit raw
  recordings to Git unless the team has explicitly approved consent and storage.

### Deliverables

- `docs/word_data_collection_protocol.md`
- `backend/data/README.md` documenting storage locations and data handling
- A fixed vocabulary list and version identifier

### Exit criteria

One person can follow the protocol without verbal interpretation, and a sample
session has all required metadata.

## Phase 1 — Confirm IMU capabilities and recording rate

### Magnetometer check

The detected address (`0x68`) and `WHO_AM_I=0x70` identify an MPU-6500/9250-class
device, not the exact part:

- An MPU-6500 is a six-axis accelerometer/gyroscope and has no magnetometer.
- An MPU-9250 includes a magnetometer, but it must be enabled and read; the
  present runtime reads only the accel/gyro register block.

### Tasks

- [ ] Photograph or read the exact module/chip marking and record it in the
  hardware notes.
- [x] Add a narrowly scoped diagnostic that checks whether an MPU-9250-style
  magnetometer can be accessed. Do this before buying a new module.
- [ ] If unavailable, record the decision: first release uses six-axis fusion,
  pitch/roll normalization where useful, and controlled yaw augmentation.
- [x] Configure BLE sensor capture in the 25–50 Hz target range (40 Hz default).
- [ ] Measure actual delivered packet rate, loss, notification completeness, and
  ordering on the target phone before real collection.
- [x] Add monotonically increasing sample sequence IDs and a device-side
  timestamp if practical. The phone will also attach its receive timestamp.

### Planned files

- `ESP32/src/main.cpp` — packet-rate configuration and recording packet fields
- `ESP32/docs/imu_bringup_diagnostics.md` — confirmed device capability result
- `README.md` — updated BLE packet and sampling-rate documentation

### Exit criteria

The app receives a stable stream at the chosen rate and the team knows whether
magnetometer data is actually available.

## Phase 2 — Build the Flutter recording tab

Add a dedicated **Record Signs** tab rather than placing collection controls in
the diagnostic BLE Testing tab. It will reuse the established BLE connection and
packet parser, but collection must remain understandable to a non-developer.

### User flow

```text
Connect glove
  -> choose word, signer, orientation, and trial number
  -> verify live packet rate and sensor status
  -> start a short countdown
  -> record one complete sign
  -> stop automatically or manually
  -> review validity / discard / save
  -> repeat until the session checklist is complete
  -> export recordings
```

### Required behavior

- [x] Disable recording unless the BLE device is connected and valid packets are
  arriving.
- [x] Display selected metadata, elapsed time, packet count, observed sample
  rate, and a clear recording state.
- [x] Save raw packets exactly as received, plus parsed numeric values and
  collection metadata. Never save only normalized values.
- [x] Support an explicit **Discard** action and a reason such as `bad_sign`,
  `BLE_drop`, or `wrong_label`.
- [x] Warn on too-short recordings, missing fields, packet-rate collapse, or
  duplicate trial identifiers.
- [x] Write a session manifest with app version, firmware `who` value, target
  sampling rate, and schema version.
- [x] Export a selected session as CSV and its manifest as JSON through a
  platform-appropriate share/save action.

### Proposed data layout

```text
recordings/
  raw/
    session_20260909_001/
      manifest.json
      trials.csv
  processed/                 # generated; never manually edited
  splits/                    # generated split manifests
```

`trials.csv` is one row per received packet and contains:

```text
schema_version, session_id, trial_id, sample_index,
device_timestamp_ms, receive_timestamp_ms,
word, vocabulary_version, signer_id, orientation_condition,
who, ax, ay, az, gx, gy, gz,
flex_thumb_raw, flex_index_raw, flex_middle_raw, flex_ring_raw, flex_pinky_raw,
packet_valid
```

If firmware provides calibrated flex values, record them in additional columns;
raw ADC readings remain authoritative. Metadata that is constant for a trial may
be repeated per row so that one CSV remains self-describing.

### Planned files

- `flutter_app/lib/screens/tabs/record_signs_tab.dart` — new collection UI
- `flutter_app/lib/screens/main_shell.dart` — add the tab to navigation
- `flutter_app/lib/services/recording_service.dart` — session, validation, and
  export logic (new)
- `flutter_app/lib/services/ble_packet.dart` — shared parsed-packet model if
  extraction from the current BLE Testing tab is appropriate (new)
- `flutter_app/pubspec.yaml` — only the file/storage/share dependencies actually
  needed after confirming supported platforms
- `docs/word_data_collection_protocol.md` — collector instructions and consent
  reminder

### Exit criteria

A collector can create, discard, save, and export a labeled session on the
target phone. A backend validator accepts the export without hand-editing.

## Phase 3 — Validate and preprocess sequence recordings

### Tasks

- [x] Implement schema validation: required fields, finite numeric values,
  monotonic timestamps, expected labels, and a minimum packet count.
- [x] Report per-trial duration, delivered rate, missing/invalid packets, and
  sensor ranges. Flag rather than silently repair suspicious trials.
- [x] Resample each trial to the agreed fixed rate.
- [x] Segment complete trials into fixed-length word windows by pad/trim or a
  documented activity-boundary rule. Record the selected window strategy in the
  processed-data manifest.
- [ ] Calibrate flex channels per recording session.
- [x] Standardize every model input using parameters fit on training data only.
- [x] Generate deterministic train/validation/test manifests for both:
  - user-dependent: recordings from every signer may appear in each split, but
    never the same trial in more than one split;
  - user-independent: at least one entire signer is held out from training.
- [x] Retain trial IDs, signer IDs, orientation conditions, and schema/data
  version with every processed example.

### Orientation experiments

- [ ] Baseline A: raw sensor sequences with measured data augmentation.
- [ ] Baseline B: gravity-relative pitch/roll or six-axis orientation features.
- [ ] If D2 confirms a usable magnetometer, Baseline C: magnetometer-stabilized
  quaternion/Earth-frame features.
- [ ] Compare all alternatives against the same held-out orientation examples.

### Planned files

- `backend/word_data.py` — schemas, validation, loading, and preprocessing
- `backend/word_dataset.py` — fixed examples, split manifests, and train-only
  standardization
- `backend/prepare_word_sequences.py` — reproducible dataset preparation CLI
- `backend/data/README.md` — schema and split documentation
- `backend/tests/test_word_data.py`, `backend/tests/test_word_dataset.py` —
  validator, preprocessing, and split tests

### Exit criteria

One command creates versioned, reproducible sequences and split manifests from
raw exports; tests cover malformed and valid recordings.

## Phase 4 — Update synthetic data responsibly

The existing `backend/generate_asl_data.py` produces independent static samples
for the legacy 36-class MLP. Leave it intact for that baseline.

### Tasks

- [x] Add a separate word-sequence fixture generator; do not replace the static
  data generator.
- [x] Generate small deterministic fixtures with timestamps, starts/stops,
  smooth motion, temporal variation, sensor noise, packet gaps, and controlled
  orientation changes.
- [x] Use fixtures only for automated tests, pipeline smoke runs, and UI export
  tests. Clearly label all synthetic outputs and exclude them from reported
  real-data accuracy unless a distinct synthetic-only experiment is stated.

### Planned files

- `backend/generate_word_sequence_fixtures.py`
- `backend/tests/test_prepare_word_sequences.py`

### Exit criteria

The complete collection-to-preprocessing path can be tested before real data
arrives, with no risk of synthetic samples being mixed into real evaluation.

## Phase 5 — Benchmark three sequence models

All candidates use the exact processed data version and split manifests from
Phase 3. Start small and regularized: dropout, early stopping, a validation-set
learning-rate schedule, and class weighting only if data imbalance warrants it.

| Candidate | Role | Initial expectation |
| --- | --- | --- |
| Small 1D CNN/TCN | Compact non-recurrent baseline | Strong deployment candidate if it captures the motions well. |
| CNN-GRU | Primary sequence candidate | Likely balance of temporal accuracy and parameter/latency budget. |
| CNN-LSTM | Accuracy comparator | Establish whether the added LSTM complexity produces a meaningful gain. |

### Tasks

- [x] Implement shared training/evaluation code and configuration, not three
  disconnected notebooks.
- [ ] Train each candidate with identical splits and search budgets.
- [ ] Evaluate raw versus selected orientation preprocessing for each promising
  candidate.
- [ ] Export each valid candidate to TFLite and verify numerical outputs on a
  fixed representative sample set.
- [x] Smoke-test untrained candidate shapes and float-TFLite conversion using
  built-in operators only. These tests are compatibility checks, not model
  validation or accuracy evidence.
- [ ] Measure inference latency on the intended runtime. If ESP32 deployment is
  required, validate TensorFlow Lite Micro operator support and memory arena
  usage—not only mobile TFLite conversion.

### Required report for every run

- data and vocabulary version; split manifest and split strategy;
- model architecture, parameter count, regularization, and random seed;
- top-1 accuracy, top-5 accuracy, macro F1, and per-word confusion matrix;
- metrics by signer and orientation condition;
- `.tflite` size, conversion status, and measured latency;
- failure examples and any excluded trials with reasons.

### Planned files

- `backend/word_models.py` — CNN/TCN, CNN-GRU, and CNN-LSTM definitions
- `backend/train_word_models.py` — reproducible training CLI
- `backend/evaluate_word_models.py` — metrics, confusion matrices, and reports
- `backend/tests/test_word_models.py` — shape/conversion smoke tests
- `backend/tests/test_evaluate_word_models.py` — reporting/provenance tests
- `research/word_model_benchmark.md` — experiment results and final decision

### Exit criteria

The three-candidate comparison produces one reproducible report on real data.
No model is selected solely on user-dependent or synthetic results.

## Phase 6 — Select and deploy the word model

### Selection rule

Choose the smallest compatible model that meets the team’s accuracy and
orientation-robustness thresholds. Prefer CNN-GRU when its accuracy is close to
CNN-LSTM but it is smaller/faster. Prefer the 1D CNN/TCN if it is comparable and
substantially easier to deploy. Document the tradeoff rather than selecting by
top-1 accuracy alone.

### Tasks

- [ ] Freeze word labels, preprocessing parameters, window length, and model
  version together.
- [ ] Package model, label map, and preprocessing metadata as one versioned
  artifact.
- [ ] Add streamed-window inference with a confidence threshold and top-3/top-5
  candidate presentation in the Flutter curriculum flow.
- [ ] Keep existing static MLP files and firmware path functional as a regression
  baseline until the word model is independently validated.
- [ ] Perform a real-device end-to-end latency test: sensor packet to displayed
  word suggestion.

### Planned files

- `backend/models/word_model_<version>.tflite`
- `backend/models/word_model_<version>.json` — labels and preprocessing metadata
- Flutter inference integration files, selected after the runtime target is
  confirmed
- `README.md` — deployment and validation results

### Exit criteria

The selected TFLite model runs in the intended product path, shows ranked word
predictions, and has a recorded validation report.

## Immediate next actions

1. Approve the first vocabulary and collection protocol.
2. Inspect the physical IMU module and record its exact part number/photo.
3. Flash the higher-rate firmware and validate delivered rate, packet loss/order,
   and notification completeness on the target phone.
4. Exercise save/discard/export from **Record Signs** and validate the exported
   CSV/manifest without hand editing.
5. Make a short real pilot recording before running the model training scripts.

## Change log

| Date | Update |
| --- | --- |
| 2026-09-10 | Added configurable TCN/CNN-GRU/CNN-LSTM builders, leakage-safe split manifests, train-only standardization, shared training/evaluation metadata, and built-in-only TFLite smoke tests. No real-data training occurred and no fixture-trained artifact was retained. |
| 2026-09-09 | Added 40 Hz configurable firmware packets, shared Flutter BLE/recording export, `word-sequence-v1` validation/preprocessing, and test-only sequence fixtures. Physical validation and real collection remain pending. |
| 2026-09-09 | Initial living plan created from Issue #7 research and current repository state. |
