# Helping Hand post-mortem presentation plan

Prepared November 6, 2026 after reviewing the beta presentation. This is a
working approach, not the finished deck or a claim that final testing is complete.
The [P3 assignment](../P3-Post-Mortem-Presentation.md) governs requirements.

## Starting point

The October beta deck told this story: learning problem -> glove/app pipeline
-> alpha foundation -> beta learner experience -> word model -> live demo
-> current limitations -> haptic roadmap -> questions.

The post-mortem should answer: **What did we build, what can we demonstrate,
what worked well, and what would we change about how we developed it?**
Use the final artifact as the thread connecting those answers. Give the
required three successes and three challenges enough speaking time to explain
causes and lessons, rather than placing six unexplained bullets at the end.

## What to carry forward from beta

| Beta material | Post-mortem use |
| --- | --- |
| [HTML deck](../beta_presentation/index.html), local assets, keyboard controls, 16:9 PDF workflow | Reuse the presentation structure in a separate `post_mortem_presentation/` folder when building the new deck. Preserve the beta deck as its historical submission. |
| [App-matched style](BETA_PRESENTATION_STYLE_GUIDE.md) | Keep ivory, teal, mint, DM Sans, restrained Fraunces branding, spacious composition, and short visual explanations. Adapt content to P3 rather than copying beta-specific requirements. |
| Problem and sensor-to-app pipeline | Compress the introduction; one clear need and one system diagram are enough. |
| Glove photos and app screenshots | Replace with final-assembly photos and current screenshots where available. Label retained October images by date/stage. Prefer the actual final glove for the main product image. |
| Static-versus-sequence model explanation | Keep the conceptual distinction. Put detailed architecture, preprocessing, and evaluation tables in backup material. |
| Dedicated live-demo slide and [demo checklist](../beta_presentation/demo_checklist.md) | Keep a clear transition into live use and prepare the account, BLE connection, wearer, phone projection, and selected targets beforehand. |
| Alpha history and beta feature tour | Fold into final-state evidence and success stories instead of repeating both milestone sections. |
| Haptic roadmap and proposed dates | Replace with the actual final haptic state and a lesson from the work. Describe unfinished work plainly. |

## Proposed running order

P3 specifies **7 minutes with questions throughout**. The beta deck's separately
agreed 5-6 minute presentation plus Q&A does not carry over to this assignment.
Aim for **6 minutes 10 seconds of prepared content**, leaving approximately
50 seconds for interruptions and transitions within seven minutes. This is a
planning target, not a separate Q&A period; rehearse and adjust after the demo
duration and speakers are known.

| Slide | Purpose | Target |
| --- | --- | --- |
| 1. Helping Hand: the need | Introduce the team and explain the ASL practice-feedback need in one sentence. | 20 s |
| 2. What we built | Show final glove -> ESP32 -> BLE -> Flutter -> practice feedback/progress. Distinguish where static and word inference run. | 30 s |
| 3. Final project state | Cover major features and modes, hardware/assets, performance evidence, and remaining limitations. | 40 s |
| 4. From poses to words | Explain the static MLP and complete-attempt TCN; state the deployed vocabulary and evaluation scope. | 35 s |
| 5. Live learner scenario | Perform a rehearsed static target and one word, show actual feedback and saved completion; add a second word only if rehearsal supports the time. | 80 s |
| 6. Three successes | Explain three challenge -> approach -> outcome stories, about 25 seconds each. | 75 s |
| 7. Three challenges and lessons | Explain three difficulty -> impact -> future change stories, about 25 seconds each. | 75 s |
| 8. Final takeaway | State the delivered capability, its main limit, and the strongest engineering lesson. | 15 s |
| **Prepared content** | | **370 s / 6:10** |

Use concise visual labels on slides 6 and 7; put the explanation in speaker
notes. If six stories do not fit intelligibly, simplify the earlier technical
explanation and expand the reflection time. Eight slides is a proposal, not an
assignment requirement. Assign speaking/demo roles after the content is settled.

## Candidate success stories

These are supported starting points, not invented accounts of team process.
Confirm the team's explanation of why each approach worked before scripting it.

