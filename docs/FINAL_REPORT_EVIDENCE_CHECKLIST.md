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
| New ICM-20948 integration and calibration | Gael confirmed that the ICM-20948 was installed, calibrated, and working on the glove. | Confirmed during M6 review | CAL-03 and M6 review follow-up below | The app flagged some checks. The cause of those messages remains unknown. |
| A-Z recognition, including moving J/Z | ESP32 static MLP supports 24 letters. J and Z use a separate phone TCN in Alphabet practice. Operator reported at least 10 live successes each for G and I. | Nov. 18 rehearsal, Nov. 19 J/Z integration | LIVE-01, LIVE-03, EVAL-05 | J/Z have been checked offline. Live J/Z and full per-letter validation are not yet documented. |
| 0-9 recognition | ESP32 static MLP supports ten digits. Operator reported at least 10 live successes for 1. | Nov. 18 rehearsal | LIVE-01, LIVE-03 | Full per-digit live validation is not yet documented. |
| All eight app words | App lists eight words. Hello, Please, and Yes have named live practice results. The working build adds Sorry and No using a second model checked offline. | Nov. 18 rehearsal and Nov. 19 model expansion | EVAL-04, EVAL-06, LIVE-02 to LIVE-04 | Live Sorry and No checks are Not run. Thank You and Eat need further separation checks. Drink has no captured trials. |
| Ten actuator outputs | Operator heard all ten during serial testing. In the app's manual Piezo Outputs screen, the operator reported that the physical buzzers matched the highlighted dots. | Nov. 18 report | HAPT-01 | Tactile sensation was very faint in the serial check. The phone test has no per-output tally or interruption results on file. |
| Automatic finger bend/straighten guidance | The Developer Mode demo for 3 starts automatically after five seconds, repeats needed middle or pinky corrections, and stops when practice completes. Gael reported that the timed demo worked on the glove. | Nov. 19 implementation and rehearsal | DATA-02, HAPT-02, HAPT-03 | Per-cue timing, output counts, and wearer perception were not measured during the rehearsal. |
| Word-motion guidance / demonstration patterns | Developer Mode starts a preset back-of-hand cue three seconds after opening Hello or Please, then replays after two-second pauses. Starting an attempt pauses the cue. | Current working build | HAPT-04, HAPT-05 | Software tests simulate glove responses. Live guidance and motion-error feedback remain unverified. |
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
  [LIVE-03](#live-03-selected-sign-rehearsal-and-progress-persistence) and
  [LIVE-04](#live-04-three-attempt-live-practice-check) preserve the operator's
  reported per-target results.
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
  See [HAPT-01](#hapt-01-piezo-output-check) for the earlier visual preview and
  [HAPT-05](#hapt-05-word-guidance-before-practice) for current preset guidance.
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
  the reported close/reopen check. [APP-09](#app-09-firestore-progress-sync-fix)
  records a write rejection and the server-side fix.
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
| DATA-02 | November 19, 2026 | Repeated static holds and moving J/Z (HW-1, ML-2, HAP-3) | 123 real trials. Seven static reference candidates checked against reserved holds. The scheduler passed 38 synthetic direction checks offline. | [Capture and cue checks](#data-02-repeated-sign-recordings-and-haptic-references) | Results / limitations |
| DATA-03 | November 19, 2026 | Additional seven-word recording session (HW-1, ML-2) | 53 real trials and 5,250 packet-valid frames. | [Word capture](#data-03-additional-word-recordings) | Results / limitations |
| EVAL-01 | November 18, 2026 | Offline app-rule replay of post-swap recordings (ML-4 to ML-8) | Static 5/36 intended completions. Words 0/9 intended completions. | [Replay results](#eval-01-post-swap-offline-replay) | Results / limitations |
| EVAL-02 | November 18, 2026 | Post-swap augmentation pilot (ML-3, ML-8, ML-9) | Six word candidates tied at 2/3 validation top-1. Both TCNs completed 1/3 in app-rule replay. | [Pilot results](#eval-02-post-swap-augmentation-pilot) | Results / limitations |
| EVAL-03 | November 18, 2026 | Demo word TCN retraining (ML-3, ML-8, ML-9) | Frozen candidate completed 3/3 matching and 0/18 wrong-target exposures on reserved recordings. | [Demo word candidate](#eval-03-demo-word-tcn-retraining) | Results / limitations |
| LIVE-01 | November 18, 2026 | Demo wearer rehearsal (ML-4, ML-5) | Operator reported live G, I, and 1 successes and inconsistent word results except Please. | [Rehearsal and follow-up](#live-01-demo-wearer-rehearsal) | Results / limitations |
| EVAL-04 | November 18, 2026 | Real-only, all-channel word model (ML-3, ML-8, ML-9) | Five matching completions and zero wrong-target completions across 25 exposures on reserved recordings. | [Second word APK](#eval-04-real-only-all-channel-word-model) | Results / limitations |
| EVAL-05 | November 19, 2026 | IMU-only J/Z TCN (ML-3, ML-8, ML-9) | Accepted 4/4 matching held-out motion letters and 0/36 unrelated attempts in the second offline experiment. | [Motion letters](#eval-05-jz-motion-letter-tcn) | Results / limitations |
| EVAL-06 | November 19, 2026 | Expanded word TCN (ML-3, ML-8, ML-9) | 22/24 intended matches across seven words on reserved recordings. One Thank You attempt scored as Eat. | [Word expansion](#eval-06-expanded-word-tcn) | Results / limitations |
| LIVE-02 | November 18, 2026 | Real-only word model live retest (ML-4, ML-5) | Operator reported that Please, Hello, and Yes worked on the phone. | [Live word retest](#live-02-real-only-word-model-live-retest) | Results / limitations |
| HAPT-01 | November 18, 2026 | Piezo output check (HAP-1, HAP-2, HAP-4, HAP-6) | All ten outputs were audible during serial testing. The operator reported matching dots and buzzers in the manual phone test and a working word-practice preview. | [Piezo output check](#hapt-01-piezo-output-check) | Results / limitations |
| HAPT-02 | November 19, 2026 | Number 3 practice demo (HAP-3, HAP-4, HAP-8) | Flutter tests exercised two directions and canceled the sequence on an invalid reading or page exit. | [Number 3 demo](#hapt-02-number-3-practice-demo) | Results / limitations |
| HAPT-03 | November 19, 2026 | Live rehearsal of the automatic number 3 demo (HAP-3, HAP-4) | Gael reported that the timed number 3 demo worked on the glove. | [Automatic haptic rehearsal](#hapt-03-automatic-number-3-demo-rehearsal) | Results / limitations |
| HAPT-04 | November 19, 2026 | Preset word cues for Hello and Please (HAP-4, HAP-6, HAP-8) | Flutter tests exercised the requested output order using simulated glove responses. | [Word cue playback](#hapt-04-word-cue-playback) | Results / limitations |
| HAPT-05 | Follow-up after slide preparation | Preset haptic guidance before word practice (HAP-6, HAP-8) | The cue starts three seconds after opening a lesson, replays after two seconds, and pauses before sensor recording. | [Word guidance](#hapt-05-word-guidance-before-practice) | Design / Results |
| BUILD-01 | Reported November 18, 2026 | PCB and glove assembly revisions (BUILD-1, BUILD-4, HIST-2, DES-2) | Team abandoned the fabricated PCB and later replaced conductive thread with discrete wiring on a perfboard-based glove. | [Assembly history](#build-01-pcb-and-glove-assembly-history) | Timeline / Design / Results |
| LIVE-03 | Reported November 18, 2026 | Selected-sign rehearsal and progress (ML-4, ML-5, APP-4) | Operator reported at least 10 successful attempts each for G, I, 1, Hello, Please, and Yes, and progress persisted after closing and reopening the app. | [Rehearsal and persistence](#live-03-selected-sign-rehearsal-and-progress-persistence) | Results / limitations |
| LIVE-04 | Reported November 18, 2026 | Three-attempt live practice check (ML-4, ML-5, ML-8) | G, I, 1, Hello, Yes, and Please succeeded on all three attempts each. K and X succeeded once each in three attempts. | [Practice results](#live-04-three-attempt-live-practice-check) | M6 verification / R4 Results |
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

### DATA-02 repeated sign recordings and haptic references

- `trials (6).csv` and `manifest (6).json` in Gael's Downloads match session
  `session_20261119T084617_709220Z`. The export has 14,824 packet-valid frames
  over 123 trials from one recorded signer ID, including five J and six Z
  motion attempts. There is no attached calibration profile.
- Thumb/index raw values were identical in 2,420 frames and within four counts
  in 11,791 frames. Gael reported that bending the index independently also
  moves the thumb reading. Ring hit the ADC rail in 3,655 frames.
- [The reference builder](../tools/haptics/build_pose_references.py) used steady
  central measurements from three or four holds per target and reserved each
  target's final two holds for a check. It omitted thumb and index everywhere
  and omitted ring for 3 and C, where it clipped in the fit holds. The ring
  and pinky bands for 5 showed poor coverage on the reserved holds. G, L, O,
  0, C and 3 had better coverage on the available channels in this session.
- The builder exercised both directions in 38 synthetic dry runs. The offline
  scheduler emitted a finger pulse followed by top/center/bottom or the reverse.
  The local bands, per-hold results, source hashes, and synthetic test inputs
  are in `tmp/motion-letters-20261119/static_haptic_references.json`.
  Physical playback, perception, and correction efficacy were not run.

### DATA-03 additional word recordings

- The matched `trials (7).csv` and `manifest (7).json` from Downloads identify
  session `session_20261119T142754_729891Z`. The 53 saved attempts include six
  Hello, seven Thank You, seven Please, eight Sorry, nine Yes, eight No, and
  eight Eat. All are labeled neutral under one signer ID. There are zero Drink
  or idle trials in the export.
- The backend accepted all 5,250 frames. Device times advanced within each
  attempt with no sequence gaps. Phone receipt times tied in 237 adjacent pairs
  and the longest within-trial receipt gap was 94 ms. Ring clipped at an ADC
  rail in 605 frames. Thumb and index were within four counts in 4,952 frames.
- Together with the two earlier post-swap word exports, there are 85 attempts
  and 8,493 packets across the seven labels. Session labels alone do not
  establish independent wearers. Source hashes and whole-trial assignments
  are in `tmp/word-expansion-20261119/frozen-split.json`.

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

### EVAL-05 J/Z motion letter TCN

- [The trainer](../backend/train_motion_letters.py) uses a 160-sample window
  at 40 Hz with six accelerometer and gyroscope features. The training set
  contains 104 original trials, including three J and four Z, and adds 208
  timing-offset examples derived from training trials. Scaling is fitted on
  real training windows. The ESP32 static MLP and three-word bundle remain in use.
- The first offline model accepted all four J/Z attempts and falsely accepted
  nine of 45 unrelated attempts. The second fit included additional recorded
  word negatives and validation negatives. At an 80% acceptance threshold it
  accepted all four held-out J/Z attempts and none of 36 unrelated attempts.
  The four included two J and two Z. Some of these recordings were examined in
  the first experiment. Signer independence and live accuracy are not established.
- The Flutter app routes J/Z to **Start attempt** and **Finish sign** in Alphabet
  practice and saves matching completions as letters. Flutter's input tensors
  matched Python's exactly on all 40 held-out raw packet sequences. The six-axis
  [model bundle](../flutter_app/assets/models/motion_letters_tcn/model_metadata.json)
  records the export and input hashes. Per-trial evidence is in
  `tmp/motion-letters-20261119/rejection-tuned/evaluation.json` locally.
  The live app/glove test is Not run.

### EVAL-06 expanded word TCN

- Fixed whole-trial training, validation, and reserved sets before fitting.
  The three word sessions contributed 37, 24, and 24 word attempts to those
  sets. The separate letter/number session contributed 36, 18, and 18 unrelated
  attempts, including moving J/Z. An `other` output can reject those movements.
- Compared all motion and flex inputs, six inertial axes alone, and the six
  inertial axes plus middle and pinky. Compared recorded-only fits with four
  training-only timing variants per attempt. The selected TCN used middle
  and pinky with the six motion axes, 73 original trials, and zero timing
  variants. The model masks flex rail readings after train-only scaling.
  See the [bundle metadata](../flutter_app/assets/models/expanded_words_tcn/model_metadata.json).
- At the app's 80% matching threshold, the exported model matched 22/24
  reserved word attempts and rejected all 18 reserved unrelated signs. It
  matched all 14 reserved attempts from the latest export. Two older Thank
  You attempts missed; one scored as Eat and one scored Thank You below
  threshold. The original three-word bundle matched 11/11 reserved attempts
  for its three trained words and made 11 wrong-label matches on the same
  42-clip set, all from unrelated signs.
- The working app uses the expanded model for Sorry and No and the rehearsal
  model for Hello, Please, and Yes. Replay through the Flutter capture and
  completion controller matched 3/3 for Sorry and 3/3 for No. Each target
  had 0/39 false completions, with zero capture or preprocessing failures.
  The still and moving sign negatives do not cover ordinary idle actions or
  new users. The 79 Flutter tests and Android debug build passed. Both
  packaged model files matched the verified assets. Live testing is Not run.
  The local run directory
  `tmp/word-expansion-20261119/` holds the frozen split, TFLite scores, and
  `expanded_words-replay.json`.

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
  On November 19, Gael reconfirmed that the manual test passed and the dots
  matched the buzzers.
- **Word practice:** Gael also tried the practice screen preview and reported
  that it worked as intended. The preview visually highlights a dot after a
  recognized target word. Physical word-motion guidance remains unfinished.

### HAPT-02 number 3 practice demo

- Below regular recognition, **Numbers → 3** in Developer Mode has a **Demo**
  box. With the glove connected, the learner gets five seconds to try 3 before
  cues are enabled. It uses the DATA-02 raw bands for middle (513–550) and pinky
  (310–355). Both reserved holds had all 79 central samples inside both bands.
  Thumb and index were coupled, and ring clipped in the fit holds, so those
  three inputs are omitted. The 175 ms persistence and 3.5% entry margin are
  software settings. The recognition tracker still awards lesson progress.
- The first cue selects the largest normalized deviation and stays with that
  finger until it enters its band or crosses past it. Bend uses finger,
  top, center, bottom. Straighten uses finger, bottom, center, top. The hand
  highlights each confirmed active output from the existing `piezo_demo`
  firmware. The app waits for that output to end before requesting the next.
  After a pattern ends, the same cue can repeat after two seconds if it is
  still needed. Completion, page exit, app backgrounding, or a fault cancels
  the demo. A correction that changes mid-pattern stops scheduling its
  remaining pulses.
- The targeted Flutter tests checked the start and repeat timing, both output
  orders, one-finger priority, and acknowledgment-driven highlights. They also
  exercised cancellation on completion, an invalid reading, and page exit.
  These checks used simulated packets and responses. See
  [HAPT-03](#hapt-03-automatic-number-3-demo-rehearsal) for the separate live
  rehearsal and [HAPT-01](#hapt-01-piezo-output-check) for manual mapping.

### HAPT-03 automatic number 3 demo rehearsal

- After trying the hands-free Number 3 demo on the glove, Gael reported that
  it worked. The tested app behavior waits five seconds before enabling cues,
  pauses two seconds before repeating a still-needed cue, and ends practice
  output at recognition completion. The operator report does not log each
  timing or cue independently. Device revisions, pulse counts, measured
  latency, and wearer perception are not yet documented for this rehearsal.

### HAPT-04 word cue playback

- This record describes the earlier version that played a cue after a match.
  HAPT-05 describes the current lesson-entry trigger.
- In Developer Mode, a matching attempt plays a preset pattern on the back
  of the hand. Hello uses left, center, right. Please uses left, top,
  right, bottom, repeated three times. The cue illustrates the chosen
  motion pattern. The recognition model continues to determine matches.
- The app requests one pulse at a time using the existing `piezo_demo`
  firmware and highlights the dot confirmed by the glove. The learner can start
  another attempt after the cue stops. Leaving the lesson, backgrounding the app,
  or losing the BLE connection cancels playback.
- Flutter tests checked both sequences and cancellation using simulated
  responses. Live playback for Hello and Please is Not run. Words uses green
  rows and checkmarks for saved completions from the existing progress store.

### HAPT-05 word guidance before practice

- With Developer Mode enabled and a glove running `piezo_demo` connected,
  opening Hello or Please schedules the first cue after three seconds. Hello uses
  left, center, right. Please uses left, top, right, bottom for three laps.
  The hand highlights outputs confirmed by the glove. The next cue starts
  two seconds after the glove confirms the previous cue's stop.
- Starting practice cancels a pending cue. If output is active or being
  stopped, the app waits for the firmware's stop acknowledgment before
  recording. Guidance resumes after a cancelled or unmatched attempt and
  ends after a match. Leaving the lesson, backgrounding the app, or losing
  the glove connection ends automatic replay.
  Word recognition and progress still use the Start attempt / Finish sign flow.
- Flutter widget tests checked the three-second delay, the two-second pause
  after a confirmed stop, early-start cancellation, and replay after a
  cancelled attempt. They also checked that a stale pulse response does
  not start recording and that a match ends replay. All 79 Flutter tests
  and the Android debug build passed. Live verification on the glove is
  pending.

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

### LIVE-04 three-attempt live practice check

Gael reported attempting eight targets three times each with the glove and
app. These are firsthand counts reported in chat. Per-attempt logs, predicted
labels on misses, and confidence scores are unavailable.

| Target | Successful attempts | Total attempts |
| --- | ---: | ---: |
| G | 3 | 3 |
| I | 3 | 3 |
| 1 | 3 | 3 |
| Hello | 3 | 3 |
| Yes | 3 | 3 |
| Please | 3 | 3 |
| K | 1 | 3 |
| X | 1 | 3 |

Use these counts for the eight-target check. The overlap with LIVE-03 is
unknown, so the counts should stay in their respective records. The results
describe one wearer and the selected targets. The cause of the K and X misses
is unknown. Gael confirmed hardware changes and rewiring are unavailable now.

**Configuration reference:** At review, the local branch and `origin/gael`
both pointed to `d1c506b3e165bd6109b6feed7551d9f460984ac3`. That source revision
has Flutter version `1.0.1+2`, the ESP32 `adafruit_feather_esp32s3` and
`piezo_demo` build environments, the recorded 34-class static MLP, and the v2
Hello/Please/Yes TCN. The bundled word model SHA-256 is
`6ed41ddd6b09d727e87cd1b6d299a9a75d5e51615cbad93822c1bb3487c9f7dd`.
The repository's earlier phone reference is Fairphone Gen 6 / Android 15.
The exact APK, flashed firmware environment, phone/OS, and power used for
these attempts have yet to be confirmed.

### USER-01 lab glove tryouts

- **Participants and feedback:** Gael reported two lab tryouts with two friends
  of team members. Gael recalled feedback along the lines of “I don't think
  it's working.” That prompted the team to investigate. Attendance by round,
  signing experience, specific tasks, and assistance are not yet documented.

| Round | Observation reported by Gael | Change or retest |
| --- | --- | --- |
| About one month before November 18 | The team investigated incorrect readings and identified broken flex sensors. | The team bought and installed replacement flex sensors. |
| November 18, 2026 | The team investigated missing sensor readings and attributed them to conductive-thread shorts. | The team switched to discrete wiring. Gael confirmed that a repeat tryout with those participants after rewiring has not been done. |

- **Evidence gap for M6:** The first round's date is approximate. Both rounds
  are documented from Gael's recollection. Gael reported having no photos or
  other records from the tryouts, so timestamped third-party evidence is missing.

### M6 review follow-up for R4

- Gael confirmed that the new IMU was installed, calibrated, and working. The
  app did flag calibration checks, including the earlier recorded diagnostic.
  The cause of the app messages was not determined. Keep the diagnostic
  readings as observations from that run.
- Gael confirmed recognition of more words than the three named in the live
  practice check. The bundle inspected at `d1c506b` lists Hello, Please, and
  Yes. The full label list and corresponding build for the broader coverage
  remain to be confirmed. Use the three named words when reporting LIVE-04.
- Gael confirmed that the team has not done another tryout with the two outside
  participants since the glove was rewired.

### APP-09 Firestore progress sync fix

- November 19, 2026. Android log supplied by Gael showed repeated
  `PERMISSION_DENIED` writes to `users/{uid}/progress/current` after a Flutter
  restart. Expected behavior was for signed-in progress to sync to Firestore.
- The app writes `word_prediction_*` completion IDs, but the rules previously
  allowed only 36 static exercise IDs. Updated
  [the Firestore rules](../flutter_app/firestore.rules) to allow all eight
  curriculum word IDs and 44 total exercises. Authentication and ownership
  checks stayed in place.
- A source check matched the allowlist to all eight Words tab entries and 36
  static targets. Firebase CLI compiled and released the rules to
  `helping-hand-83137`. Phone retry and cloud document readback were not run.

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
