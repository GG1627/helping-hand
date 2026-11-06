# Configurable sequence preparation

Implemented November 5, 2026. This prepares candidate training/deployment paths;
the packaged Hello/Please/Yes model, metadata, vocabulary, completion rules,
static MLP, and calibration behavior remain unchanged.

## Supported experiments

`sequence-preprocessing-v1` freezes four choices in every new model bundle:

| Setting | Options |
| --- | --- |
| `window_samples` | 4–400 samples |
| `target_rate_hz` | 25–50 Hz, default 40 |
| `feature_set` | `flex_imu6` (11 raw values) or `flex_imu9` (14 raw values) |
| `window_policy` | `center_trim_edge_pad` or `reject_overlength_edge_pad` |

Both paths resample on device timestamps with linear interpolation, then use
training-only per-feature standardization. No quaternion fusion, gyro correction,
flex calibration, or synthetic training augmentation is added by these settings.

The original policy center-trims long resampled attempts and edge-pads short
ones. The strict policy **refuses a resampled attempt longer than the window**;
it edge-pads shorter ones. It does not skip the trial and continue training.
Choose a sufficiently long window and investigate oversized attempts, instead
of discarding difficult examples merely to improve a score.

The 14-value layout appends `mx_ut,my_ut,mz_ut` to the existing five-flex,
three-acceleration, three-gyro order. Every valid source sample must have a
complete, finite magnetic vector with status `ok`. Missing magnetic values
cause preparation to fail; no zeros, stale readings, or invented channels are
substituted. A real measured zero remains valid. Legacy six-axis recordings
continue to use the 11-value layout.

The runtime preparation limit remains approximately ten seconds; normal learner
attempt capture retains its existing eight-second timeout. Experimental windows
do not extend that timeout. A fixed-rate resampling grid may not land exactly
on the final raw timestamp; “no trim” here means retaining the resampled sequence,
not reconstructing information beyond the recording rate.

## Preview without training

From the repository root:

```powershell
python backend/prepare_word_sequences.py path/to/trials.csv --window-samples 96 --window-policy center_trim_edge_pad --report-json baseline-preview.json
python backend/prepare_word_sequences.py path/to/trials.csv --window-samples 224 --window-policy reject_overlength_edge_pad --report-json long-preview.json
```

Use `--manifest path/to/manifest.json` if the manifest does not have its standard
neighboring filename. Add `--feature-set flex_imu9` only for new real magnetic
recordings. Preview failures return nonzero and appear per trial in the report;
CSV validity alone is not preparation success. Window previews are not accuracy
evaluations and do not fit a model.

The historical word-recording comparison is retained in
[window coverage evidence](evidence/word_window_coverage_2026-11-05.json):

| Candidate at 40 Hz | Trials trimmed | Samples trimmed | Edge-padding samples |
| --- | ---: | ---: | ---: |
| 96, center trim | 7/15 | 400 | 70 |
| 224, reject overlength | 0/15 | 0 | 1,590 |

The 224-sample candidate covers the historical maximum of 212 resampled points.
The extra padding and computation can hurt recognition or latency; no trained
224-sample improvement has been established. A longer input does not by itself
change the TCN's convolutional receptive field. Compare against the baseline
and consider activity-boundary handling later as a separate experiment.

The evidence includes both the working CSV hash and LF-normalized hash. Git's
CRLF conversion changes file bytes; normalization matches the historical source
hash. The coverage check did not edit the recording or model artifacts.

## Training and evaluating candidates

Reuse one whole-trial split manifest across window/feature comparisons:

```powershell
python backend/train_word_models.py path/to/trials.csv --vocabulary path/to/words-v1.txt --data-version wearer-v2 --split-manifest path/to/frozen-split.json --output-directory backend/models/word_runs/wearer-v2-long --architectures tcn --window-samples 224 --feature-set flex_imu6 --window-policy reject_overlength_edge_pad --defer-test
```

Use a new output directory for every run. Generate the initial split once if
needed, then reuse it; do not search seeds for favorable test results. Compare
validation lesson behavior, false completions, size, and intended-phone latency.
Reserve new independent real attempts for final evaluation. Historical evaluated
trials are regression/development evidence after further tuning.

The training bundle records `preprocessing`, feature order, scaler, dimensions,
and trim/pad coverage. The evaluator reads the bundle's configuration rather
than silently reverting to the legacy window/feature layout. Legacy bundles
without the new field retain the center-trim, 11-feature interpretation; their
declared window and rate are still validated. Conflicting shape/rate/order is
rejected. Feature sets must match the scaler and model input tensor.

## Flutter and deployment boundary

Flutter retains optional magnetic vectors alongside the original eleven frame
values. Its preparer selects inputs from validated bundle metadata, implements
both window policies, and checks missing/nonfinite features. TFLite input shape
checks now use the metadata feature count and window length. Vocabulary remains
the currently integrated three words; this change does not add J/Z recognition.

The existing bundled model continues to receive its original 96 × 11 tensor.
Do not change that bundle's window number to 224: the weights expect the old
shape. Retrain, export, review model/scaler/preprocessing metadata together, and
test on the intended phone before installing a new bundle. No new trained model
is automatically packaged by this change. Oversized or missing-feature attempts
fail preparation and cannot award completion.

## Verification

November 5 checks passed: 61 Flutter unit/widget tests, targeted Flutter
analysis, 49 backend regression tests plus two new candidate-shape TFLite
checks, and the Android debug APK build. TensorFlow conversion emitted dependency
deprecation warnings. The packaged TCN SHA-256 remains
`7664ceacd04b488fc896b04210490e4c0908d852050ad22ed4dc2b80fe561a8a`.

Software checks retain real-recording legacy Python/Dart parity and add a shared
synthetic fixture for center trimming, a complete longer window, and irregular
14-feature interpolation with odd edge padding. The fixture is marked
`accuracy_reporting_allowed=false`. Regenerate it with:

```powershell
python backend/export_preprocessing_fixtures.py
```

The Python test checks fixture freshness; Flutter compares every prepared float32
value with the stored Python output. Backend tests cover absent magnetic data,
invalid configurations, mismatched metadata, and rejected windows. Additional
untrained TCN smoke checks verify 224 × 11 and 224 × 14 built-in TFLite conversion
and invocation. These establish software compatibility, not model accuracy.

Fresh training, physical 14-feature capture, live candidate inference, phone
latency comparisons, and recognition improvements remain **Not run**.