| Success | Challenge and approach to explain | Outcome and supporting evidence |
| --- | --- | --- |
| Connecting sensing to a learner experience | Getting sensor capture, BLE, recognition feedback, and progress to work together. Explain the shared packet contract and how the team checked each stage. | Historical physical glove-to-phone operation is documented. Later team observations report practiced signs and progress visible in the app and Firebase. Use [demo observations](R3_DEMO_OBSERVATIONS.md); confirm the final assembly separately. |
| Adding motion-based word practice | A static pose cannot represent the time evolution of a word. The team recorded complete attempts, compared TCN/CNN-GRU/CNN-LSTM, selected a small TCN, and integrated Start/Finish inference in Flutter. | Hello/Please/Yes are packaged; Hello and Please recognition/completion were reported during the October demo. The comparison used only 15 real attempts. Use [training](WORD_MODEL_DEMO_TRAINING.md), [integration](WORD_DEMO_INTEGRATION.md), and [physical observations](R3_DEMO_OBSERVATIONS.md). |
| Turning predictions into saved practice progress | A predicted label alone does not complete a learner workflow. Explain target selection, static stability checks, word-attempt matching, completion feedback, and account-scoped storage. | The learner flow is implemented; the team reported checking completion indicators and corresponding Firebase progress. This does not establish measured human learning or retention, restart recovery, or cross-device reliability. Use [release-candidate documentation](../RELEASE_CANDIDATE.md) and [demo observations](R3_DEMO_OBSERVATIONS.md). |

The first story should emphasize device/software integration; the third should
emphasize the learner interaction and persistence design so they remain distinct.
Replace one with a communication/versioning/task-distribution success if the team
has a specific, better-supported example. Explain the actual mechanism and result.

## Candidate challenges and future changes

| Challenge | What made it difficult / effect | Future change to discuss |
| --- | --- | --- |
| Sensor damage and changing calibration | Thumb/index sensor faults were reported, and replacement sensors/mounting can change input distributions. Historical model results cannot establish performance on the rebuilt glove. | Add regular raw-signal health checks, mounting/strain-relief checks, calibration records, and repeated attempts after re-donning. Collect and evaluate data on the actual final assembly before reporting improvement. |
| Limited data and motion coverage | The word dataset has 15 attempts and cannot establish robustness across wearers or wrist angles. The later audit found that the deployed window trims 7/15 historical attempts, including every Yes attempt. | Reserve fresh evaluation attempts; collect separate sessions, confusable signs, incomplete gestures, and unrelated motion. Compare justified window/model changes on frozen splits and measure false completions as well as correct ones. |
| Completing hardware/software integration | As of the current handoff, ten piezo outputs have firmware support, but circuit review, cue design, app/classifier triggering, and on-glove validation remain pending. PCB work is unfinished. Confirm the team's actual scheduling/dependency difficulties before explaining their causes. | Plan smaller end-to-end integration milestones, give each interface an owner and an observable acceptance check, and reserve time to test the assembled artifact. Present this as a proposed process improvement unless the team confirms it was used. |

Sources: [current glove/model handoff](GLOVE_MODEL_SESSION_HANDOFF.md),
[demo observations](R3_DEMO_OBSERVATIONS.md), and
[model optimization audit](DEMO_MODEL_OPTIMIZATION.md). If final work resolves
one of these issues, retain the historical difficulty and explain the actual
resolution rather than continuing to label it unfinished.

## Final-state and demo evidence to collect

The November 6 handoff is the current technical starting point. The October
beta deck is a presentation reference. Later retrospective observations add
historical physical-demo evidence; they do not validate the repaired assembly.

- Record the final hardware, firmware/app revisions, phone, model bundle, and
  calibration configuration; take final assembly photos and current screenshots.
- Confirm final feature/mode status, including sign practice, word practice,
  accounts/progress, recording/developer tools, and haptics. State what is
  integrated, what was physically tested, and what remains incomplete.
- Record fresh demo attempts and failures on the intended glove/phone. Choose
  reliable targets from those results. Preconfigure login and BLE, then show
  actual use rather than spending the demo on setup.
- Report measured performance with its scope: attempts per sign, failures/false
  completions, actual delivered packet rate, model size, and intended-phone
  latency where measured. Keep unexecuted measurements labeled **Not run**.
- Keep implementation thresholds separate from measured accuracy. The current
  recorded static model has 34 classes, excluding J/Z; the original 36-class
  baseline is preserved. The packaged word TCN covers Hello, Please, Yes.
- Do not promote the historical three-trial test result into general accuracy.
  Historical data reused during development is regression evidence; reserve
  fresh attempts for a final evaluation claim.
- Show tactile guidance live only if integrated and tested. Current firmware
  output support alone does not establish corrective haptic feedback.
- Prepare a short recovery path for live failures. Continue showing genuine
  available functionality, explain the failure, and keep the live-use requirement.
  Recordings/screenshots can support an explanation but do not fulfill that requirement.

## Next working session

1. Confirm the final presentation date, current assembly/haptic/PCB status, and
   any measurements or physical tests completed since November 6.
2. Ask each teammate for one concrete success and one challenge, including what
   happened, why, and what changed or should change. Select three of each.
3. Freeze the final learner demo scope after rehearsal; gather its evidence and
   update the final-state outline.
4. Draft slide copy and speaker notes against the timing table, then build the
   separate deck using the beta visual system and local presentation controls.
5. Rehearse with questions and the physical artifact. Export and inspect the PDF
   for Canvas after the deck is settled. Do not treat slide/PDF checks as device
   or model validation.
