# Recorded static MLP for the October 6 demo

Prepared October 5, retrained October 6, 2026 with all fingers at 425 fully bent
and 625 fully unbent. This is a static letter/number model and software
verification record. Dynamic word training and integration remain separate work.

## What changed

The default ESP32 build now uses a real-recording MLP with the same hidden
architecture as `backend/asl_train.ipynb`: five inputs, Dense(128, ReLU),
Dropout(0.3), Dense(64, ReLU), Dropout(0.2), and softmax output. The output has
34 recorded classes: 0–9 and letters excluding J/Z. Those two motion-based
letters have no training recordings. The synthetic 36-class baseline remains
available through `HH_USE_RECORDED_STATIC_MODEL=0`.

Training uses `backend/recorded_data/trials.csv` and `trials_2.csv`. The recent
session supplies all A, B, 1, and 3 samples; older samples of those four labels
are excluded because the current sensor readings differ substantially. The
other 30 labels use the older session. Selected data totals 8,093 frames across
52 trials. A/B/3 have five recent trials each; 1 has six. Other classes have
one trial each, except 2 with two.

Each class receives equal total training weight before priority weighting;
each trial within a class receives equal total weight. A/B/1/3 receive 4x
per-class weight. This prioritizes the requested demo signs without removing
the other recorded classes from the model. It does not guarantee live accuracy.

## Preprocessing and deployment

Training reads the calibration directly from `ESP32/include/firmware_config.h`.
All five fingers use raw 425–625, with clamping at either endpoint.
Thumb/index/middle/ring map to 120–550; pinky maps to 80–560, matching the
preserved baseline's finger-specific model endpoints. A weighted StandardScaler
is fitted only on training trials, then applied after calibration. Runtime uses the identical
calibration and the exported float32 mean/scale values.

The generated `ESP32/include/recorded_static_model_data.h` packages model bytes,
scaler, labels, and compile-time calibration checks. The model is 47,128 bytes
(46.0 KiB), with SHA256:

```text
d705da905a48e25649be3b64a2d2b309061a9220aab7eed555f5124e2bde7040
```

The original `ESP32/src/asl_model_data.h` and original backend model/scaler
artifacts are preserved. Keras/TFLite artifacts and full reports are in
`backend/models/static_runs/recorded-priority-v5-all425-625/`; this directory is ignored
by Git. Back it up with the recorded dataset if moving machines. The generated
header is sufficient to build the deployed firmware. The previous 400-bound
run, `recorded-priority-v2/`, and thumb/index 200–515 run,
`recorded-priority-v3-bent200/`, are retained separately for rollback.

## Data split and measured results

Seed 42 assigns entire `(session_id, trial_id)` groups to splits. For each
priority label, one trial is held out for validation and one for test; the
remaining trials train the model. The other 30 classes remain train-only because
they lack enough independent repetitions. Adjacent frames never cross splits.
The model trained from new weights with Adam, batch size 32, an 80-epoch limit,
and validation-loss early stopping (patience 8). It stopped after 30 epochs and
restored the best validation checkpoint. Test data was not used to select it.

| Split | Trials | Frames | Labels evaluated | Frame top-1 | Frame macro F1 |
| --- | --- | --- | --- | --- | --- |
| Train (fit diagnostic) | 44 | 6,799 | All 34 | 88.94% | 0.8512 |
| Validation | 4 | 679 | A, B, 1, 3 | 100% | 1.0000 |
| Test | 4 | 615 | A, B, 1, 3 | 100% | 1.0000 |

All four held-out test trials were also correct when averaging their model
probabilities. On those same test frames, the preserved synthetic model with
the current live calibration classified none correctly. This comparison only
describes these four recorded trials. The October 6 retraining reused the same
split and recordings to check the calibration change; this is a regression
check, not a fresh untouched-test experiment or new live accuracy evidence.

Frozen test trial IDs are `static_1_0014`, `static_3_0019`, `static_a_0003`,
and `static_b_0006` in session `session_20261005T213726_982678Z`.

The four test recordings each contain a correct, >=80%-confidence run lasting
3.3–4.4 seconds by device timestamps. This exceeds the app's existing 750 ms,
five-packet hold requirement in offline recorded-data checks. Phone receive
timing and live BLE delivery have not been verified. Model confidence is a
softmax score, not a measured probability of correctness.

