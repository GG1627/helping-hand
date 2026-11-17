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
- [ ] **BUILD-2:** Record firmware/app revisions, any uncommitted changes,
  phone/OS, model filenames/hashes, labels, calibration, and preprocessing.
- [ ] **BUILD-3:** Take clear final photos of the whole glove, PCB, sensor
  attachment/insulation, IMU mounting, and ten actuator positions. Label photos
  as actual assembly or proposed placement as appropriate.
- [ ] **BUILD-4:** Record actual dates of major interface, hardware, firmware,
  model, and integration changes. Preserve earlier planned dates separately.
- [ ] **BUILD-5:** Explain strategies used to finish the work: division of work,
  staged integration, parallel hardware/software preparation, troubleshooting,
  scope decisions, and dependencies. Include specific examples that happened.
- [ ] **BUILD-6:** Complete the feature inventory below, including unfinished
  goals and their effect on the final system.

| Feature / goal | Actual final state | Completed date, if applicable | Evidence / record ID | Remaining limit and effect |
| --- | --- | --- | --- | --- |
| PCB fabrication, assembly, and glove integration | Not yet documented | | | |
| Five working flex sensors and calibration | Not yet documented | | | |
| New ICM-20948 integration and calibration | Not yet documented | | | |
| A-Z recognition, including moving J/Z | Intended scope; final coverage not yet documented | | | |
| 0-9 recognition | Intended scope; final coverage not yet documented | | | |
| All eight app words | Intended scope; final vocabulary/coverage not yet documented | | | |
| Ten actuator outputs | Not yet documented | | | |
| Automatic finger bend/straighten guidance | Intended behavior; final state not yet documented | | | |
| Word-motion guidance / demonstration patterns | Design undecided in report discussion | | | |
| App instruction, navigation, and feedback | Final-build checks not yet documented | | | |
| Accounts and saved progress | Final-build checks not yet documented | | | |
| Battery-powered operation | Goal; USB is a possible fallback | | | |

The last reviewed handoff describes a 34-class static model excluding J/Z and
Hello/Please/Yes phone recognition. This is a baseline, not confirmation of the
latest work in other sessions. Verify both the eight-word app vocabulary and
the deployed labels before updating the inventory.

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
- [ ] **HAP-5:** Check whether users identify the finger and intended direction.
  Record the instruction given, cues presented, responses, and correct/total
  counts. Distinguish audible hints from tactile perception if relevant.
- [ ] **HAP-6:** Describe the final word-motion behavior, if any. Separate
  demonstration playback from feedback based on detected motion errors.
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
| | | | | | |

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
- No final report prose/document created in this step; no new tests executed.
- Next useful update: add a session record when assembly, calibration, haptic
  implementation, or testing produces actual evidence, and link its checklist IDs.
