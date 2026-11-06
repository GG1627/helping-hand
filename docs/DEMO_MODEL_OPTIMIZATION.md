# Main-wearer model optimization

Reviewed November 5, 2026. The user selected reliable demonstration for the main
glove wearer and selected signs as the primary goal. This is a personalized
prototype objective; it does not establish performance for new wearers.

## Audit findings

This review inspected the current training code, real recordings, frozen split
manifests, and saved training reports. It did not retrain or replace deployed
weights, modify acceptance thresholds, or execute a new accuracy evaluation.

### Static MLP

The deployed recorded model has 34 classes and five calibrated flex inputs. Its
52 selected trials contain 8,093 frames. Only A, B, 1, and 3 have validation/test
trials; the other 30 labels are training-only. The current trainer already gives
A/B/1/3 four times the class weight. These are the initial demo candidates with
the strongest existing recording coverage, not a newly confirmed final demo list.

Applying the deployed 425-bent/625-straight endpoints to the selected recordings
clips the following proportions outside the measured range:

| Selected recording source | Thumb | Index | Middle | Ring | Pinky |
| --- | ---: | ---: | ---: | ---: | ---: |
| September `trials.csv`: 31 trials, 4,830 frames | 64.1% | 76.7% | 60.5% | 69.7% | 73.2% |
| October `trials_2.csv`: 21 trials, 3,263 frames | 22.7% | 22.7% | 51.5% | 69.2% | 76.8% |

These are descriptive clipping rates across each selected source, not sensor
failure rates or a diagnosis of the repaired glove. Values outside measured
endpoints map to identical extremes, potentially discarding distinctions. Do
not infer replacement-sensor calibration from these historical files.

The saved training confusion matrix includes E→A (152 frames), W→6 (84),
O→0 (72), X→C (59), and C→X (58). These are correlated training-frame counts,
not independent test failures. Letter/number category filtering already exists
in the app and helps with cross-category candidates, but cannot resolve every
within-letter distinction. Five bend sensors may also miss distinguishing
orientation, finger spread, or contact information.

### Word TCN

The deployed model uses 96 samples at 40 Hz and 11 features. The 15 real trials
cover Hello, Please, and Yes, five trials each, from the reported demo wearer at
neutral orientation. The split has 9 training, 3 validation, and 3 test trials.

| Word | Resampled sample counts | Samples discarded by current center trim |
| --- | --- | --- |
| Hello | 90, 80, 84, 74, 88 | 0, 0, 0, 0, 0 |
| Please | 95, 92, 128, 95, 100 | 0, 0, 32, 0, 4 |
| Yes | 212, 201, 158, 133, 140 | 116, 105, 62, 37, 44 |

Seven of fifteen trials are trimmed. Every Yes trial loses roughly 28–55% of
its resampled observations. This establishes truncation, not that all discarded
samples contain useful sign motion or that a longer window improves accuracy.
Dropout and L2 already exist. The model has no rest/other class. An 80% softmax
score alone does not establish rejection of unrelated motion.

## Optimization order

1. Freeze the main wearer, final demo vocabulary, calibrated glove configuration,
   and collection procedure. Begin with the current three words and selected
   static targets; obtain real sequence examples before adding J/Z.
2. Measure per-finger calibration after repair and attach calibration/session
   versions to recordings. Preserve the historical models and their endpoints.
   Compare raw and calibrated distributions before pooling sessions.
3. Compare TCN preprocessing on the same frozen development split: current
   96-sample center trim versus a longer window (224 samples covers these saved
   attempts). Also consider activity-boundary selection or whole-attempt time
   normalization as separate experiments. Update Python and Flutter together
   for any selected preprocessing change. Measure padding, motion retention,
   artifact size, and actual phone latency.
4. Collect independent correct attempts, wrong trained signs, idle motion,
   unrelated motion, and incomplete attempts. Keep explicit Start/Finish
   boundaries for the demo. Fit rejection or an other class using development
   data and report both false completion and successful completion.
5. Use conservative training-only augmentation after collecting repeated real
   attempts. Estimate noise/offsets from training captures, preserve cross-axis
   and temporal relationships, and compare real-only against augmented training.
   Do not count generated descendants as independent recordings.
6. Tune a small, declared set of capacities and regularization settings on
   validation data. MLP priorities can be weighted explicitly, with per-sign
   results documenting tradeoffs. Retain TCN as the sequence baseline until
   another candidate demonstrates a useful advantage. Do not pick split seeds
   or acceptance thresholds to improve the displayed score.
7. Select on actual lesson completion, false completion, repeatability, model
   size, and intended-phone latency. Evaluate the selected candidate on fresh
   whole attempts collected separately from development. Historical evaluated
   recordings remain regression/development evidence after further tuning.

The new magnetic recording path enables future 11-feature versus 14-feature or
derived-orientation experiments. Existing recordings have no magnetic channels;
do not invent them. Magnetic calibration and axis alignment precede a claim of
usable orientation. Preserve palm orientation meaningful to the target signs.

## Current boundary

The previous firmware/app recording update is committed and pushed as
`ea38c33`; its Android debug APK also built successfully. No physical Android
device or serial port was connected during the November 5 installation check.
Flashing/installing and live validation remain pending.

This audit identifies concrete development priorities. No accuracy gain,
unknown-motion rejection, post-repair recognition result, or learning benefit
has been established by it. Final calibration, new recordings, final static
demo targets, and measured performance still require the team's input.

## Source records

- [Recorded static model](STATIC_MLP_DEMO_MODEL.md)
- [Recorded word comparison](WORD_MODEL_DEMO_TRAINING.md)
- [Word preprocessing and app integration](WORD_DEMO_INTEGRATION.md)
- [Earlier TCN review](R3_TCN_IMPROVEMENT_REVIEW.md)
- [Magnetic recording extension](MAGNETOMETER_RECORDING.md)
- Local retained artifacts: `backend/models/static_runs/recorded-priority-v5-all425-625/`
  and `backend/models/word_runs/demo-real-v1/` (ignored model-run backups).
