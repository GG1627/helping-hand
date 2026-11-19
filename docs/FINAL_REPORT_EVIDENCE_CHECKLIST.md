# R4 Final Report: Evidence Checklist and Working Log

Started November 17, 2026. This is a collection tool for building and testing,
not the report itself. Gael maintains the report in Word; provide report prose
in chat when requested. Do not create a report document or PDF, commit, or push
without explicit instruction.

## How to use this file

1. Before a build/test session, select the relevant unchecked items below.
2. Copy a session record from the bottom, give it an ID, and record the setup,
   procedure, expected behavior, and actual outcome while doing the work.
3. Link raw recordings, photos, screenshots, logs, model bundles, or existing
   records. Keep originals; describe what each file demonstrates.
4. Add the record ID beside its checklist item. Check an item when its evidence
   is documented, even if the outcome was a failure or an unfinished feature.
5. Record fixes and retests separately. Never replace the original failure with
   the later result. A checkbox means evidence collected, not feature passed.

Use **Not run** only for procedures known not to have been performed. Use
**Not yet documented** when results may exist elsewhere but have not been
provided here. No new hardware or model validation is established by this file.

Start with sections 1-6 during assembly and testing. Sections 7-10 help turn the
evidence into the report. Optional experiments are useful if feasible; missing
tests should be disclosed rather than replaced by invented results.

## 1. Final build and completion timeline

