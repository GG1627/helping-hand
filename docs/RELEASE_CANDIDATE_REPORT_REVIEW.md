# Release candidate report revision notes

Recorded November 12, 2026. This file inventories the existing M5 documents and
sets the reference for a later report revision; it is not the revised report.

**Current scope:** Gael authorized research for the two-page report on November
12, including reviews of the assignment, earlier documents, and repository
evidence, with subagents as useful. Research is complete below. Drafting and
exporting the updated submission report remain the next stage, awaiting Gael's
instruction. The October PDFs and their source documents have not been changed.

## Gael's scope and status clarification, November 12

- The report will cover work through **October 28, 2026**, rather than later
  November improvements.
- Gael now retrospectively confirms that the replacement flex sensors and
  upgrade parts had arrived by that deadline. Driver/software support had been
  added, but the new components had not been soldered into the glove circuit.
  This resolves the earlier receipt uncertainty as a team-reported clarification;
  it does not establish installation, calibration, or physical validation.
- Gael reports PCB design work in KiCad by the deadline; the board had not been
  printed/fabricated. The team is currently waiting for printing. The committed
  repository contains a schematic and an empty board file, so describe **KiCad
  circuit/PCB design work with fabrication and assembly pending**. Do not infer
  completed routing or a fabrication-ready design from the committed files;
  a newer off-repo layout has not been inspected.
- Gael does not recall additional tests or fixes and asked to use the earlier
  M5 records. No new test outcome or bug resolution was supplied. Use the
  documented IMU software checks and earlier integration/demo evidence with
  their dates and limits.
- Gael recalls mostly software work while waiting for parts, including TCN
  improvement work. The October records substantiate **review/planning of TCN
  improvements**, alongside actual IMU drivers and piezo control code. They
  establish no newly trained TCN, deployed model replacement, or measured accuracy
  improvement after beta. Do not turn the broad recollection into those claims.

These clarifications are sufficient to proceed with a factual report using the
existing evidence; no additional general research is needed. Drafting remains
the next stage, not part of this clarification update.

## Correct assignment

Use [M5: Release Candidate](../M5-Release-Candidate.md), supplied by Gael on
November 12. Gael reported that the earlier release candidate document used the
wrong assignment reference, as had the alpha report before its correction.
The earlier incorrect reference has not been identified in this inventory.

The supplied M5 assignment requires:

- An approximately 1–2 page PDF report relating completed work to the
  specification and rubric criteria, with the project repository link.
- A polished beta refinement with all major elements integrated, complete and
  usable, clearly documented bugs, and no showstopper bugs.
- Coverage of Interface, Navigation, Perception, Responsiveness, Robustness,
  Consistency, and Aesthetic Rigor, including refinements informed by testing.
- An in-person stakeholder presentation and defense in the week following the
  assigned due date; the team must arrange the meeting.
- Repository source code, hardware designs, and a README describing completed
  work, architecture, and all known bugs.
- Time-stamped third-party effort evidence, such as remote repository pushes
  and online documents. Action logs alone do not qualify. The stated effort
  expectation is approximately 130 hours per member / 390–650 person-hours per
  team, excluding design documentation; this expectation is not proof of hours.

The prompt prints **CEN3908C**; existing project reports print **CEN4908C**.
Preserve that distinction until choosing the corrected report's course heading.
The supplied text contains no due date or separate scoring rubric. Existing
October documents state October 28, 2026 as the milestone date.

## Existing files found in this repository

| File | Contents and historical status |
| --- | --- |
| [M5_Work_Outline.pdf](../output/pdf/M5_Work_Outline.pdf) | **2 pages**, titled “Helping Hand Release Candidate / M5 Milestone Work Outline.” Summarizes IMU firmware, piezo control, PCB planning, sewing/insulation preparation, replacement sensors, TCN review, software checks, and unrun physical checks. Closest existing artifact to the requested brief report. |
| [RELEASE_CANDIDATE.pdf](../output/pdf/RELEASE_CANDIDATE.pdf) | **20 pages**, titled “Helping Hand - M5 Release Candidate.” Extended README-style documentation containing architecture, learning flow, rubric status, setup, evidence, hardware plans, and known bugs. Supporting material; its length exceeds the requested brief report. |
| [M5_Work_Outline.md](../M5_Work_Outline.md) | Editable work-outline source. Now includes a November 5 parts-arrival follow-up absent from the October PDF. |
| [RELEASE_CANDIDATE.md](../RELEASE_CANDIDATE.md) | Editable extended release candidate document. Now includes November 5 and November 6 follow-ups absent from the October PDF. |
| [README.md](../README.md) | Root project README with release candidate summary, architecture, and known issues, plus later development updates. It is a living document, not a frozen October report. |

