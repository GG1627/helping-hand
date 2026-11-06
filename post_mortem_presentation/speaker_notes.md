# Speaker notes · post-mortem draft 01

November 19, 2026. Prepared November 6. Main content: 6:10 including 90-second live demo; allow questions within seven minutes. Speakers and demo assignments remain TBD.

Notes mirror the inline HTML templates. Update both when editing the narration. Notes opened in the deck appear on the projected screen; rehearse from this file on a separate device.

## 1. Helping Hand: the need

Speaker: TBD · 25 seconds.

We built Helping Hand to connect a learner's own signing attempt to feedback. Books and ordinary prerecorded references show a sign, but do not measure that learner's hand. Our glove and app aim to make practice more responsive. Introduce the team and transition to the system.

Draft: the photo shows the October beta glove, not the final PCB assembly. Replace it when available. We have not measured human learning improvement.

## 2. From sensing to feedback

Speaker: TBD · 30 seconds.

Flex sensors capture bending; the IMU captures motion. The ESP32 reads them and performs current static recognition. BLE carries packets to Flutter, where complete word attempts run through a TCN and the app saves progress. The intended final loop adds haptic guidance.

Draft: the dashed line is a conceptual planned return path, not an implemented app-to-glove command claim. Update the diagram to the actual haptic trigger source and final architecture.

## 3. The final glove: draft layout

Speaker: TBD · 35 seconds.

Use this slide to explain the finished physical design once available: why the PCB matters, how the new IMU is mounted, and what the piezos communicate. Focus on two or three decisions and their actual outcomes. These October photographs reserve the layout; they do not show the final PCB or new IMU assembly.

Draft: replace photos, pending labels, and goals with the actual final construction and observed behavior. Receiving an IMU does not establish orientation-fusion benefits; piezo control alone does not establish useful tactile guidance.

## 4. What the learner can practice

Speaker: TBD · 35 seconds.

The learner chooses a target, practices, receives feedback, and saves completion. Our intended final coverage is A-Z, 0-9, and Hello, Thank You, Please, Sorry, Yes, No, Eat, Drink. A pose is a held configuration; a sequence includes how it changes over time.

Draft: only Hello/Please/Yes are currently trained. The recorded static model has 34 classes excluding J/Z. Update supported coverage, model explanation, results with scope, and current screenshots after development. The third image is a word picker, not evidence that a new word was completed. Do not describe 80% confidence as 80% measured accuracy.

## 5. Live learner demonstration

Wearer: TBD · Phone operator: TBD · Narrator: TBD · 90 seconds.

0-10 seconds: show the worn glove and prepared target. 10-40: attempt a rehearsed static sign, show actual feedback, adjust, and complete if supported. 40-70: perform a complete word and show the real prediction. 70-90: show saved completion; include a short extra target only if timing permits.

Draft: use the real final haptic meaning. If it only indicates success/error, explain that. Do not guarantee a successful recognition. If a step fails, describe the observed failure, try a short recovery, and continue showing available live use. Login, BLE connection, projection, and props should be prepared beforehand. The slide does not establish measured learning improvement.

## 6. Three successes: candidate stories

Speakers: TBD · 70 seconds, about 23 seconds per story.

Story 1: integration connects sensing to a useful practice response and saved progress. Historical team observations report signs completed and corresponding Firebase progress. Confirm which shared contract, test, or coordination decision made this work; do not invent a team-process explanation.

Story 2: static poses do not represent whole-word motion. The team recorded real attempts, compared TCN/CNN-GRU/CNN-LSTM, selected a small TCN, and integrated complete-attempt inference. Hello/Please completion was reported in October. Update with final eight-word outcomes if delivered.

Story 3 is a draft slot for the final wearable integration. Explain the actual PCB/haptic/IMU outcome and why the approach worked once finished. If another collaboration or technical story is stronger, replace it. No improved reliability or learning result is established merely by completing a feature.

## 7. Three challenges and lessons

Speakers: TBD · 70 seconds, about 23 seconds per story.

1. The team reported thumb/index flex faults. Explain the actual symptoms, impact, replacement/calibration response, and the earlier checks we would use next time. Do not infer that every historical recording was faulty.

2. Historical word data contain 15 attempts from the reported wearer. Timing and coverage matter: later audits found center trimming in 7/15 attempts. Explain one actual difficulty and the final response if it is evaluated; do not claim longer windows improved accuracy without results.

3. Supply a concrete PCB/IMU/haptic or software handoff example from the team. The difficulty and proposed smaller integration steps are reflection candidates, not a proven explanation of delays. A challenge can be discussed even if it is solved before November 19.

## 8. Final takeaway and questions

Speaker: TBD · 15 seconds.

Close with the strongest supported final capability, its main limitation, and the lesson that represents the semester. Proposed theme: the learner experiences the whole sensing-feedback loop, so integration must be tested as a whole. Leave this slide visible for questions.

Draft: add the actual final outcome and limit; do not imply all targets or corrective haptics are already validated. Questions occur throughout the seven minutes, not in a separate assumed allowance.

## Backup. Coverage: baseline and final targets

Backup only · not part of the prepared 6:10.

Use to explain the distinction between November 6 implementation and intended November 19 scope. Today all eight word pages exist, but only three words are trained. Update this table after final integration and evaluation. Do not present historical records as current repaired-glove evidence.

## Backup. Model and final measurement slots

Backup only · not part of the prepared 6:10.

The historical TCN input is 96 samples at 40 Hz with 11 raw features, device-clock resampling, center trim/edge pad, and training-only standardization. No deployed magnetic features or orientation fusion. Historical size is 48,324 bytes, with 15 real attempts and a 9/3/3 whole-trial split. Three test trials are not evidence of generalization. Do not use desktop/emulator latency as intended-phone latency.

Draft: fill final measurement slots only with recorded results and source links. An 80% confidence acceptance threshold is an implementation rule, not measured accuracy or a correctness probability calibration.
