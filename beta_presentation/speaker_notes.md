# Helping Hand beta presentation ? speaker notes

Presentation: October 6, 2026. Target: 5 minutes 30 seconds including the live demo; then 1?2 minutes Q&A. Speaker assignments remain TBD.

These notes mirror the slide notes panel. Notes opened in the deck appear on the projected screen; use this file on a separate device.

| Slide | Topic | Seconds | Speaker |
| --- | --- | --- | --- |
| 1 | Helping Hand | 15 | TBD |
| 2 | The learning problem | 25 | TBD |
| 3 | Our solution | 30 | TBD |
| 4 | What alpha established | 25 | TBD |
| 5 | What beta adds | 40 | TBD |
| 6 | Recognizing motion | 35 | TBD |
| 7 | Live demo | 90 | TBD |
| 8 | Current state and limitations | 25 | TBD |
| 9 | Next: haptic feedback | 35 | TBD |
| 10 | Questions | 10 | TBD |

## 1. Helping Hand

Speaker: TBD · 15 seconds

Introduce Helping Hand as a wearable-assisted ASL learning system. Name the four team members. The intro is a generated product visualization based on supplied references.


## 2. The learning problem

Speaker: TBD · 25 seconds

NIDCD reports that more than 90% of deaf children are born to hearing parents, citing Mitchell and Karchmer (2004). This motivates accessible opportunities for families to learn ASL; it does not measure ASL proficiency or prove the effectiveness of our glove. Books and ordinary prerecorded videos teach through observation but do not measure the learner's own hand position or provide personalized live correction by themselves. Helping Hand aims to add sensor-based feedback. Do not generalize this gap to every app or instructor. Source verified October 5, 2026; see sources.md.


## 3. Our solution

Speaker: TBD · 30 seconds

Flex sensors capture finger bending; IMU readings capture motion/orientation. ESP32 samples and sends BLE packets to Flutter. The app processes readings and displays practice feedback. Tactile feedback is a future addition. The left photo shows the current glove with its mounted electronics; the right shows the ESP32-S3 and connections on the perfboard.


## 4. What alpha established

Speaker: TBD · 25 seconds

Alpha established the sensor-to-app vertical slice and static TFLite baseline. These are supplied historical alpha materials, not fresh beta validation. The previous deck's 78%/94% figures are omitted because evaluation context has not been supplied. Preserve the static model as a regression baseline while adding words.


## 5. What beta adds

Speaker: TBD · 40 seconds

Show sign-in, learning paths, target selection, and dedicated practice routes. Account-scoped progress now includes static signs and completed word attempts. Hello, Please, and Yes use the integrated TCN with Start attempt and Finish sign controls. These supplied screenshots predate that integration. The static practice screen is disconnected and the images do not establish live recognition or cloud-sync validation.


## 6. Recognizing motion

Speaker: TBD · 35 seconds

The static MLP reads a single pose. Our TCN learns how a sign changes over time. Its convolutions look at increasingly spaced samples, so later blocks capture motion over wider intervals. Residual links preserve earlier features. We prepare a 96-sample window from five flex channels and six motion axes, then average the learned features and predict Hello, Please, or Yes. Flutter runs the model locally after Finish sign. The sensor traces are illustrative.

We compared TCN, CNN-GRU, and CNN-LSTM on the same whole-trial 9 training / 3 validation / 3 test split of 15 real recordings from the reported demo wearer. All three got 3/3 validation trials correct. TCN won the predefined smaller-export tie-break at 48,324 bytes, then got 3/3 reserved test trials correct with macro F1 1.00. This sample is too small to establish general accuracy or architecture superiority. Flutter runs the TFLite model locally after Finish sign. Three Android emulator recorded-replay checks passed. Fresh glove/phone validation and intended-phone latency are Not run. No orientation normalization or rest/unknown class is implemented.


## 7. Live demo

Speaker/demo operator: TBD · 90 seconds

Use the actual glove/app live, as confirmed with instructors. Demonstrate a rehearsed static target, then two rehearsed words chosen from Hello, Please, and Yes. The recorded wearer signs while a teammate taps Start attempt and Finish sign. Show the actual predicted word and confidence. Matching the target at at least 80% confidence saves completion. Set up login and connection in advance. Fresh rehearsal and the two final word choices remain pending. If recognition fails, explain what happened and demonstrate remaining live functions. Do not substitute video for live use.


## 8. Current state and limitations

Speaker: TBD · 25 seconds

Static and three-word recognition are implemented. The recorded static demo model has 34 labels, prioritizing A, B, 1, and 3, while the original 36-class baseline is retained. The TCN recognizes Hello, Please, and Yes from explicit Start attempt / Finish sign sequences. Android recorded replay passed, but fresh glove/phone rehearsal, intended-phone latency, and live cloud synchronization of word progress are Not run.

Static completion requires the correct target label, confidence at least 80%, a stable hold of at least 750 ms, at least five matching packets, and gaps no greater than 250 ms. Word completion instead checks the predicted word and 80% confidence after Finish sign. These thresholds are acceptance rules, not measured accuracy. Rest/unknown rejection and robustness to other wearers or wrist angles remain development needs. Haptic guidance remains planned.


## 9. Next: haptic feedback

Speaker: TBD · 35 seconds

Plan five piezo elements in an X pattern and one per finger, ten total as understood. Goal: indicate incorrect positioning and degree of deviation. Confidence alone is not a positional error estimate; establish a calibrated deviation measure and feedback mapping. Validate tactile response and drivers. Artwork is conceptual, not an exact mounting schematic. Dates are proposed and require team review; the final deadline is unknown. Explain mount/wire → calibrate → recognition variation trials → user tests/polish.


## 10. Questions

All speakers available · 10-second closing + 1–2 minutes Q&A

Connect the current wearable/app experience with corrective tactile guidance. Answer using actual implementation/evidence. Prepare for questions on vocabulary, training data, orientation, BLE, progress, and haptic calibration.

## Required content follow-up

Slide 6 now shows the selected, integrated TCN. The deck and PDF include actual input preparation, deployment, model size, and the small trial-split result. Intended-phone latency and fresh glove rehearsal remain Not run. See `CONTENT_REVIEW.md`.

Review the proposed milestone dates and assign all four team members a speaking/demo role. Rehearse with the actual glove wearer.