Both PDFs were added in commit
[`5548a7b`](https://github.com/GG1627/helping-hand/commit/5548a7bd3d6eed13d2774cabc64c89dbecd22837),
“Added the PDFs to our PDF folder,” timestamped October 28, 2026,
21:10:57 -04:00. PDF metadata records creation at 21:09:50 -04:00 for the work
outline and 21:09:44 -04:00 for the extended document that day.
Their headings identify
[`ff6a9ab`](https://github.com/GG1627/helping-hand/commit/ff6a9ab763f12f60e3a327d0df4f00a8784894b8)
as the release candidate implementation snapshot; that is distinct from the
later commit adding the PDFs.

**Snapshot correction found during research:** `ff6a9ab` predates the actual
ICM-20948 driver addition in `794f695` later that evening. The host checks and
work outline followed in `f8c6eaf`. For the complete October 28 artifact state,
use `5548a7b` and the specific implementation commits below; do not claim that
all work described in the PDFs was already present in `ff6a9ab`.

The latest source edits found during this inventory were November 5 for
`M5_Work_Outline.md` (`ea38c33`) and November 6 for `RELEASE_CANDIDATE.md`
(`2c5c9e8`). Use the saved PDFs or October Git versions when reviewing what the
October artifacts actually said.

Repository presence and commit metadata identify saved artifacts; they do not
confirm which files were uploaded to Canvas, a successful submission, stakeholder
meeting completion, remote push timestamps, or actual hours worked. No submission
receipt was found in the reviewed repository documents. If Gael's submitted
copies differ, obtain those copies before treating these as exact submissions.

## Initial implications for the rewrite

- The two-page outline is a useful starting source, but its work-list format
  does not explicitly organize the report around all seven criteria. Include
  a clear repository URL: <https://github.com/GG1627/helping-hand>.
- The longer document already contains a rubric table and bug list. Condense
  relevant, supported evidence into the brief report instead of copying the
  full README or treating planned improvements as completed work.
- The October artifact lists a potentially blocking USB Serial startup wait,
  static practice completing after leaving the page, BLE/power issues, and
  faulty flex readings. It also describes unfinished PCB work, haptic integration,
  and new-IMU installation/testing. These prevent an unqualified claim that all
  features were complete or that the artifact met the no-showstopper requirement.
  State the actual limits; do not erase them to match the assignment wording.
- Distinguish alpha evidence, beta carryover, M5 changes, and later November
  work. Software/emulator checks do not establish fresh glove performance,
  external-user usability, physical haptic output, or current hardware reliability.
- Identify the beta feedback or observed defect behind each refinement when
  evidence exists. Do not invent beta test results, hours, or stakeholder outcomes.
- Preserve both October PDFs when creating the corrected report under a distinct
  filename. Rewriting and exporting that report have not been done in this
  inventory session.

## Research completed November 12: material ready for drafting

Three read-only reviews covered the original M5 sources, firmware/hardware, and
app/models. The main review also inspected the corrected alpha report, R3
observations/review notes, SME feedback, PCB provenance, packaged word model,
recorded CSVs, and Git chronology. No new implementation, training, hardware
tests, or replacement report was produced. Existing-source review and artifact
inspection are the basis of the findings below.

### What the two-page report needs to do

Explain the retained integrated system briefly, identify actual refinements
after beta, relate that work to the seven named criteria, summarize relevant
verification, and disclose bugs/incomplete work. Include the repository URL.
The stakeholder defense and repository documentation are separate assignment
deliverables; preparing them is outside this report-only task. The assignment
does not prescribe an abstract, literature review, detailed architecture chapter,
pin listing, or reproduction commands for the brief report.

### Reusable evidence by criterion

| Criterion | Useful supported material | Best source locations and boundary |
| --- | --- | --- |
| Interface | Account flow, branded Home and learning pages, target selection, separate practice screens, saved progress indicators. | `RELEASE_CANDIDATE.md:114`; `docs/BETA_BUILD_STATUS.md:14`; `docs/APP_DESIGN_GUIDE.md:19`. Implemented behavior and software checks; formal accessibility/external-user usability remain unrun. |
| Navigation | Picker-to-practice flow, Back, Retry, and clear recognition availability for unsupported words. | `RELEASE_CANDIDATE.md:99`; `docs/WORD_DEMO_INTEGRATION.md:30`. Static completion after Back remains a known defect; do not claim every control is fully tested. |
| Perception | Prediction/confidence, hold progress, word results, BLE state and save/sync feedback. | `RELEASE_CANDIDATE.md:116`; `docs/WORD_DEMO_INTEGRATION.md:37`. Visual feedback exists; corrective haptics and user cue-perception validation do not. |
| Responsiveness | Asynchronous BLE/Firebase, background word inference, elapsed-time piezo control. | `flutter_app/lib/services/tflite_word_classifier.dart:56`; `flutter_app/lib/services/ble_connection_service.dart:58`; `ESP32/src/piezo.cpp:61`. Intended-phone latency and sustained streaming are unmeasured. |
| Robustness | Local-first saved progress, malformed-state handling, word packet/timing checks, cancellation on disconnect/Back/backgrounding, static regression baseline retained. | `flutter_app/lib/services/progress_repository.dart:280`; `docs/WORD_DEMO_INTEGRATION.md:48`; `RELEASE_CANDIDATE.md:118`. These controls do not establish a crash-free or fully stress-tested physical build. |
| Consistency | Static matching at >=80% confidence, >=750 ms and >=5 packets, max 250 ms gaps; word completion requires matching top prediction at >=80%; progress scoped by Firebase UID. | `flutter_app/lib/services/stable_prediction_tracker.dart:40`; `flutter_app/lib/services/word_practice_controller.dart:22`; `docs/WORD_DEMO_INTEGRATION.md:37`. Thresholds are acceptance rules, not measured accuracy or unknown-motion rejection. |
| Aesthetic Rigor | Shared palette, typography and components, bundled fonts, narrow/large-text/reduced-motion software layout checks. | `docs/APP_DESIGN_GUIDE.md:19`; `docs/WORD_DEMO_INTEGRATION.md:100`. Final glove finish, fit, comfort and all-device appearance are unvalidated. |

### What was new, retained, or later

| Date / commit | Material useful to the report | Classification |
| --- | --- | --- |
| September alpha; corrected alpha report saved November 10 | Sensor -> ESP32 static inference -> BLE -> Flutter feedback -> local progress -> Firestore architecture. | Background/carryover; the newly written alpha report is not new M5 implementation evidence. |
| October 1–2: `4259269`, `9c5caab`, `d581d19` | Accounts, shared visual design and dedicated learning routes. | Beta carryover. |
| October 5–6: `c5f849b`, `66df6b2` | Recorded 34-class static model, preserved 36-class baseline, local Hello/Please/Yes TCN, saved word completion and static calibration update. | Beta-era carryover. |
| October 22: `1dcc188`, `3983cfc` | KiCad schematic development and board-layout planning. | M5 progress; board source has no placed/routed design. |
| October 28, 19:47: `be9ae3a` | Ten piezo assignments, safe-off startup, timed one-output PWM control and pin conflict checks. | M5 firmware implementation; no automatic correction trigger or validated physical cue. |
| October 28, 20:32: `794f695` | ICM-20948 accelerometer/gyro and AK09916 magnetic sampling, retaining legacy IMU support and retry behavior. | M5 firmware implementation; magnetic values initially serial-only, no fusion/model input change. |
| October 28, 20:34: `f8c6eaf` | Simulated-I2C checks and work-outline record. | M5 software verification; full board build then timed out installing a missing tool, physical new-board testing unrun. |
| October 28 artifact cutoff: `5548a7b` | Saved two-page and twenty-page PDFs. | Complete historical document snapshot, later than the named `ff6a9ab` snapshot. |
| November 5–6: `ea38c33`, `7cf20c7`, `4890f24`, `2c5c9e8`, `b4daab3` | Magnetic BLE/export, calibration tooling, configurable preprocessing, bounded Serial startup, replay evaluation and training augmentation. | Later software work; keep separate unless Gael chooses to include post-October work. No new physical recognition result established. |

Other M5 material from `M5_Work_Outline.md:40`, `:48`, `:59`, `:64`:
conductive-thread practice, sensor placement/fabric-insulation planning,
replacement-flex planning, and TCN improvement review. Compress these if used.
They do not establish a finished sewn glove, validated circuit, or improved model.

### Strongest additional evidence outside the old M5 work list

- **Historical physical integration:** [demo observations](R3_DEMO_OBSERVATIONS.md),
  lines 8 and 20–25, record Gael's October 28 retrospective account of the October
  5–6 NSC-lab demonstration on the documented Fairphone Gen 6 / Android 15.
  A/B/C/L/S/U/Y completions, attempts at digits 0–9, Hello/Please recognition and
  completion, and green progress indicators checked against actual Firebase
  records were reported. No controlled denominators, exact builds, original
  accuracy logs, or restart/cross-device results were supplied. Describe this as
  a team-reported demonstration, never measured learning or an accuracy rate.
- **Documented software verification:** [word integration](WORD_DEMO_INTEGRATION.md),
  lines 98–105, records 42 focused unit/widget/parity checks, three native Android
  recorded replay checks on a Pixel 8 API 36 emulator, layout checks and a debug
  APK build. These support retained software integration, not new M5 hardware
  validation. Do not combine dated test counts into one supposed RC acceptance run.
- **Small word-model evaluation:** [training record](WORD_MODEL_DEMO_TRAINING.md),
  lines 12–23 and 45–70: 15 real attempts, five per word, one reported wearer,
  neutral wrist; 9/3/3 whole-trial split. TCN, CNN-GRU and CNN-LSTM each got
  three validation attempts correct. TCN won the size tie-break at 48,324 bytes
  and classified three reserved test attempts correctly, one per word. If space
  permits, use counts and scope instead of a headline 100% accuracy claim.
- **Static model scope:** [static record](STATIC_MLP_DEMO_MODEL.md), lines 7–19,
  53–85: default recorded model covers 34 classes, excluding J/Z; the original
  synthetic 36-class model is preserved. Held-out static results concern A/B/1/3
  only, and repeated calibration checks are regression evidence. Do not claim
  all-class, other-wearer or repaired-glove accuracy.
- **Defect/feedback to refinement links:** broken thumb/index readings motivate
  replacement and recalibration planning; the incomplete physical integration
  motivates PCB/mounting work; long gestures and limited examples motivate the
  model review. [SME notes](../SME.md), lines 25–41, also record remote ASL-club
  feedback about orientation, repetition and haptics. This is a remote walkthrough
  with incomplete fields, not a formal worn-glove usability or comfort study.
- **PCB provenance:** [schematic notes](../pcb/exports/README.md), lines 10–30,
  identify the October 22 source and unfinished generic pin/driver/net-label
  details. Use schematic development as progress, not fabrication readiness.

Read-only artifact checks in this session independently reconfirmed the packaged
TCN's 48,324-byte size and documented SHA-256, plus source CSV counts:
`trials.csv` 5,518 rows / 35 trials; `trials_1.csv` 1,770 rows / 15 trials;
`trials_2.csv` 3,263 rows / 21 trials. These checks do not rerun model evaluation.

### Guardrails and readiness

There is enough supported material to write the two-page report without more
general research or implementation. Prioritize the actual system, M5 changes,
criterion coverage, concise verification and explicit remaining issues; omit
detailed pin maps, model hyperparameters, lengthy research and setup instructions.

The evidence does **not** support declaring the October artifact nearly bug-free,
free of showstoppers, physically validated, fully haptic-integrated, or PCB-complete.
Retain the Serial startup defect for the October scope, static completion after
Back, BLE/power issues, damaged flex inputs and outstanding integration/testing.
November's Serial fix must be labeled later, and physical battery startup is
still unrun. Exact IMU-arrival statements conflict across October documents;
avoid unnecessary receipt-date claims. Actual hours, formal external-user
testing, complete account/recovery checks and stakeholder defense are unproven.

Gael has confirmed the October deadline scope; the research retains November
facts separately as background only. No later work has been silently attributed
to October. The
prompt's course identifier differs from CEN4908C in the project; R3 review notes
record CEN4908C as previously confirmed by the user.

## Original PDF fingerprints

SHA-256 recorded for identifying the historical copies:

```text
output/pdf/M5_Work_Outline.pdf
a624239a5b7a6492e42ee4ac8708f253a0a28e2e76851bf448ac5ce13bcdbf83

output/pdf/RELEASE_CANDIDATE.pdf
85e0473c58e219917b86a9ae3900c1bb5c75694da2225b09793e1aa892b7957b
```
