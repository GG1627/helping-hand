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

Flex sensors capture finger bending; IMU readings capture motion/orientation. ESP32 samples and sends BLE packets to Flutter. The app processes readings and displays practice feedback. Tactile feedback is a future addition. Current hardware photo slots are placeholders.


## 4. What alpha established

Speaker: TBD · 25 seconds

Alpha established the sensor-to-app vertical slice and static TFLite baseline. These are supplied historical alpha materials, not fresh beta validation. The previous deck's 78%/94% figures are omitted because evaluation context has not been supplied. Preserve the static model as a regression baseline while adding words.


## 5. What beta adds

Speaker: TBD · 40 seconds

Show sign-in, learning paths, target selection, and dedicated practice routes. Firebase accounts own static progress. Words opens beginner vocabulary pages. The supplied practice screen is disconnected, not a successful recognition result. These screens do not establish dynamic recognition validation or word completion.


## 6. Recognizing motion

Speaker: TBD · 35 seconds

Alpha's MLP classifies a sensor snapshot. For beta words, use a time window: a 1D CNN extracts local patterns; a GRU carries information across time; dense/softmax layers predict word probabilities. The diagram summarizes a candidate, omitting normalization, dropout, and intermediate implementation details for clarity. Research recommends CNN-GRU first, comparing CNN-LSTM. Current backend builders support both and a TCN candidate; this does not establish a selected trained/deployed model. Hello and 3–4 words remain provisional demo scope. Traces/output are illustrative, with no measured accuracy claimed. REQUIRED FOLLOW-UP: update this slide after training/model selection and integration to match the actual architecture, vocabulary, preprocessing, and measured device performance. See CONTENT_REVIEW.md.


## 7. Live demo

Speaker/demo operator: TBD · 90 seconds

Use the actual glove/app live, as confirmed with instructors. Demonstrate a rehearsed static target, then Hello and the actual available feedback. Set up login and connection in advance. If recognition fails, explain what happened and demonstrate remaining live functions. Do not substitute video for live use.


## 8. Current state and limitations

Speaker: TBD · 25 seconds

Separate implemented static software, sequence-model development, and planned haptics. Static progress requires the correct target label, confidence at least 80%, a stable hold of at least 750 ms, at least five matching packets, and packet gaps no greater than 250 ms. These are implementation thresholds from StablePredictionTracker, not measured accuracy or latency. They do not apply to dynamic words. Current physical-device route/BLE, Firebase end-to-end, and external-user beta procedures remain Not run in the repository notes; update only with recorded evidence. Confirm the actual dynamic demo build before presenting.


## 9. Next: haptic feedback

Speaker: TBD · 35 seconds

Plan five piezo elements in an X pattern and one per finger, ten total as understood. Goal: indicate incorrect positioning and degree of deviation. Confidence alone is not a positional error estimate; establish a calibrated deviation measure and feedback mapping. Validate tactile response and drivers. Artwork is conceptual, not an exact mounting schematic. Dates are proposed and require team review; the final deadline is unknown. Explain mount/wire → calibrate → recognition variation trials → user tests/polish.


## 10. Questions

All speakers available · 10-second closing + 1–2 minutes Q&A

Connect the current wearable/app experience with corrective tactile guidance. Answer using actual implementation/evidence. Prepare for questions on vocabulary, training data, orientation, BLE, progress, and haptic calibration.

## Required content follow-up

Slide 6 must be updated after the actual word model is trained, selected, and integrated. Follow the checklist in `CONTENT_REVIEW.md`; update architecture, vocabulary, preprocessing, measured performance, status, and PDF consistently.

Review the proposed milestone dates and assign all four team members a speaking/demo role. Rehearse with the actual glove wearer.
