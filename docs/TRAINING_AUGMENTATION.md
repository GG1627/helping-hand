# Training augmentation for measured glove variation

Implemented November 6, 2026. Both the recorded static MLP trainer and the word
sequence trainer accept `--augmentation-config`. It is **disabled by default**.
This adds candidate training tools; it does not replace the deployed MLP/TCN,
change runtime preprocessing, or establish a recognition improvement.
For the overall stopping point and ordered return-to-hardware checklist, read
[the glove/model handoff](GLOVE_MODEL_SESSION_HANDOFF.md).

## What the generator does

`backend/training_augmentation.py` creates bounded perturbations of original
**training trials only**, after whole-trial splitting and scaler fitting. The
original recordings remain the evidence. Generated descendants retain their
parent trial identity and label; they do not count as independent trials.

For each requested copy and feature, the generator adds:

- One uniformly sampled offset, constant across that trial.
- Uniformly sampled noise at each observed time step.

Each term is bounded independently by its configured absolute limit. Their
maximum combined deviation is the sum of those limits, plus float32 rounding.
There is no estimated covariance or physical sensor model. Seeds depend on
the configured seed, parent identity, and copy index, so parent order does not
change its generated values. Feature order is recorded separately in the manifest.

The static trainer perturbs raw flex ADC readings before applying its existing
firmware-matched calibration and original training scaler. Calibration can
still clamp values at its measured endpoints; augmentation cannot repair a
wrong or excessively narrow calibration range.

The word trainer perturbs raw features after resampling/window selection and
before the original training scaler. Existing edge padding is removed, observed
samples are perturbed, and the new endpoints are padded again. This avoids
inventing motion in the padded tails. It supports the selected 11- or 14-feature
layout, with names from that layout; magnetic channels require actual recorded
magnetic data. These operations do not synthesize missing channels, letters,
words, trajectories, head/chest position, or wrist rotations. They do not change
sign duration or recover motion already removed by a short window.

Invalid/nonfinite inputs and flex values outside the 12-bit ADC range fail the
run. The generator does not silently clip raw ADC values or repair recordings.
Validation and test inputs remain original recordings, and neither set is used
to fit the scaler or produce descendants.

## Configuration and measurement

Start from [the disabled configuration](examples/training_augmentation.disabled.json).
Its fields are:

| Field | Meaning |
| --- | --- |
| `schema_version` | `training-augmentation-v1` |
| `copies_per_trial` | Integer 0–8; zero disables augmentation |
| `seed` | Unsigned 32-bit integer |
| `noise_bounds` | Feature name to maximum absolute per-sample noise |
| `offset_bounds` | Feature name to maximum absolute constant trial offset |
| `measurement_reference` | Reference to captures/analysis supporting the limits |

Bounds use each recorded column's native units: ADC counts for `flex_*_raw`,
the CSV acceleration/angular-rate units for `ax`…`gz`, and microteslas for
`mx_ut,my_ut,mz_ut`. Omitted features get zero perturbation. Limits must be
finite and nonnegative; enabled configurations require a nonzero limit and
a nonblank measurement reference. Unknown configuration fields are rejected;
enabled limits naming a feature outside the model layout also fail.

The measurement reference is an operator declaration, not automated verification
that the limits are physically correct. No recommended numeric limits are
provided before we measure the repaired glove. To determine them:

1. Capture developer calibration evidence and inspect flex ranges, saturation,
   IMU bias/noise, and magnetic status with the final wiring and mount.
2. Collect repeated still poses and target signs from the main wearer, including
   separate sessions/re-donning. Distinguish sensor noise from intentional motion
   and meaningful pose differences. A straight/bent flex range alone cannot
   supply this information.
3. Use training/development captures to justify conservative per-feature noise
   and offset bounds. Keep evaluation recordings reserved. Document exclusions,
   capture IDs, units, and the analysis in the measurement reference.
4. Compare disabled and enabled candidates on the same original validation set.
   Use small copy counts first. Retain augmentation only if it helps the intended
   main-wearer demo without worsening rejection, selected signs, or latency.

## Training and comparisons

For both trainers, omitting `--augmentation-config` preserves the unaugmented
training path. Every parent and its copies share a total weight equal to that
parent's original weight. Static class-priority and within-class trial weighting
are retained. For the sequence trainer, the original trial and each of its copies
receive `1 / (copies_per_trial + 1)` sample weight.

This preserves relative parent contributions, not identical optimization: more
examples create more batches, and Keras batch-mean loss scaling changes. Training
losses across copy counts are not directly comparable. Compare original validation
loss/results, record epochs and batch size, and avoid selecting on test results.

Use a new output directory for every run. Add `--defer-test` to candidate tuning
runs for **both** trainers. It omits test inference/reporting while retaining
the reserved test assignments. The test set still has to exist. Freeze baseline
assignments and use them for the augmented comparison:

```powershell
# Add these arguments to the otherwise identical word training command:
--split-manifest path/to/word-baseline/split_manifest.json --augmentation-config path/to/measured-augmentation.json --defer-test

# Add these arguments to the otherwise identical static training command:
--split-manifest path/to/static-baseline/split_manifest.json --augmentation-config path/to/measured-flex-augmentation.json --defer-test
```

Keep vocabulary, feature/window layout, source recordings, calibration, model
architecture, training seed, and hyperparameters fixed for the initial comparison.
The static frozen split validates exact trial coverage and source CSV hashes.
Check recorded source hashes for word comparisons as well. After selecting the
candidate using validation data, evaluate the reserved test once under the
documented protocol. The existing word evaluation command can evaluate the
saved selected bundle. The static trainer can rerun the frozen selected
configuration without `--defer-test`; this retrains it and must not become
another opportunity to select a better-looking test result.

Static source CSVs now require an origin manifest, matching the word pipeline's
real/fixture distinction. Standard names pair `trials.csv` with `manifest.json`
and `trials_2.csv` with `manifest_2.json`. For custom locations use `--manifests`
with one path per CSV. Real and fixture sources cannot be mixed. Fixtures require
`--allow-synthetic-smoke`, keep `accuracy_reporting_allowed=false`, and cannot be
exported as firmware headers.

Each candidate writes `augmentation_manifest.json`. Enabled manifests include
parent/copy identities, labels, origin, deterministic seed digests, canonical
float32 matrix hashes, padding, and weight multipliers. Model metadata records
the configuration and both original and expanded training counts. Source hashes,
splits, scaler statistics, and evaluation counts remain separate. Generated
training descendants are labeled `augmented_training`; they are never written
back into exported recording CSVs.

## Verification and remaining work

November 6 final backend suite: **82 passed**; dependency deprecation warnings
were non-failing. Documentation reference checks and `git diff --check` passed.

Automated checks cover determinism, bounds, input immutability, training-only
parents, padding, ADC failures, feature validation, configuration parsing, and
parent weight conservation. Local one-epoch synthetic-fixture smoke runs cover
both trainers, TFLite conversion, baseline/augmented split and scaler equality,
and deferred test reporting. Fixture metrics are not recognition evidence.

Physical calibration, measured augmentation limits, real-data comparisons,
fresh glove/phone demo success, and target-runtime latency are **Not run** for
this change. Once hardware is ready, those tasks take priority over generating
more descendants from the existing small dataset. See also
[developer calibration](DEVELOPER_CALIBRATION.md),
[sequence preparation](SEQUENCE_PREPROCESSING.md), and
[demo evaluation](DEMO_READINESS_TOOLS.md).
