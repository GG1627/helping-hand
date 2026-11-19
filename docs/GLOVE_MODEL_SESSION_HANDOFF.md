# Glove and model development handoff

Last updated: November 19, 2026. Read this first when resuming sensor,
calibration, ML, or demo-readiness work. The current working build includes
app changes pending code review and commit. The November 6 preparation
and verification notes remain below as historical records.

## Where we stopped

The planned demo is **G → Z → 3 → Hello → Please** on the wired perfboard glove
with laptop USB power. Gael reported repeated live G and word recognition and
confirmed the automatic Number 3 haptic demo worked on the glove. The J/Z
recognizer and the new word cue sequences have software results. Rehearse Z
and the Hello/Please playback on the presentation phone and glove before
making live performance claims. See the [run sheet](../post_mortem_presentation/demo_checklist.md).

The November 19 export has 123 real trials and 14,824 frames. It includes five
J and six Z attempts. Thumb and index tracked together, and ring reached the
ADC rail in 3,655 frames. The number 3 cue uses measured middle and pinky bands.
The later seven-word export adds 53 attempts. The selected expanded TCN uses
middle, pinky, and the six inertial axes. Sorry and No use this bundle in
practice. Thank You and Eat need fresh trials together to check their
separation before either is enabled. See the
[word experiment](FINAL_REPORT_EVIDENCE_CHECKLIST.md#eval-06-expanded-word-tcn)
and [recording details](FINAL_REPORT_EVIDENCE_CHECKLIST.md#data-03-additional-word-recordings).

## Current runtime and evidence

| Area | Current state | Important limit |
| --- | --- | --- |
| Static recognition | Default ESP32 recorded MLP: five calibrated flex inputs, 34 letter/number classes excluding J/Z | Legacy 36-class baseline is preserved; current endpoints are 425 bent / 625 straight for all five fingers and must be rechecked on replacement sensors |
| J/Z recognition | A separate phone TCN uses six IMU axes and a 160-sample, 40 Hz window. It accepts J or Z through a Start/Finish attempt and has an `other` class. | Offline replay accepted 4/4 matching held-out attempts and 0/36 unrelated attempts. Some of those attempts were examined during development. Live J/Z use and signer independence are unverified. |
| Word recognition | Hello, Please, and Yes use the rehearsal TCN. Sorry and No use the expanded TCN. Start/Finish attempts award saved completion. All eight lesson rows appear in Words. | Both models accept 160 samples at 40 Hz and 11 input features. Sorry and No have offline results; live tests are Not run. Thank You, Eat, and Drink are practice lessons without scored recognition. |
| Historical word data | 15 real attempts, five per word; original split 9 train / 3 validation / 3 test | Reported signer IDs do not prove independent wearers; historical test attempts are development/regression evidence after further tuning |
| IMU transport | Six motion axes plus optional magnetic status/vector through firmware, BLE, Flutter, and recording export. Gael reported the installed ICM-20948 working. | The six-face diagnostic flagged two Y captures. The cause and magnetic fusion behavior need verification. |
| Calibration | Developer-only guided capture, local save/export, raw evidence, and profile-linked recording snapshots | Measurement only: profiles are not automatically applied to firmware readings, model inputs, or magnetic fusion |
| Candidate preprocessing | Python and Flutter use explicit feature order and configurable windows. The J/Z and word bundles have respective 160 × 6 and 160 × 11 contracts. | A different contract needs newly trained weights and matching metadata. Dart and Python J/Z input tensors matched on the 40 held-out recordings. |
| Training augmentation | Recorded static and generic sequence trainers accept bounded training-only copies. The J/Z trainer uses training-only timing offsets. | Fit transformations on training trials and keep whole attempts separate during evaluation. |
| Demo evaluation | Offline replay uses the actual Flutter completion rules, with positive and negative target exposures | Replay does not establish live BLE reliability, body placement, general ASL validity, or native phone latency |
| Standalone boot | Optional USB Serial wait is bounded to approximately 1,500 ms before continuing setup | Firmware/host checks passed; physical battery-only startup is Not run |
| Haptics | Manual BLE output testing, automatic Number 3 cues, and preset Hello/Please playback use the same bounded pulses. | Gael confirmed manual mapping and Number 3 playback. The word cues have simulated results. See the [haptic handoff](HAPTIC_ENGINEERING_HANDOFF.md). |

The rehearsal word TCN uses five raw flex readings plus
`ax, ay, az, gx, gy, gz`. The expanded TCN selects middle, pinky, and those six
motion axes. J/Z use those motion axes alone. A wrist IMU measures motion and
orientation, while body-relative position, finger spread/contact, and other-hand
activity require separate evidence.

## Completed preparation and references

The following sections retain the November 6 preparation and its planned tests.
Use the November 19 status above for the active demo and resume point.

| Change | Commit / documentation |
| --- | --- |
| Optional AK09916 magnetic telemetry, backward-compatible packets, Flutter parsing, CSV/JSON export | `ea38c33`; [magnetic recording](MAGNETOMETER_RECORDING.md) |
| Main-wearer model audit and ICM-20948 integration research; developer calibration workflow and profile-linked captures | `7cf20c7`; [optimization plan](DEMO_MODEL_OPTIMIZATION.md), [IMU reference](../research/ICM20948_INTEGRATION_REFERENCE.md), [calibration guide](DEVELOPER_CALIBRATION.md) |
| Configurable feature layouts/windows, reject-overlength option, shared Python/Flutter preprocessing fixtures | `4890f24`; [sequence preparation](SEQUENCE_PREPROCESSING.md) |
| Bounded optional USB startup wait and offline demo evaluation using production Flutter rules | `2c5c9e8`; [startup and replay guide](DEMO_READINESS_TOOLS.md) |
| Training-only augmentation, recorded-static frozen splits/deferred test evaluation, source-origin checks, and this handoff | November 6 follow-up; [training augmentation](TRAINING_AUGMENTATION.md) |

The audit found substantial historical flex clipping under the current static
endpoints and that 7/15 word attempts are trimmed by the former 96-sample
window, including every Yes attempt. A 224-sample window retains all resampled
points in those historical attempts but adds padding and computation. It is an
**untrained candidate**, not a demonstrated accuracy improvement or a chosen
replacement. Review the audit and coverage evidence before selecting a window.

The latest augmentation implementation adds:

- `backend/training_augmentation.py`: deterministic parent-specific raw-feature
  perturbations, constant trial offsets plus per-sample bounded noise, lineage
  hashes, train-only parent enforcement, and parent total-weight conservation.
- `--augmentation-config` in `backend/train_static_recorded.py` and
  `backend/train_word_models.py`; original train-only scalers and original
  validation/test observations are retained. Word padding is stripped and
  recreated from perturbed endpoints.
- Static `--split-manifest` with exact trial/source-hash checks, `--defer-test`,
  and origin manifests. Fixture runs require `--allow-synthetic-smoke`, cannot
  mix with real data, and cannot export a firmware header.
- `augmentation_manifest.json` and model metadata showing original/expanded
  training counts, limits, origin, parent identities, seeds, and weights.
- [A disabled config](examples/training_augmentation.disabled.json) and tests
  for leakage guards, determinism/bounds, padding, provenance, and invalid data.

No guessed real noise limits or generated letter/word recordings are supplied.
Generated descendants remain training material, not independent evaluation
attempts. Copy counts change batches and loss scaling; compare original
validation behavior rather than comparing training losses across copy counts.

## First session with the assembled glove

1. **Inventory the actual assembly.** Confirm the five flex channels, IMU board,
   wiring, sensor-to-hand axes, mounting version, firmware/app revisions, phone,
   and power source. Inspect the IMU reference before probing the new board.
   Photograph the mount/axis directions and use equipment IDs rather than names.
2. **Verify startup and telemetry.** Check battery-only boot/advertising,
   connection/reconnection, all flex channels, acceleration and gyro directions,
   magnetic status, and complete packets on the intended phone. Measure actual
   delivered rate/gaps against the 40 Hz target. If magnetic data is unreliable,
   preserve its unavailable status and use the supported six-axis path.
3. **Capture developer calibration.** Enable Developer Mode on Home, connect via
   Developer -> BLE Testing, then open Developer -> Glove calibration. Record
   equipment/settings notes and complete the 19 guided steady poses. Investigate
   blocking findings, saturation, repeatability warnings, and axis mismatches.
   Export both `profile.json` and `captures.json` before clearing app data.
4. **Review measurements before changing inference.** Inspect per-finger ranges,
   clipping on real signs, stationary noise/bias, and repeatability after
   re-donning. `python backend/calibration_profile.py path/to/profile.json`
   previews proposed endpoints without editing firmware. Saving a profile alone
   does not apply it to models. Changing static endpoints requires a matching
   retrained/exported model header; compile-time guards enforce this. Any gyro
   correction must match training and phone preprocessing as well as firmware.
5. **Freeze the first data-collection scope.** Start with the main wearer and
   Hello/Please/Yes, then confirm the selected static demo targets. A/B/1/3 have
   stronger historical held-out coverage but are not a confirmed final list.
   Keep J/Z as separately labeled future motion work; neither deployed model
   currently recognizes them.
6. **Record independent repetitions and negatives.** Include separate sessions,
   re-donning, intended wrist-angle variation, confusable signs, idle/unrelated
   movement, and incomplete attempts. Label the sign actually performed and
   preserve failed attempts. Export raw CSVs and manifests with the frozen
   calibration snapshot before changing sensor/mount/session settings.

Calibration is development equipment characterization. Repeat it when sensors,
mounting, wiring, ranges/filters, or relevant behavior change; it is not a
guaranteed one-time setting and is not a learner onboarding requirement today.
The current workflow does not perform magnetometer hard/soft-iron fitting or
full orientation fusion. Magnetic/fusion experiments require separate validation.

## Model work after those captures

1. Validate exports and inspect raw distributions, per-channel noise, clipping,
   packet gaps, feature completeness, and sign duration. Decide whether historical
   and replacement-sensor recordings are compatible before pooling them.
2. Reserve fresh final-evaluation attempts. Freeze whole-trial development
   splits; fit scalers/augmentation limits from training/development evidence.
   Do not choose split seeds, omit difficult trials, or lower confidence rules
   to obtain a better-looking result.
3. Train an unaugmented real-data baseline with `--defer-test`, then compare
   measured augmentation on the same sources/splits/preprocessing/hyperparameters.
   A flex endpoint range alone is insufficient to infer sign distributions or
   physically plausible noise. Record capture references supporting each bound.
4. Compare legacy 96-sample preprocessing with a justified longer window and
   suitable TCN receptive field. Compare 11 versus 14 features only when actual
   complete magnetic recordings exist. Treat fusion, temporal normalization,
   and additional vocabulary as separate experiments, preserving meaningful
   sign orientation and keeping Python/Flutter contracts in agreement.
5. Select using original validation completion/false-completion behavior,
   per-target results, model size, and measured intended-phone latency. Retain
   the MLP and TCN baselines; compare other architectures only when useful.
6. Freeze the selected model, scaler, feature order, vocabulary, calibration,
   window policy, and acceptance rules. Evaluate reserved real attempts, then
   rehearse with the physical glove/phone, including disconnects, navigation,
   and saved completion. Report the personalized, selected-sign scope.

Use the [demo replay plan templates](DEMO_READINESS_TOOLS.md) to inspect both
correct and false completions. A capture failure is not proof of rejection.
Keep reportable final attempts separate from training, tuning, fixture checks,
and historical replays.

## Verification and files to retain

For the augmentation follow-up, the final complete backend suite passed
**82 tests** (`python -m pytest backend/tests -q -p no:cacheprovider`), including
the new static-source/split guards. Dependency deprecation warnings were
non-failing. Synthetic one-epoch
baseline/augmented runs passed for MLP and TCN, including conversion and checks
of identical source hashes, frozen splits/scalers, unchanged original validation
counts, deferred test reports, parent lineage/weights, and fixture reporting
flags. These establish software behavior, not recognition quality.

The preceding startup/replay update records 63 Flutter unit/widget passes,
targeted analysis, firmware compilation, and a startup host test. Earlier guides
record Android debug builds and preprocessing parity checks. These are dated
results for their respective changes; the augmentation follow-up changes backend
code/docs only and does not constitute a new hardware or Android validation.

Physical new-board calibration, measured noise limits, real augmented-model
comparisons, repaired-glove recognition, battery-only boot, phone export, magnetic
fusion, unknown-motion rejection, and intended-phone latency remain **Not run**.

Keep raw exports, calibration captures, manifests, frozen split files, trained
bundles, and detailed reports in approved team storage. Model run folders under
`backend/models/word_runs/` and `backend/models/static_runs/` are ignored and are
not restored by cloning source alone. Retain deployed artifact backups separately.
Local `tmp/augmentation-smoke-20261106/`, `tmp/demo-replay-check-20261106/`, and
other `tmp/` outputs are diagnostics, not committed project evidence or required
inputs for resuming work. Use new output directories and preserve original files.

Other backlog items remain separate from this model-preparation stopping point:
the README's static-practice lifecycle bug, live BLE/power behavior, haptic cue
integration/circuit testing, and unfinished PCB work. Do not describe the entire
product as hardware-validated or feature-complete.

## Suggested prompt for a new session

> Read AGENTS.md, the current status above, and docs/HAPTIC_ENGINEERING_HANDOFF.md.
> Rehearse Sorry and No with the connected glove. Collect a fresh session with
> alternating Thank You and Eat attempts to check confusion, plus idle and
> unrelated movements for rejection checks. Drink is pending collection. Record
> live outcomes and confirm additional cue patterns before extending playback.