- [ ] **BUILD-1:** Record the actual final hardware: PCB revision, ESP32, IMU,
  flex sensors, actuator parts/driver, mounting, wiring, and power arrangement.
  [BUILD-01](#build-01-pcb-and-glove-assembly-history) covers the wired assembly
  and planned laptop USB power.
- [ ] **BUILD-2:** Record firmware/app revisions, any uncommitted changes,
  phone/OS, model filenames/hashes, labels, calibration, and preprocessing.
- [ ] **BUILD-3:** Take clear final photos of the whole glove, PCB, sensor
  attachment/insulation, IMU mounting, and ten actuator positions. Label photos
  as actual assembly or proposed placement as appropriate.
  [BUILD-01](#build-01-pcb-and-glove-assembly-history) links the final glove and
  both sides of the abandoned PCB. The IMU mount and detailed wiring are still
  to be documented.
- [ ] **BUILD-4:** Record actual dates of major interface, hardware, firmware,
  model, and integration changes. Preserve earlier planned dates separately.
- [ ] **BUILD-5:** Explain strategies used to finish the work: division of work,
  staged integration, parallel hardware/software preparation, troubleshooting,
  scope decisions, and dependencies. Include specific examples that happened.
- [ ] **BUILD-6:** Complete the feature inventory below, including unfinished
  goals and their effect on the final system.

| Feature / goal | Actual final state | Completed date, if applicable | Evidence / record ID | Remaining limit and effect |
| --- | --- | --- | --- | --- |
| PCB fabrication, assembly, and glove integration | Team fabricated a PCB and tried it in the glove. The current glove uses perfboard and discrete wiring. | Exact dates not yet documented | BUILD-01 | The PCB and conductive-thread builds were abandoned after unreliable connections. Photos are on file, and the as-built wiring diagram is still to be documented. |
| Five working flex sensors and calibration | Not yet documented | | | |
| New ICM-20948 integration and calibration | Not yet documented | | | |
| A-Z recognition, including moving J/Z | ESP32 static MLP supports 24 letters, excluding J and Z. Operator reported at least 10 live successes each for G and I. | Nov. 18 rehearsal | LIVE-01, LIVE-03 | Full per-letter live validation is not yet documented. |
| 0-9 recognition | ESP32 static MLP supports ten digits. Operator reported at least 10 live successes for 1. | Nov. 18 rehearsal | LIVE-01, LIVE-03 | Full per-digit live validation is not yet documented. |
| All eight app words | App lists eight words. The deployed TCN recognizes Hello, Please, and Yes. The operator reported at least 10 live successes each for those words. | Nov. 18 rehearsal | EVAL-04, LIVE-02, LIVE-03 | Five lessons are outside the deployed model vocabulary. Exact attempt totals and per-trial records are not yet documented. |
| Ten actuator outputs | Operator heard all ten during serial testing. In the app's manual Piezo Outputs screen, the operator reported that the physical buzzers matched the highlighted dots. | Nov. 18 report | HAPT-01 | Tactile sensation was very faint in the serial check. The phone test has no per-output tally or interruption results on file. |
| Automatic finger bend/straighten guidance | Visual estimates exist in letter practice. Automatic physical correction is an unfinished goal. | | HAPT-01 | Reliable detection, physical cue selection, and wearer interpretation still require validation. |
| Word-motion guidance / demonstration patterns | The operator reported that the Developer Mode visual preview worked as intended during word practice. | Nov. 18 report | HAPT-01 | Physical word-motion guidance remains an unfinished goal. |
| App instruction, navigation, and feedback | Final-build checks not yet documented | | | |
| Accounts and saved progress | Operator reported that progress was still visible after closing and reopening the app. | Nov. 18 report | LIVE-03 | Account isolation and cloud records are not yet documented. |
| Battery-powered operation | Demo power will be supplied by laptop USB due to earlier battery issues. | Nov. 18 decision | BUILD-01 | Battery failure details and runtime are not yet documented. |

Use the [glove model handoff](GLOVE_MODEL_SESSION_HANDOFF.md) and the dated
records below to verify the build shown at the release. Reported live checks,
software validation, and intended feature coverage describe distinct evidence.

## 2. Hardware, calibration, and power evidence

- [ ] **HW-1:** Check each flex channel independently: finger identity, straight
  and bent readings, response direction, usable range, noise, and any clipping.
  Retain raw values and the calibration/profile actually used.
- [ ] **HW-2:** Record sensor checks after final mounting and, if performed,
  after removing/re-donning the glove. Describe repeatability or drift observed.
- [ ] **HW-3:** Check IMU axes, units, mounting direction, and stationary/moving
  responses. Record magnetic availability and calibration/fusion actually used;
  do not treat magnetic telemetry as proof of calibrated orientation.
- [ ] **HW-4:** Record USB and battery startup, connection, and signing behavior
  separately. Record power source, test duration, disconnects/resets, and changes.
  [BUILD-01](#build-01-pcb-and-glove-assembly-history) records the demo power choice.
- [ ] **HW-5:** If battery runtime is measured, retain start/end conditions and
  workload. If it is not measured, do not state a measured runtime.
- [ ] **HW-6:** Record physical observations: secure attachment, insulation,
  wiring strain, fit, comfort, and any heat or component problems encountered.

Follow [the glove/model handoff](GLOVE_MODEL_SESSION_HANDOFF.md) and its linked
guides for calibration/model changes. A saved measurement profile is not proof
that its values were applied to inference. This checklist does not authorize
changes to the sensor or model contracts by itself.

## 3. Recognition and model evidence

- [ ] **ML-1:** Record exactly what each deployed model recognizes, where it
  runs, input features/units, calibration, sampling/window policy, preprocessing,
  model size, and completion/rejection rules.
- [ ] **ML-2:** Record dataset counts by class, actual wearers, sessions, sensor
  configuration, and orientation. Link original recordings and label manifests.
- [ ] **ML-3:** Record training/validation/test separation, trial/session/signer
  boundaries, training-only scaling, and how candidates were selected. Identify
  reused evaluation data; reserve fresh final attempts before tuning when able.
- [ ] **ML-4:** Keep a per-target live attempt log for the letters, numbers, and
  words actually tested. Include failed, invalid, and inconclusive attempts.
  [LIVE-03](#live-03-selected-sign-rehearsal-and-progress-persistence) has the
  operator's per-target totals as reported.
- [ ] **ML-5:** Record expected target, sign actually performed, predicted label,
  confidence, completion awarded or not, and any separate human correctness
  check. A completion threshold is not an accuracy measurement.
- [ ] **ML-6:** Check confusable signs, incorrect/incomplete signs, idle motion,
  and unrelated movements. Count false completions as well as missed completions.
- [ ] **ML-7:** Document the users, wrist orientations, and signing conditions
  actually evaluated. Separate main-wearer results from other-wearer results.
- [ ] **ML-8:** Summarize correct/total results per target and overall, stating
  what was counted (frames, whole attempts, or trial-averaged predictions).
  Include confusion matrices, macro F1, and top-5 results when appropriate and
  available; do not imply the assignment mandates every metric.
- [ ] **ML-9:** Record model comparisons and reasons for the final choice if
  models changed. Include measured phone latency and deployment size if tested.

Use the attempt-log template below. Software replay, training evaluation, and
live physical attempts are different evidence types. Repeating a recorded trial
does not create an independent new sign attempt. App completion is not proof
that a user learned or retained a sign.

## 4. Haptic feedback evidence

- [ ] **HAP-1:** Link the separate haptic session's implementation notes,
  actual actuator/driver details, physical mapping, and tested drive settings.
- [ ] **HAP-2:** Check all ten outputs individually and record which ones
  produce usable sensations with the actual mounting.
- [ ] **HAP-3:** Document how the system identifies a finger needing correction
  and chooses bend versus straighten. Record reference data, thresholds, and
  behavior when readings are missing, noisy, stale, or ambiguous.
- [ ] **HAP-4:** Check that commanded finger/directional patterns match the
  physical outputs. Record simultaneous versus sequential behavior and timing.
  [HAPT-01](#hapt-01-piezo-output-check) records the reported match between
  physical outputs and highlighted dots during manual activation.
- [ ] **HAP-5:** Check whether users identify the finger and intended direction.
  Record the instruction given, cues presented, responses, and correct/total
  counts. Distinguish audible hints from tactile perception if relevant.
- [x] **HAP-6:** Describe the final word-motion behavior, if any. Separate
  demonstration playback from feedback based on detected motion errors.
  See [HAPT-01](#hapt-01-piezo-output-check) for the working visual preview.
- [ ] **HAP-7:** Check perception during signing and whether actuation affects
  sensor readings, recognition, BLE delivery, power, or comfort.
- [ ] **HAP-8:** Check that cues stop on cancellation, navigation, disconnection,
  or other relevant interruption. Record outstanding problems.

Actuator activation, useful correction selection, understandable cues, and
improved learning are separate claims. Record only what was actually evaluated.

## 5. App, integration, reliability, and performance

- [ ] **APP-1:** Test the whole flow: connect glove, select target, attempt sign,
  receive feedback, complete/retry, and return to the learning page.
- [ ] **APP-2:** Test practice exit, app backgrounding, disconnect/reconnect,
  interrupted attempts, and stale/invalid data. Recheck the previously reported
  static-target completion after leaving practice; do not assume it is fixed.
- [ ] **APP-3:** Check account access and progress isolation for the actual
  account workflows supported. Record any recovery flows tested or not tested.
- [ ] **APP-4:** Confirm local saving, restart persistence, and corresponding
  cloud records. Test offline/reconnection behavior if feasible; a visible
  "Synced" indicator alone does not independently verify database contents.
  [LIVE-03](#live-03-selected-sign-rehearsal-and-progress-persistence) records
  the reported close/reopen check.
- [ ] **APP-5:** Record final software checks/builds with commands, revisions,
  dates, pass/fail counts, warnings, and logs. Keep older alpha/beta runs dated.
- [ ] **APP-6:** For a sustained-use test, record duration, workload, delivered
  packet rate/gaps, disconnections, crashes, and recovery. Choose and record the
  duration and acceptance criteria before the run rather than inventing them later.
- [ ] **APP-7:** If measuring latency, define the start/end events and retain
  repeated measurements on the actual phone. Separate inference time from the
  full sensor-to-feedback or completion delay.
- [ ] **APP-8:** Record layout, instructional asset, readability, and usability
  checks actually performed, including devices/settings and unresolved issues.

## 6. User feedback, historical tests, and engineering lessons

- [ ] **USER-1:** Record who participated using anonymous IDs, team/non-team
  status, relevant signing experience, tasks, date/location, and help provided.
  Explain recording/data use to participants and record what was agreed.
- [ ] **USER-2:** Capture task outcomes and feedback on connection, navigation,
  instruction, feedback, comfort, and frustration. Preserve observations that
  conflict with expectations, not just positive comments.
- [ ] **USER-3:** Link each feedback round to changes made and any retest. M6
  expects multiple rounds with outside users; R4 should describe what actually
  occurred, including gaps if the intended testing was not completed.
  [USER-01](#user-01-lab-glove-tryouts) records the two reported rounds for
  USER-1 through USER-3.
- [ ] **HIST-1:** Locate alpha and beta test plans/results and retain their
  actual procedures, setups, dates, outcomes, and evidence limitations. Do not
  retrospectively invent missing attempt counts, builds, or timings.
- [ ] **HIST-2:** For each important failure, explain expected versus observed
  behavior, investigation, cause if established, change made, and retest result.
  Examples to revisit include broken flex channels, BLE/power problems, window
  handling, and practice lifecycle defects.
- [ ] **HIST-3:** Distinguish fresh physical tests, historical demonstrations,
  recorded-model evaluation, emulator replay, and unit/build checks in Results.

## 7. Design, tools, constraints, and research

- [ ] **DES-1:** Update the system diagram to the actual final architecture:
  sensing, static/word processing, BLE commands/telemetry, app, haptic control,
  accounts, local storage, and cloud synchronization.
- [ ] **DES-2:** Update the as-built schematic, component placement, and key app
  screenshots. Explain interfaces, subsystems, and protocols without source code.
- [ ] **DES-3:** Describe design risks and actual mitigations, plus any remaining
  risk/limitation. Use observations rather than declaring the product certified.
- [ ] **DES-4:** Record constraints and their consequences: schedule, budget,
  hardware/memory, power, one-hand sensing, available data, mounting, and repairs.
- [ ] **DES-5:** Record actual BOM/cost scope; distinguish purchased parts from
  complete reproducible system cost, replacements, and the required phone.
- [ ] **REF-1:** Reuse relevant preliminary-report scholarship, checking that
  cited claims still match the final design. Add primary research for genuinely
  new claims and identify what differs from other studies' hardware/data.
- [ ] **REF-2:** Cite the tools, standards, and protocols actually used. Describe
  custom BLE behavior accurately; using a protocol is not a certification claim.
- [ ] **REF-3:** Reconcile in-text citations, figure sources, reference numbers,
  and bibliography after additions. Record source details as they are used.

## 8. Needs, impact, ethics, limits, and future work

- [ ] **IMPACT-1:** Revisit the first-semester design goals and explain which
  needs the final system addresses, its practical contribution, and remaining gaps.
- [ ] **IMPACT-2:** Discuss public health, safety, and welfare considerations
  relevant to this actual glove: physical/electrical use, comfort, and misleading
  instruction or feedback. State mitigations and evidence limits.
- [ ] **IMPACT-3:** Cover cultural, global, social, economic, and environmental
  factors with project-specific examples: ASL scope, Deaf/fluent-signer input,
  right-hand/device access, costs, repairs, component waste, and reuse.
- [ ] **IMPACT-4:** Record ethical/professional considerations: informed data
  collection, privacy in saved progress/recordings, honest results, instructional
  correctness, accessibility, and attribution/AI disclosure.
- [ ] **IMPACT-5:** Explain sensing limits, including finger spread and unreliable
  body-relative hand location, plus any final vocabulary or haptic restrictions.
- [ ] **IMPACT-6:** Separate unfinished original goals from future extensions.
  Explain what each would require and what a later team could build on.
- [ ] **IMPACT-7:** Distinguish demonstrated functionality from hoped-for learning
  benefits. Claim learning/retention improvement only if separately evaluated.

## 9. Report assembly checklist

These are R4 requirements from the prompt Gael supplied in chat. Section titles
are flexible; all required content must be organized and readable.

- [ ] Begin with a 200-300 word abstract, updated after the results settle.
- [ ] Introduction: need, motivation, approach, and explicit broader considerations.
- [ ] Background: theoretical context, prior art, scholarly evidence, and relevant
  team experiments, with citations.
- [ ] Timeline: actual completion dates, implementation approach, and work strategies.
- [ ] Design: user interfaces, internal subsystems, communication, risks/mitigations.
- [ ] Tools, constraints, and engineering standards, properly cited.
- [ ] Needs/impact: all requested contexts, ethics, limitations, and future work.
- [ ] Results: reproducible alpha/beta procedures and results, final functionality,
  experiments and user/stress/performance testing actually done, unfinished goals,
  challenges, changes, and lessons.
- [ ] Conclusion: connect actual outcomes, goals, contribution, and research/practice.
- [ ] Complete references and accurate acknowledgements/AI disclosure.
- [ ] US Letter or A4; margins 0.5-0.75 inches; at most 5,000 words excluding
  references and acknowledgements; no source code in the report; final PDF for Canvas.
- [ ] Use the previously confirmed CEN4908C report heading unless Gael corrects it;
  note that the supplied assignment prints CEN3908C. Confirm final date/cutoff.
- [ ] Remove drafting placeholders and unsupported claims; verify figures, captions,
  tables, word counts, citations, and final exported layout when requested.

## 10. Evidence index

Prefer links to existing records instead of duplicating raw data. Store new
evidence in approved team storage and put its path/link here. Do not publish
personal account information or participant identities in report screenshots.

| Record ID | Date | Topic / checklist IDs | Type and outcome | Raw files / detailed record | Report section |
| --- | --- | --- | --- | --- | --- |
| BASE-01 | Historical; last handoff Nov. 6 | Baseline and calibration/model workflow | Reference only; not a final acceptance run | [Glove/model handoff](GLOVE_MODEL_SESSION_HANDOFF.md) | Design / Results context |
| BASE-02 | Historical | Earlier physical demonstrations | Team-reported observations; see source limits | [Demo observations](R3_DEMO_OBSERVATIONS.md) | Alpha/beta Results |
| BASE-03 | Current report planning | Agreed intended final scope | Goals, not verified outcomes | [Feature inventory](#1-final-build-and-completion-timeline); scope agreed in Gael's report discussion | Timeline / final scope |
| CAL-01 | November 18, 2026 | Guided glove calibration (HW-1 to HW-3) | Operator reported failed pinky repeatability and ±Y/±Z pose checks | [Calibration session note](#cal-01-guided-glove-calibration) | Results / limitations |
| CAL-02 | November 18, 2026 | Guided flex calibration after resistor swap (HW-1) | Operator reported index ADC clipping and blocked profile save | [Index clipping note](#cal-02-index-adc-clipping) | Results / limitations |
| CAL-03 | November 18, 2026 | Six-face accelerometer diagnostic (HW-3) | Four checks passed. Both Y captures had the opposite sign from their pose labels. | [Axis measurements](#cal-03-six-face-accelerometer-diagnostic) | Results / limitations |
| DATA-01 | November 18, 2026 | Post-swap recording review (HW-1, ML-2) | Verified 57 labeled trials and measured ADC clipping | [Recording review](#data-01-post-swap-recording-review) | Results / limitations |
| EVAL-01 | November 18, 2026 | Offline app-rule replay of post-swap recordings (ML-4 to ML-8) | Static 5/36 intended completions. Words 0/9 intended completions. | [Replay results](#eval-01-post-swap-offline-replay) | Results / limitations |
| EVAL-02 | November 18, 2026 | Post-swap augmentation pilot (ML-3, ML-8, ML-9) | Six word candidates tied at 2/3 validation top-1. Both TCNs completed 1/3 in app-rule replay. | [Pilot results](#eval-02-post-swap-augmentation-pilot) | Results / limitations |
| EVAL-03 | November 18, 2026 | Demo word TCN retraining (ML-3, ML-8, ML-9) | Frozen candidate completed 3/3 matching and 0/18 wrong-target exposures on reserved recordings. | [Demo word candidate](#eval-03-demo-word-tcn-retraining) | Results / limitations |
| LIVE-01 | November 18, 2026 | Demo wearer rehearsal (ML-4, ML-5) | Operator reported live G, I, and 1 successes and inconsistent word results except Please. | [Rehearsal and follow-up](#live-01-demo-wearer-rehearsal) | Results / limitations |
| EVAL-04 | November 18, 2026 | Real-only, all-channel word model (ML-3, ML-8, ML-9) | Five matching completions and zero wrong-target completions across 25 exposures on reserved recordings. | [Second word APK](#eval-04-real-only-all-channel-word-model) | Results / limitations |
| LIVE-02 | November 18, 2026 | Real-only word model live retest (ML-4, ML-5) | Operator reported that Please, Hello, and Yes worked on the phone. | [Live word retest](#live-02-real-only-word-model-live-retest) | Results / limitations |
| HAPT-01 | November 18, 2026 | Piezo output check (HAP-1, HAP-2, HAP-4, HAP-6) | All ten outputs were audible during serial testing. The operator reported matching dots and buzzers in the manual phone test and a working word-practice preview. | [Piezo output check](#hapt-01-piezo-output-check) | Results / limitations |
| BUILD-01 | Reported November 18, 2026 | PCB and glove assembly revisions (BUILD-1, BUILD-4, HIST-2, DES-2) | Team abandoned the fabricated PCB and later replaced conductive thread with discrete wiring on a perfboard-based glove. | [Assembly history](#build-01-pcb-and-glove-assembly-history) | Timeline / Design / Results |
| LIVE-03 | Reported November 18, 2026 | Selected-sign rehearsal and progress (ML-4, ML-5, APP-4) | Operator reported at least 10 successful attempts each for G, I, 1, Hello, Please, and Yes, and progress persisted after closing and reopening the app. | [Rehearsal and persistence](#live-03-selected-sign-rehearsal-and-progress-persistence) | Results / limitations |
| USER-01 | Reported November 18, 2026 | Two friends of team members across two lab rounds (USER-1 to USER-3, HIST-2) | Participants reported the glove was failing. The team replaced broken flex sensors after the first round and switched to wires after diagnosing conductive-thread shorts in the second. | [Lab tryouts](#user-01-lab-glove-tryouts) | Results / engineering lessons |
| | | | | | |

### CAL-01 guided glove calibration

- **Setup and procedure:** Operator used the app's guided glove calibration.
  Hardware/mount, firmware and app revisions, and exact pose sequence are not
  yet documented.
- **Expected and reported:** Repeated flex readings should agree and steady
  board orientations should show the expected signed acceleration axes. The
  operator reported pinky repeatability and ±Y/±Z axis check failures. The app
  gates profile save on these checks. A save attempt outcome, raw readings,
  screenshots, and the exact on-screen wording are not yet documented.
- **Follow-up:** Check live pinky readings across repeated open and bent poses
  and verify the signed accelerometer axes in BLE Testing before recapturing.
  No calibration changes were made. Retest is not yet documented.

### CAL-02 index ADC clipping

- **Setup and procedure:** Operator reported a resistor swap and ran guided
  glove calibration. Resistor values and the exact hardware and build revisions
  are not yet documented.
- **Expected and reported:** Index readings should stay inside the 12-bit ADC
  limits in both open and both index-bent captures. The operator reported
  `index: ADC clipping at a rail.` and could not save the profile. The index
  bent reading was reported at the upper 12-bit ADC limit of 4095 counts.
  Packet-level evidence and repeat-by-repeat values were not supplied.
- **Reported values:**

  | Channel | Straight (ADC counts) | Bent (ADC counts) |
  | --- | ---: | ---: |
  | Thumb | 535 | 397 |
  | Index | 535 | 4095 (clipped) |
  | Middle | 541 | 193 |
  | Ring | 591 | 245 |
  | Pinky | 548 | 224 |

  Reported gyro bias was X = 0.62, Y = 0.18, Z = 0.13 degrees/s.
- **Follow-up:** See [CAL-03](#cal-03-six-face-accelerometer-diagnostic) for
  the separate orientation session and [DATA-01](#data-01-post-swap-recording-review)
  for rail counts in labeled recordings. A clipped index measurement cannot
  establish a bent endpoint. A guided flex calibration retest is not yet
  documented.

### CAL-03 six-face accelerometer diagnostic

The operator supplied `Helping Hand calibration diagnostics.json` from the
IMU-only workflow. The export reports device identity `0xEA` and has 121 packets
over 3.000 s per face (726 packets total). Setup revision fields were blank.

| Named pose | Median X (g) | Median Y (g) | Median Z (g) | Check |
| --- | ---: | ---: | ---: | --- |
| +X | +0.994 | +0.027 | +0.023 | Pass |
| −X | −1.000 | −0.004 | +0.135 | Pass |
| +Y | −0.056 | −1.012 | −0.025 | Fail |
| −Y | +0.054 | +0.983 | +0.044 | Fail |
| +Z | +0.006 | +0.055 | +1.026 | Pass |
| −Z | +0.166 | +0.165 | −0.949 | Pass |

The largest within-pose acceleration standard deviation across axes was
0.0235 g. The Y pair showed stable opposite signs. Verify which marked
board face was up during those captures before attributing the sign mismatch
to the mounting or firmware. This run measured steady acceleration.

### DATA-01 post-swap recording review

- Match `trials (3).csv` with `manifest (4).json` and `trials (4).csv` with
  `manifest (3).json` by internal session IDs. Trial metadata and row counts
  match. All 8,133 stored rows carry six IMU values, five flex values, and
  valid packet flags. Within trials, the device cadence was approximately
  40 Hz with no device sequence gaps. Both manifests have no active profile.
- Static data has 6,140 frames from 36 labeled trials (one each for A–Z and
  0–9). Word data has 1,993 frames from 21 trials (three each for Hello,
  Thank You, Please, Yes, Sorry, No, and Eat). Drink is absent. All saved trials
  are labeled neutral. The word exports use three signer IDs, each with one
  trial per word. Distinct physical wearers are not yet confirmed.
- The digit 2 trial clipped at 4095 for 129/182 index frames and 127/182 thumb
  frames. Ring readings reached zero on E, S, and 4 (45 static frames), and on
  Thank You, Yes, and Eat (95 word frames). Thumb and index were within four
  counts on 7,651/8,133 sign frames. The reason for this agreement is unknown.
  An isolated single-finger motion test can check channel independence.
- Keep the raw values for provenance and flag ADC rail readings before using
  them as flex measurements. The recordings contain one labeled attempt per
  static target and three per recorded word. Repeatability and live lesson
  completion require additional evidence.

### EVAL-01 post-swap offline replay

- Replayed DATA-01 using `backend/evaluate_demo.py` and recorded phone
  receive timestamps. Static used the original packet predictions and the
  Flutter stable-hold rule. Words used the bundled 96-sample, three-class TCN
  and Flutter Start/Finish completion rules. Trial boundaries were constructed
  around the recorded packets. Operator-provided labels supplied ground truth.
- Static completed on 5 of 36 matching-target exposures (A, G, I, 1, and 3)
  and on 29 of 1,260 wrong-target exposures. Digit 1 completed its single
  positive attempt and had zero completions on the other 35 recordings. The
  tested alphabet includes J and Z, which the static runtime does not support.
- Words completed on 0 of 9 matching-target exposures and on 21 of 54
  wrong-target exposures. Every Hello and Yes attempt completed under Please,
  and every Please attempt completed under Hello. The remaining four recorded
  words were evaluated as other signs against the three deployed targets.
  No replay capture or preparation failures were reported.
- Detailed plans and results are in local `tmp/sign-review-20261118/`, under
  `static-replay/report.json` and `word-replay/report.json`. Wrong-target
  exposures reuse the 57 recorded attempts. Native phone inference, idle
  rejection, and live completion were not tested by this replay.

### EVAL-02 post-swap augmentation pilot

- Generated three bounded jitter copies per source trial for A, G, I, 1, and
  3, yielding 15 static training copies from five rail-free source trials.
  Measured quiet-pose differences supplied the limits for middle, ring, and
  pinky. Thumb and index were held at their recorded values due to the
  unresolved channel agreement. The static subset has one original per label.
  Static MLP training and held-out scoring were not run in this pilot.
- Compared TCN, CNN–GRU, and CNN–LSTM with and without augmentation for Hello,
  Please, and Yes. The derivative training dataset omits four isolated ring
  zero packets in the Yes recordings. Device-time resampling bridges the
  resulting single-packet gaps. All nine trials fit the 128-sample window.
  Recorded IDs define three trial groups for training, validation, and reserved
  test. Each has one real attempt per word. Physical signer independence has
  not been confirmed. The augmented fit used nine training copies from three
  originals, jittering only the IMU channels within limits derived from CAL-03.
- All six fits scored 2/3 top-1 and 0.556 macro F1 on the same three cleaned
  validation trials. Hello and Please were the two correct top-1 labels.
  Both TCNs completed only Please when replayed on the original validation
  packets through the app rules. The real-only TCN had one false completion
  across 18 wrong-target exposures. The augmented TCN had two.
- Pilot files, source hashes, dropped-packet identities, lineage, splits,
  validation reports, TFLite files, and replay details are under local
  `tmp/post-swap-word-pilot-20261118/`. Reserved test scoring, native phone
  inference, and live validation were not run. No deployment selection was
  made from the three-try validation set.

### EVAL-03 demo word TCN retraining

- Compared four TCN variants on the same source groups, using the six IMU
  channels alone or paired with middle and pinky flex. For each feature set,
  trained with and without the measured jitter from CAL-03. The selected model
  uses middle and pinky plus the six IMU channels. Windowing uses 128 samples
  at 40 Hz. The scaler was fitted on original training trials.
- Training used seven real attempts (643 sensor frames) and 21 jittered
  copies, for 28 fixed-length training sequences. The 3,584 window time
  steps include padding. Hello, Please, and Yes were completion targets.
  Thank You, Sorry, No, and Eat supplied examples for an internal Other
  class. Other probability was distributed across the three exposed scores
  to reduce confidence while preserving the existing app interface and 80%
  acceptance threshold.
- The selected model was frozen using the development group before scoring
  the reserved group. Original packet replay completed Hello, Please, and
  Yes (3/3) with zero wrong-target completions (0/18) in each of those two
  groups. The 18 wrong-target exposures reuse the seven recordings in each
  group. Group IDs do not establish distinct physical wearers. Idle motion
  and fresh live phone/glove attempts remain not run.
- Training scripts, counts, candidate metadata, and replay reports are in
  local `tmp/post-swap-demo-word-20261118/`. The demo app build is separate
  from the normal bundled model. The static MLP remains the deployed baseline
  for the G, I, and 1 rehearsal targets.

### LIVE-01 demo wearer rehearsal

- The operator reported live success for G, I, and 1, and described word
  recognition as inconsistent except for Please. Attempt counts, exact
  recognition messages, phone details, and direct logs of failed practice
  attempts were not supplied. The follow-up export is a separate recording
  session and does not capture the failed live attempts.
- The new `trials (5).csv` and `manifest (5).json` matched by session and
  contain 1,250 frames across four Hello, four Yes, and three Thank You
  attempts. The first demo APK model completed all eight Hello/Yes attempts
  and zero wrong-target exposures in offline replay on these recordings.
  The difference between offline and live outcomes remains unresolved.
- Thumb and index were within four ADC counts on 1,201/1,250 frames. Ring
  hit zero on 641 frames and pinky on two. The longest ring rail run was
  121 frames. Channel coupling is suspected from the recorded behavior.
  The physical cause is not confirmed.
- The optional flex estimate tables preserve the measured columns. Across
  both word sessions, 14 isolated rail readings had close, valid neighbors
  and were interpolated into labeled estimate columns. The other 724 rail
  values remain marked missing in those tables. Thumb and index were never
  reconstructed from one another. Details and source hashes are in local
  `tmp/post-swap-word-followup-20261118/flex-repair-audit.json`.

### EVAL-04 real-only all-channel word model

- Used 12 original training attempts (1,205 sensor frames) from the two
  post-swap word sessions. This candidate uses all five flex channels and
  six IMU channels. Near-rail flex values contribute zero after train-only
  standardization. The scaling statistics exclude these values. The selected
  fit used zero generated sequences and no estimates from the repair tables.
- The 160-sample window retains the longer new recordings. The original
  threshold and class targets remain Hello, Please, and Yes. The selected
  model completed all five intended exposures and zero of 25 wrong-target
  exposures in full validation replay. The same outcome held with a simulated
  200 ms late start and 200 ms early finish, as separate boundary checks on
  the same recordings.
- A separate reserved replay produced five matching completions and zero of
  25 wrong-target exposures on ten original recordings. The five were two
  Hello, one Please, and two Yes. These are offline results. The new APK and
  replay evidence are under local `tmp/post-swap-word-followup-20261118/`.
  See [LIVE-02](#live-02-real-only-word-model-live-retest) for the separate
  physical check.

### LIVE-02 real-only word model live retest

- The operator reported that Please, Hello, and Yes worked on the demo
  glove and Android phone using the v2 Flutter test build (1.0.1+2). The
  report does not include repeat counts, live confidence values, or
  wrong-target checks, so no live rate is calculated.
- At the operator's request, the same TFLite and metadata bytes were promoted
  to the standard Flutter assets. The recorded static MLP remains the
  deployed baseline for G, I, and 1.

### HAPT-01 piezo output check

- The operator used the ESP32 piezo testing tool and reported hearing all ten
  piezo outputs. The operator reported very faint tactile sensation. The
  as-tested hardware revision, output-by-output tactile responses, repetitions,
  selected drive settings, and raw logs are not yet documented.
- This provides a qualitative audible output check. Reliable location and
  direction discrimination remain unverified. The existing Flutter hand
  indicators were generated by the practice animation at the time. See the
  [manual output display and word preview handoff](HAPTIC_ENGINEERING_HANDOFF.md#november-18-demonstration-controls)
  for the later demo implementation.
- **Manual phone test:** Gael used the app's Piezo Outputs screen and reported
  that the physical buzzers activated at the locations shown by the highlighted
  dots. The phone/app/firmware revisions, per-output tally, perceived intensity,
  and stop behavior on interruption are not yet documented for this check.
- **Word practice:** Gael also tried the practice screen preview and reported
  that it worked as intended. The preview visually highlights a dot after a
  recognized target word. Physical word-motion guidance remains unfinished.

### BUILD-01 PCB and glove assembly history

- **PCB attempt:** The team designed and fabricated a custom PCB and built a
  glove assembly around it. The team reported mechanical breakage, unreliable
  connections, and poor quality of the engraved copper traces. The team
  abandoned that board and returned to perfboard.
- **Conductive-thread attempt:** The team built a perfboard-based glove with
  conductive thread connections and connected the piezos. The assembly used
  multiple fabric layers to insulate the connections. The assembly remained
  unreliable. The team attributed missing sensor values during the latest
  tryout to conductive-thread shorts. Electrical measurements for that
  diagnosis are not yet documented. See [USER-01](#user-01-lab-glove-tryouts).
- **Current assembly:** The team replaced conductive thread with discrete
  wires and continues to use perfboard. The demo will use USB power from Gael's
  laptop because the team previously had battery issues. Exact build dates, the
  as-built wiring diagram, final fabric layers, and power used during earlier
  tests are not yet documented.
- **Photos supplied November 18:** [Final glove](figures/r4/IMG_9891.jpeg)
  shows the cuff-mounted ESP32 board on perfboard, discrete wiring, five flex
  strips, and ten piezo discs (five near the fingers and five in a plus on the
  back of the hand). The abandoned custom PCB is shown from the
  [component side](figures/r4/IMG_9894.jpeg) and
  [reverse side](figures/r4/IMG_9893.jpeg). The photos document the visible
  assembly. The IMU mount and electrical checks require separate evidence.

### LIVE-03 selected-sign rehearsal and progress persistence

- **Source and procedure:** On November 18, 2026, Gael reported repeating the
  six selected demo signs on the glove and app at least ten times each, with
  every attempt working. The phone/OS, exact app and firmware revisions,
  power source during this rehearsal, and raw per-attempt records are not yet
  documented.

| Target | Reported successful attempts, minimum |
| --- | ---: |
| G | 10 |
| I | 10 |
| 1 | 10 |
| Hello | 10 |
| Please | 10 |
| Yes | 10 |
| **Total** | **60** |

- **Result scope:** Gael also reported trying additional signs without
  specifying their labels, counts, or outcomes per target. The six named
  targets provide a rehearsal result for one wearer. Exact counts, a
  trial-by-trial record, and broader live recognition accuracy remain unknown.
- **Progress:** Gael reported that saved progress was still visible after
  closing and reopening the app. Cloud records, cross-device or account
  behavior, and offline persistence are not yet documented.

### USER-01 lab glove tryouts

- **Participants and feedback:** Gael reported two lab tryouts with two friends
  of team members. Gael recalled feedback along the lines of “I don't think
  it's working.” That prompted the team to investigate. Attendance by round,
  signing experience, specific tasks, and assistance are not yet documented.

| Round | Observation reported by Gael | Change or retest |
| --- | --- | --- |
| About one month before November 18 | The team investigated incorrect readings and identified broken flex sensors. | The team bought and installed replacement flex sensors. |
| November 18, 2026 | The team investigated missing sensor readings and attributed them to conductive-thread shorts. | The team switched to discrete wiring. A repeat tryout with the two participants after rewiring is not yet documented. |

- **Evidence gap for M6:** The first round's date is approximate. Both rounds
  are documented from Gael's recollection. Gael reported having no photos or
  other records from the tryouts, so timestamped third-party evidence is missing.

### Build/test session record - copy for each session

```text
Record ID:
Date/time and location:
Person recording; participant IDs and team/non-team status:
Checklist IDs / report section:
Evidence type: physical / offline model evaluation / software / review
Goal / question:
Setup: hardware/mount, firmware/app revision + local changes, phone/OS,
       power, sensor/calibration profile, model/preprocessing/labels:
Procedure: exact steps, inputs/targets, repetitions, timing, assistance:
Expected behavior and acceptance criteria chosen before testing:
Actual results: counts, units, failures, invalid/inconclusive attempts:
Raw files / photos / logs / commands:
Interpretation and limits: what this does and does not establish:
Change made or next action:
Retest record ID (if any):
```

### Recognition attempt log - copy for each evaluated build/session

Record ID and complete setup: [link to session record]

| Attempt / raw trial ID | Participant / session | Selected target | Sign actually performed | Condition / orientation | Prediction / confidence | Completion? | Valid / invalid and reason | Human correctness check, if any | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| | | | | | | | | | |

### Problem, change, and retest log

| Issue ID | Date / affected setup | Expected vs actual behavior | Evidence / cause certainty | Change and revision | Retest record / outcome | Remaining impact |
| --- | --- | --- | --- | --- | --- | --- |
| | | | | | | |

### Timeline and decisions log

| Date | Feature / decision | Work actually completed and strategy | Evidence | Planned work still outstanding |
| --- | --- | --- | --- | --- |
| | | | | |

### Report progress

- November 17: R4 requirements compared with R3; preliminary report will be the
  foundation. Evidence collection checklist and reusable logs prepared.
- November 18: Filed hardware photos and recorded the demo USB power choice,
  selected-sign rehearsal, app restart observation, and lab tryouts.
- Next useful update: add a session record when assembly, calibration, haptic
  implementation, or testing produces actual evidence, and link its checklist IDs.
