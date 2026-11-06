# Standalone startup and demo evaluation

Implemented November 6, 2026. This changes firmware startup and adds offline
evaluation tooling. Models, calibration endpoints, learner thresholds, Firebase
state, and deployed word preprocessing remain unchanged.

## Standalone startup

`setup()` formerly waited indefinitely for a USB Serial host before sensor/BLE
initialization. It now waits at most approximately **1,500 ms** for that optional
connection, then continues. The existing 500 ms delay and sensor/model setup
still follow; 1,500 ms is not a measured total boot time. An already connected
monitor proceeds immediately. Piezos still initialize off before the wait.

The actual wait helper is exercised by a host test covering absent, immediate,
and delayed hosts, zero wait, and unsigned clock wrap. The Feather firmware
build passes. Physical battery-only boot/advertising and reconnect are **Not
run**. Compile success does not prove battery/power wiring or live BLE behavior.

From `ESP32/`, in an MSVC developer command prompt:

```text
cl /nologo /EHsc /std:c++14 /Itest\host /Iinclude test\serial_startup_host_test.cpp /Fo.pio\build\ /Fe.pio\build\serial_startup_host_test.exe
.pio\build\serial_startup_host_test.exe
```

## Offline evaluation

`backend/evaluate_demo.py` prepares predictions and invokes a Flutter test
harness that runs the production `StablePredictionTracker` and
`WordPracticeController`. It does not duplicate their acceptance rules in
Python or lower thresholds to improve results.

- **Static:** original raw-packet predictions by default, or predictions from
  an explicit recorded MLP bundle. Candidate evaluation reuses the static
  trainer's calibration, scaler, and category winners. Confidence is formatted
  to one decimal place to match telemetry, without category renormalization.
  Raw source packets are retained; prediction overrides exist only in replay
  input. Parsed CSV flex values must match the source packet.
- **Words:** the bundled TCN by default, or an explicit candidate bundle.
  Python executes that TFLite model on metadata-defined preprocessing. Flutter
  repeats preprocessing and compares the tensor before using those predictions
  in the production controller. This checks rules and preparation, not native
  Android inference. Predictions are never conditioned on the selected target.
- **Acceptance:** the actual app determines completion, including its 80%
  confidence rule, static 750 ms/five-packet hold and 250 ms gap rule, and word
  capture minimums, gaps, timeout, and complete-attempt finish behavior.

One recording is evaluated against each requested target. This intentionally
tests both its correct target and other targets. `kind=sign` expects completion
only for the actual `performed_label`; `idle`, `incomplete`, and `unrelated`
expect no target to complete. Ground truth must be checked by a human; the
tool does not establish that a sign or its body placement is linguistically
correct. Label the performed sign, not merely the selected lesson.

### Plan and commands

Copy the [static plan](examples/demo_static_plan.example.json) or
[word plan](examples/demo_word_plan.example.json) next to your recording export.
Replace every placeholder and add independent attempts. Paths resolve relative
to the plan. The examples are templates, not existing test results or complete
target coverage. Plan origin must match source manifests; duplicate logical
trials are rejected even if CSV files were copied.

From the repository root, use a Python environment with the backend dependencies
and Flutter on PATH:

```powershell
python backend/evaluate_demo.py path/to/static-plan.json --output-directory path/to/new-static-report
python backend/evaluate_demo.py path/to/static-plan.json --static-bundle backend/models/static_runs/recorded-priority-v5-all425-625 --output-directory path/to/new-mlp-report
python backend/evaluate_demo.py path/to/word-plan.json --output-directory path/to/new-word-report
```

`--word-bundle path/to/candidate` selects another compatible three-word TCN
bundle. `--prepare-only` writes replay input without executing Flutter. Output
directories must be new, preserving earlier runs. Source recordings, model
weights, split manifests, and app progress are not modified. Real recordings
and detailed reports remain in the team's approved private backup location,
outside committed source.

### Timing and boundaries

The default `recorded_receive` timing uses original phone receive timestamps,
matching the static app's hold clock. Duplicate timestamps are counted and
retained. Backward times and gaps are replayed; they are not silently repaired.
Bad collection timestamps can make a replay unrepresentative of live behavior.