These results are **not all-class accuracy**, signer-independent validation,
or a guarantee of fresh live performance. Metadata uses several signer IDs;
the user reports the demo wearer supplied the recordings, so these IDs are not
treated as verified independent participants. The other 30 classes need fresh
recordings on the current glove before their recognition can be relied on.
The model has no rest/unknown class and always chooses a supported label.
41 of 44 training trials have the correct trial-averaged prediction in this run.
The incorrect trial means are C→X, E→A, and W→6. Expanding calibration to all
fingers at 425–625 clamps more of the older recordings and reduces the training
fit from 99.75% frame accuracy in the prior thumb/index 200–515 run to 88.94%.
In particular, the recorded A validation/test frames clamp to the fully bent
model endpoints and receive 86.9% category confidence. This can obscure nearby
poses. Training fit and repeated recorded checks do not establish live accuracy.

## Letter and number practice

ESP32 runs inference once and sends the overall winner plus separate best
letter and number predictions. The new fields are `pred_letter`,
`pred_letter_conf`, `pred_number`, and `pred_number_conf`. Category confidence
retains the original full-model softmax probability; it is not renormalized.

Learner letter practice uses only the best letter. Number practice uses only
the best digit. Selection uses the category, never the desired target label.
An incorrect letter or digit can still be shown. Developer BLE views preserve
the global winner. Older firmware can supply its global prediction when it
belongs to the selected category; an opposite-category label is hidden.

The existing >=80% confidence, >=750 ms duration, >=5 matching packets, and
<=250 ms packet-gap requirements remain. Invalid or non-finite category scores
clear the hold and cannot trigger completion.

## Verification

- ESP32 PlatformIO build: **Passed**. RAM 122,896 / 327,680 bytes (37.5%);
  flash 1,209,945 / 1,441,792 bytes (83.9%).
- Keras/TFLite parity on all selected frames: **Passed**. Maximum absolute
  probability difference `7.748603820800781e-7`.
- Embedded header bytes versus exported model: **Passed**, exact match.
- Five-finger mapping at raw 425, 525, and 625, low/high clamping, exported
  scaler/calibration guards, original source hashes and splits: **Passed**.
- Recorded eligible holds for A, B, 1, and 3: **Passed**, all eight validation/
  test trials. Fresh physical glove/app validation: **Not run**.
- FlatBuffer schema and operator versions: **Passed** compatibility inspection;
  both baseline and candidate use schema 3, FULLY_CONNECTED v1, SOFTMAX v1.
- Configured worst-case online telemetry formatting: **Passed**, 395 bytes
  against the 512-byte buffer. Actual phone notification delivery: **Not run**.
- Focused Flutter analysis: **Passed**, no issues.
- Android debug APK build: **Passed**. Artifact:
  `flutter_app/build/app/outputs/flutter-apk/app-debug.apk`.
- Packet and practice-tracker tests: **Passed**, 11 tests. Checks include
  category selection, unchanged confidence/hold rules, old-firmware fallback,
  opposite-category suppression, and invalid score rejection.
- Physical inference, inference latency, and fresh glove rehearsal: **Not run**.

## Reproduce and rehearse

From the repository root with the existing Python environment:

```powershell
python backend/train_static_recorded.py backend/recorded_data/trials.csv backend/recorded_data/trials_2.csv --priority-labels A B 1 3 --priority-weight 4 --replace-priority-with-latest-source --output-directory backend/models/static_runs/recorded-priority-v6-all425-625 --export-header ESP32/include/recorded_static_model_data.h
python backend/evaluate_static_recorded.py backend/models/static_runs/recorded-priority-v6-all425-625
pio run -d ESP32
```

Use a new run directory to retain prior evidence. TensorFlow/Keras may need
normal access to system temporary directories and caches. The selected run
used TensorFlow 2.21.0 and Keras 3.14.0 on a Windows CPU.

Close any serial monitor before uploading:

```powershell
pio run -d ESP32 -t upload
pio device monitor -d ESP32
```

Confirm the startup line `Static model: real recorded MLP (34 classes)`.
Install `flutter_app/build/app/outputs/flutter-apk/app-debug.apk` or run the
updated Flutter app, then use the same glove wearer to attempt
A and B in Alphabet and 1 and 3 in Numbers. Check both correct matches and
wrong-sign attempts. Record the fresh outcome before claiming a live success.