`simulated_device` explicitly reconstructs receive timing from device intervals
for a separate ideal-transport experiment. It is **not** a measured BLE or phone
result. Never merge that report with recorded-receive results without labeling
the distinction.

Unless both `start_ms` and `finish_ms` are supplied for a trial, the harness
constructs bounds one millisecond around the recorded packets (finish uses the
maximum receive time to preserve backward-clock events). These are collection
replay bounds, not measured practice-button events. Explicit bounds use the
selected timing clock; only packets in that interval are used, and word model
predictions are prepared on the same subset.

A fresh sensor stream at Start and a continuously connected foreground app are
assumed. CSVs do not capture all connection, navigation, or lifecycle events.
Those behaviors remain covered by dedicated software tests and require live
rehearsal. Device-clock word interpolation and receive-clock capture gates are
kept distinct. Replay completion timing is not end-to-end phone latency.

### Reading the report

`replay_input.json` preserves source/model hashes, packets, candidate prediction
overrides, timing, annotations, and model split membership where available.
`report.json` contains per-trial/target outcomes and per-target summaries:

- Positive attempts, correct/missed completions, and completion rate.
- Negative target exposures, false completions, and false-completion rate.
- Counts by negative kind and by original training/validation/test membership.
- Capture/preparation failures, separate from a model rejecting a valid attempt.
- Word inference-call counts, predictions/confidence, and failure explanations.

Rates with no supporting positive or negative samples are **null**, not perfect
scores. Each negative exposure is a trial/target pair, not an independent new
recording. A capture failure that prevents completion does not demonstrate
unknown-motion rejection. No idle trials means no evidence about idle rejection.
Training-set replays do not establish held-out recognition. The report remains
`offline_rules_replay`, `hardware_validation=Not run`, and
`final_accuracy_claim_ready=false`; phone latency is unset.

## Collection checklist for the repaired glove

1. Record hardware/mounting, firmware/app/model revisions, phone/OS, and the
   reviewed calibration profile. Verify battery-only startup and a stable stream.
2. Freeze selected demo targets and the main wearer. Capture repeated independent
   correct attempts across sessions/re-donning, not many frames from one hold.
3. Capture confusable wrong signs, idle movement, unrelated motion, and incomplete
   attempts. Review labels and preserve failures. Do not fill broken channels.
4. Export before changing calibration/vocabulary/session. Retain source manifests,
   timestamps, and profile snapshots; check packet quality before training.
5. Keep development and fresh final-rehearsal attempts separate. Freeze models
   and thresholds before evaluating the final set. Report the personalized scope.
6. Run static and word evaluation plans and inspect failures, negative coverage,
   and split membership. Then rehearse on the actual phone/glove and measure
   latency, disconnect recovery, and saved completion.

J/Z motion trials can be collected separately for future model development;
they are not recognized by the current static MLP or three-word practice model.

## Verification limits

November 6 software verification: firmware build and serial-startup host checks
passed; 63 Flutter unit/widget tests passed, with the command-only replay test
skipped in the normal suite and exercised separately through the CLI. Targeted
Dart analysis passed. Backend checks covered 60 distinct tests (the 58-test
suite followed by the expanded nine-test evaluator module, adding two cases).
End-to-end command checks passed for original static telemetry, the retained
recorded MLP bundle, and the bundled TCN. Dependency deprecation warnings remain
non-failing. Local outputs under `tmp/demo-replay-check-20261106/` are diagnostic
artifacts and are not committed as new recognition evidence.

The startup host test and firmware compilation passed. Synthetic rule tests
exercise known holds, wrong-target/idle false completions, broken streams, and
CSV-versus-packet preparation mismatch. Historical end-to-end command checks
exercise original static packets and the bundled TCN; they are development
replays containing previously used recordings, not new independent accuracy
experiments. The candidate MLP path is checked separately with its retained
model bundle. Physical standalone boot, new calibrated-glove recognition,
unknown-motion rejection, and intended-phone latency remain **Not run**.
