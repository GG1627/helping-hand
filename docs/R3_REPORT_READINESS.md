# R3 preliminary report: evidence and research readiness

Assessment date: October 27, 2026. Repository snapshot inspected: `7e75a4c`.
Assignment: [R3: Preliminary Report](../R3-Preliminary-Report.md).
External references: [R3 source notes](../research/R3_REPORT_SOURCE_NOTES.md).

Drafting follow-up: the first complete [LaTeX report](R3_Preliminary_Report.tex)
and [eight-page PDF draft](../output/pdf/R3_Preliminary_Report.pdf) are prepared.
See the [review/build checklist](R3_REPORT_REVIEW.md) for verification and
outstanding team inputs. The user confirmed **CEN4908C** for the report; retain
the original assignment prompt's CEN3908C wording as source text.

This is a preparation document, not the report or a new test-results record.
Existing results below were inspected, not rerun in this assessment.

## Assessment

The repository has enough technical information and research to start a credible
preliminary report now. Architecture, implementation, collection methods, model
comparison, software verification, and limitations are well documented. The
largest remaining gap is reproducible physical beta and user-study evidence,
followed by a current hardware specification, confirmed schedule, and a more
complete needs/impact discussion. More literature cannot replace those results.

**Current team update, October 27:** Approximately two flex sensors broke,
preventing reliable new acquisition; replacement flex sensors are on order.
The team has received the piezo buzzers needed for the planned haptic subsystem
and ordered a 9-axis IMU to replace the currently used 6-axis unit. The next
couple of weeks are intended for sensor repair, IMU integration and haptic
feedback. The user confirms ten piezo buzzers: one for each of the five fingers
and five in an X formation on the back of the hand. Feedback is intended to
identify a finger needing correction and provide directional guidance. Exact
cue patterns, error estimation, haptic driver design, piezo part number and
integration dates remain to be confirmed. Receipt of buzzers does not establish
an implemented haptic subsystem. No additional completed testing
was supplied in response to the question about work after the October 6 demo.
This is a team-reported blocker and roadmap, not a measured failure rate or a
finding that every historical recording is invalid.

**Work since the October 6 demo:** The user confirms continued PCB design and
work on ways to improve the TCN model during the hardware wait. The October 22
KiCad commits independently document schematic work. The user describes the
PCB work as developing the layout in KiCad. Inspection of the current files
and both October 22 backups shows schematic development, while the board files
contain no placed/routed layout. Report this as KiCad circuit design and board
layout planning in progress, not a completed PCB.
The [current TCN review](R3_TCN_IMPROVEMENT_REVIEW.md) identifies concrete
opportunities from the existing implementation: dataset coverage, gesture
windowing, unknown-motion rejection, sensor/orientation robustness and controlled
tuning. These findings were established on October 27 and are not a retrospective
record of implemented changes or completed experiments. No post-demo accuracy
gain is established.
The broken sensors constrain reliable acquisition and physical validation, not
all engineering progress.

Follow-up: the user expects the replacements to arrive this week (week of
October 26, 2026), as an estimate rather than confirmed delivery. Confirm whether
that estimate also covers the new IMU. The user has now identified the flex
replacement as [Adafruit Short Flex Sensor, product 1070](https://www.adafruit.com/product/1070)
and the ordered IMU as [Adafruit ICM-20948 9-DoF breakout, product 4554](https://www.adafruit.com/product/4554).
The piezo product link remains pending. Specifications and integration references
are recorded in the [source notes](../research/R3_REPORT_SOURCE_NOTES.md).

**Reminder for the next report/hardware session:**

- [x] Receive the replacement flex-sensor and 9-axis IMU product links; supplied
  October 27 and checked against Adafruit documentation.
- [ ] Ask Gael for the piezo-buzzer product name or purchase link, then verify
  its datasheet and driver requirements. Keep actual purchase costs separate
  from the dated retail prices in the source notes.
- [ ] Confirm actual delivery, which finger sensors were replaced and the
  repaired glove's calibration before collecting new model evidence.

**Course dates supplied by the user:** Preliminary report due October 28, 2026;
post-mortem presentations November 19, 2026; showcase tentatively December 3,
2026 around 6 p.m. in the WERT Lobby. The supplied showcase notice says
attendance factors into post-mortem grades. The final written-report deadline
and exact preliminary-report submission time were not supplied. Do not equate
the presentation/showcase dates with an independently confirmed report deadline.

Because the preliminary report is due the next day, use the current evidence
and explicitly report the repair dependency. Do not make its completion depend
on new sensors arriving or on running the planned November experiments.

## Confirmed roadmap and remaining team inputs

| Work item | Team-confirmed status | Information still needed |
| --- | --- | --- |
| Flex-sensor replacement | Approximately two sensors broke; Adafruit Short Flex Sensor #1070 replacements ordered, expected this week | Affected fingers, symptoms/onset, affected recording sessions, actual delivery, paid costs and repair owner. |
| IMU upgrade | Adafruit ICM-20948 9-DoF breakout #4554 ordered; currently used unit described as 6-axis | Old module identity, actual delivery, paid cost, compatible driver/fusion work and integration owner. Improved recognition is a hypothesis, not a measured result. |
| PCB design | User confirms KiCad layout/design work since the demo; October 22 files substantiate schematic work. Current/backup board files have no placed or routed layout. | Owner, remaining circuit/footprint/layout work and review/fabrication dates. |
| TCN improvement | User confirms ongoing investigation; the October 27 source review records specific opportunities in dataset coverage, windowing, rejection and sensor robustness | Team confirmation of any earlier specific work, implemented changes, experiment records and next evaluation plan. Current review findings are not measured improvements. |
| Haptics | Ten piezo buzzers received; planned layout is five finger buzzers plus five in a dorsal-hand X; intended for finger identification and directional guidance | Exact part, driver/power circuit, cue-to-direction mapping, error estimation and how the app will decide to issue feedback. Integration and perception testing remain planned. |
| Preliminary report | Due October 28, 2026; CEN4908C confirmed; first complete LaTeX/PDF draft prepared | Exact submission time, team content review and any cover-page corrections. |
| Final milestones | November 19 presentation; December 3 tentative evening showcase | Final written-report deadline, task owners, internal repair/integration/test dates and final demonstrated feature scope. |

For tomorrow's report, the most useful remaining answers are the specific PCB
and TCN work completed/explored since the demo, haptic cue/error-mapping details,
and what actually happened in the October demo or earlier physical tests
(observed signs, failures, phone, date and any video/log). The remaining piezo
product link has a reminder above; flex/IMU links are recorded. If a detail is
unknown, retain a stated limitation; do not delay the whole draft waiting for it.

Suggested status paragraph: "Since the October 6 demonstration, the team has
continued PCB design and investigation of improvements to the temporal
convolutional network while awaiting replacement flex sensors. Ten piezo
buzzers have been acquired for a planned feedback layout with one actuator per
finger and five in an X formation on the back of the hand. The intended
feedback will identify fingers requiring correction and provide directional
guidance. Sensor replacement, nine-axis IMU integration, haptic cue mapping
and end-to-end validation are the next development steps."

## Coverage against the assignment

| Requirement | Material already available | What remains before submission |
| --- | --- | --- |
| Abstract and introduction | README, original design report, presentation problem/source notes | Write a 200-300-word abstract after the body. Scope the project as beginner ASL practice and feedback; learning improvement is an objective, not a measured result. |
| Scientific background | IMU word-model research, haptic research, source list, real sensor exports, training records | Correct source attributions; explain static versus temporal classification and single-glove limitations. Add educator/community research and a direct TCN reference. |
| Design and interfaces | Firmware, Flutter services/screens, recording protocol, README architecture, current screenshots and hardware photos | Draw an updated architecture with separate ESP32 static and phone word inference. Produce an as-built schematic/pin map and identify the actual IMU and sensor parts. |
| Tools, constraints, standards | PlatformIO configuration, Flutter dependencies, Python training/evaluation code, Firebase rules, BLE/I2C source | Cite official protocol/tool documentation. Separate tools from standards. Document actual power, cost, fit, memory, data-quality, and schedule constraints; do not claim compliance or measurements that were not verified. |
| Needs and impact | Original design report's purpose/impact/risk discussion; partial ASL-club feedback in SME.md | Explicitly address cultural, global, economic, environmental, and social impacts, with drawbacks, privacy and professional obligations. Add Deaf/educator perspectives; distinguish remote comments from physical usability results. |
| Results | Historical alpha checks/videos, September pilot, October static/word offline evaluations, Android recorded replay, software checks | Assemble dated run records with configuration, procedure, expected/observed behavior, evidence and resulting changes. Current live glove/phone tests, latency, user testing and word cloud-sync checks remain Not run. Explain the broken-sensor blocker. |
| Status and timeline | Git history, training/integration records, beta handoffs, October 22 KiCad commits | Reconcile snapshots, identify completed/in-progress/planned/blocked items, and confirm future owners/dates. A commit date records repository work, not successful physical validation. |
| Conclusion and references | Enough material for a preliminary progress summary; source notes supplied separately | Summarize achieved integration, limited evidence, hardware blocker and next milestones. Use one consistent bibliography and cite every external tool/standard or research claim used. |
| Format and submission | Assignment prompt preserved | Letter or A4; 0.5-0.75-inch margins; no source code; at most 3,500 words excluding references/acknowledgements; PDF on Canvas. |

## Internal sources to use first

- [README](../README.md): architecture, historical alpha validation, packet contract,
  known issues. Several sections retain historical assumptions.
- [Original design report](../design_draft/Helping_Hand_Design_Draft.pdf): initial
  hearing-learner need, educational intent, modularity/repair, impact and risk
  analysis. Its proposed frameworks, hardware, database, and feedback are not a
  current implementation specification.
- [Static MLP record](STATIC_MLP_DEMO_MODEL.md): current 34-class recorded model,
  calibration, limited evaluation, firmware export and verification.
- [Word training record](WORD_MODEL_DEMO_TRAINING.md) and
  [integration record](WORD_DEMO_INTEGRATION.md): strongest current word-model
  evidence, implementation details and live-validation boundaries.
- [Current TCN improvement review](R3_TCN_IMPROVEMENT_REVIEW.md): concrete
  development priorities grounded in the implementation, with proposed changes
  kept separate from completed training/validation.
- [T1 alpha plan](T1_ALPHA_TEST_PLAN.md),
  [beta working notes](BETA_TEST_PLAN_WORKING_NOTES.md), and
  [T2 plan source](T2_Beta_Test_Plan.tex): reusable procedures and result fields.
  A plan alone does not show that its tests were executed.
- [Collection protocol](word_data_collection_protocol.md),
  [dataset contract](../backend/data/README.md), and
  [recorded pilot description](../backend/recorded_data/README.md): acquisition,
  metadata, preprocessing, split strategy and evidence limits.
- [SME notes](../SME.md): remote Notre Dame ASL-club discussion with two ASL
  learners, with placeholders and incomplete follow-up. These are useful
  formative comments; they are not a completed Deaf-instructor validation or
  hands-on comfort study. Avoid reproducing participant names unnecessarily.
- [PCB schematic](../pcb/pcb.kicad_sch) and
  [PCB layout file](../pcb/pcb.kicad_pcb): October 22 design work. The layout file
  contains only its file header and no placed/routed board. The schematic uses
  a generic Feather symbol and resistor references for flex/piezo paths; its
  presence does not establish an electrically complete, reviewed, fabricated,
  or integrated haptic design.

## Results that can be described with appropriate limits

| Evidence | Existing result | Correct interpretation |
| --- | --- | --- |
| Historical alpha, September 10, `cce9d38` | README records Flutter analysis, 16 Flutter tests, Android debug build, ESP32 build and 23 backend tests passing | Historical software/build evidence; not fresh beta hardware acceptance. Historical videos show physical streaming, but not a controlled recognition-accuracy experiment. |
| September static pilot | 35 trials, 5,518 rows, one recorded signer ID, neutral orientation; documented observed per-trial rate about 39.7-40.5 Hz | Physical recording/export evidence. Adjacent sensor frames are correlated, and most labels have one trial. No general accuracy claim. |
| October word dataset | 15 whole trials, 1,770 rows, five attempts each for Hello/Please/Yes, all neutral | Dataset is real; the user-reported demo wearer supplied it. Multiple signer IDs do not demonstrate independent participants. |
| Word comparison | Same 9/3/3 trial split; all three candidates correct on 3 validation trials; TCN selected by the predefined size tie-break, 48,324 bytes | Supports a small deployment-oriented comparison. It does not demonstrate that TCN is statistically more accurate than CNN-GRU/LSTM. |
| Selected TCN test | 3/3 reserved trials correct, macro F1 1.00 | Exactly one test example per word. State the counts and scope next to any percentage. No signer-independent, varied-orientation or live accuracy claim. Top-5 is not applicable to three classes. |
| October recorded static candidate | 34 output classes; 52 selected trials/8,093 frames; 4 test trials/615 frames for A/B/1/3 were correct | Evidence covers four priority labels. The other 30 classes are train-only. October 6 reused the split for a calibration regression, so it is not a fresh untouched-test result. |
| October software integration | Word record documents 42 focused Flutter checks, 3 native Android emulator recorded replay checks and APK build; static follow-up documents separate checks | Software behavior and Python/Dart/native parity. Replay of evaluated recordings is not new held-out accuracy or physical BLE evidence. Do not sum overlapping test counts across revisions. |
| Desktop latency | TCN median 0.0488 ms, p95 0.0619 ms for tensor copy/invoke/output copy under the recorded desktop procedure | Excludes BLE, capture, preprocessing and UI; not intended-phone or end-to-end latency. |
| Current sensor blocker | User reports damaged flex sensors and pending replacements | Current constraint, risk and dependency. No new quantitative failure or repair outcome has been measured in this session. |

The CSV row/trial counts, neutral-only conditions, and bundled TCN size/hash
were independently inspected for this assessment. The TCN SHA-256 matches the
training/integration record:
`7664ceacd04b488fc896b04210490e4c0908d852050ad22ed4dc2b80fe561a8a`.
This artifact inspection is not a rerun of training, inference or physical tests.

## Reconcile these differences while drafting

1. **Static baseline versus current default:** The synthetic 36-class MLP is
   preserved, but current firmware defaults to the recorded 34-class MLP.
   J/Z are excluded from that recorded static model. The UI offering a target
   does not demonstrate that the current model can recognize it.
2. **Word scope:** October 2 sections describe UI-only words; October 5 code and
   records supersede that scope for Hello/Please/Yes. Recognition and saved
   completion are implemented for explicit Start attempt / Finish sign attempts.
   Fresh live validation remains Not run; this is not continuous signing.
3. **Input channels:** Word inference uses five raw flex channels plus six
   accelerometer/gyroscope channels: 11 features per time step. Do not repeat
   the ambiguous older phrase "five-channel IMU."
4. **Orientation:** No quaternion normalization is implemented in the demo.
   No varied-orientation result exists in these three CSV exports. Distinguish
   sensor mounting variation from meaningful palm orientation in ASL; removing
   all orientation information could remove useful sign distinctions. Treat
   this as a design risk to test, not a proven benefit of normalization.
5. **Original design versus implementation:** The original report proposes
   React Native, SQLite, a 400 kHz I2C bus, and haptic correction. Current code
   uses Flutter/Dart, local JSON plus Firebase, Arduino/C++ via PlatformIO, and
   a 100 kHz I2C bus. The static model runs on ESP32; the word TCN runs on phone.
   Refresh throughput estimates for the current packet size/rate rather than
   copying the original 2-5 kbps target.
6. **Haptics:** The user now confirms that ten piezo buzzers have been acquired:
   five finger buzzers and five in an X on the back of the hand, intended to
   identify fingers needing correction and provide directional guidance.
   The research document opens with a nine-piezo proposal while later sections
   recommend staged LRA evaluation; the October presentation proposes ten piezo
   elements. Treat the piezo choice/acquisition as current team status and the
   older LRA advice as prior research. Confirm exact mounting, selected part,
   driver, direction/pattern mapping and error estimation with the hardware
   owner. A predicted word alone does not specify a finger-level corrective
   direction. `ESP32/src/piezo.cpp` remains a TODO;
   no implemented haptic feedback or learning improvement should be claimed.
7. **Hardware identity and drawings:** The old image depicts an ESP32-C3/
   LSM9DS1 concept. Current firmware targets Feather ESP32-S3 and an MPU-style
   accelerometer/gyroscope. New KiCad work is a draft, not automatically an
   as-built replacement. Identify the IMU/module before citing its datasheet
   or claiming magnetometer-stabilized yaw.
8. **Current sensor state:** Freeze known-good historical artifacts and flag
   suspect recordings by acquisition session. Do not invent missing channels
   or change labels to compensate for damaged sensors. Replacement sensors
   can change calibration and the model's input distribution.
9. **Dates and course metadata:** Proposed presentation roadmap dates are not
   confirmed completion dates. The user confirmed CEN4908C for this report;
   preserve CEN3908C in the original assignment transcription.

## Missing information, in priority order

### Needed to write accurately now

- Report cutoff, final written-report deadline, current team names and milestone
  owners/target dates. Preliminary due date and presentation/showcase dates are
  recorded above; retain the showcase's tentative status.
- Current sensor fault history: affected fingers, raw symptom/evidence, onset,
  which recordings are suspect, actual replacement delivery date
  if known, and repair owner. The user's October 27 update supplies the blocker
  but not these details.
- Any actual alpha/beta outcomes not yet linked from the repo: dated logs,
  original recordings, tester/configuration, failed cases and follow-up changes.
  If unavailable, state the documented evidence and missing fields honestly.
- As-built hardware inventory/pin map, IMU identity, supply/battery and voltage
  ratings, glove size/mass, and a simple bill of materials with actual costs
  where available. Explain unavailable measurements rather than guessing.
- Confirmed outreach facts and consent/data-sharing arrangements. Public
  pseudonymous recordings still warrant checking permission and access scope.

The ordered replacement parts are identified, but the currently installed old
IMU still needs identification. The existing MPU-style register code is not
an ICM-20948 driver; driver migration, units/axis checks, magnetometer acquisition
and fusion remain planned. Current word inputs contain no magnetic channels.
Keep acquisition, orientation estimation and model-input changes distinct in
the design/status sections.

### Measurements after replacement sensors arrive

These are proposed next runs, not completed results or newly imposed assignment
requirements. Reuse the existing T1/T2 procedures and record Pass/Fail/Not run.

1. Inspect/replace sensors; record raw straight/bent ranges for every finger,
   noise, clipping, mounting and wiring. Check that the IMU responds. Freeze the
   repaired configuration and calibration before acquisition.
2. Verify cold standalone boot, scan/connect, ten-minute delivery rate, packet
   gaps/order/truncation, disconnect/reconnect and complete CSV/manifest export
   on the named target phone. The serial startup wait is an existing code risk.
3. Collect fresh static and Hello/Please/Yes attempts on the repaired glove;
   compare against the frozen old model to quantify distribution change. If
   tuning or retraining is needed, reserve a new untouched final evaluation set.
4. Include wrong trained words, idle/unrelated motion and interrupted attempts.
   Measure false completion as well as correct recognition: the word model
   has no rest/unknown class, and an 80% softmax threshold does not establish
   reliable rejection or calibrated correctness probability.
5. Measure intended-phone latency with declared start/stop events. Separate
   capture duration, preprocessing/model setup, invocation, and visible feedback;
   report repeated measurements and a distribution, not one emulator timing.
6. Exercise progress restart, account isolation, offline recovery and cloud sync
   for both static and word completions on the current build.
7. Run a small documented external-user task study and obtain fluent ASL/Deaf
   educator review of targets/instruction. Remote image/video feedback cannot
   establish worn comfort, natural signing or learning improvement.

For the planned 9-axis upgrade, first establish a repaired sensor baseline,
then evaluate the new IMU and fusion with haptics disabled, followed by
haptics-on/off sensor checks. If the new sensor supports both fusion modes,
comparing 6-axis versus 9-axis fusion on that same hardware helps isolate the
magnetometer's contribution. An old/new hardware comparison also changes
sensor quality and mounting, so any improvement cannot automatically be
attributed to the extra axes. See the IMU upgrade discussion in the source notes.

For any learning-effectiveness claim, a separate study with defined learning/
retention outcomes and an appropriate comparison is needed. Such a study is
not necessary to report a preliminary prototype and its honest limitations.

## Impact topics to develop

| Dimension | Project-specific discussion | Evidence still needed for stronger claims |
| --- | --- | --- |
| Cultural | ASL has its own grammar and nonmanual features. Use authentic SME-reviewed instruction; avoid equating three recognized words with ASL competence. | Fluent/Deaf educator input and reviewed instructional content. |
| Global | The architecture may be reusable, but ASL is not universal. Other sign languages require different vocabulary, linguistic review and data. | Language-specific data and evaluation before claiming portability. |
| Economic | Hardware and phone requirements affect access; sensor replacement adds cost and downtime. Local inference may reduce inference-server dependence. | Actual BOM, replacement cost and maintenance assumptions; no affordability/savings claim without comparison. |
| Environmental | Replaceable parts could reduce whole-device disposal, but failed flex sensors create waste; batteries/electronics require appropriate disposal. | Actual construction/repairability and power measurements; no quantified sustainability benefit yet. |
| Social | Additional independent practice and visible progress are intended benefits. Incorrect feedback could reinforce errors or frustrate learners; fit/handedness/accessibility can exclude users. | User-task observations and learning measures, with population limits. |
| Ethical/professional | Consent, pseudonymous data, restricted sharing, honest performance claims, safe wearable construction and consultation with the language community. | Confirmed handling practices, failure records and evidence that safeguards were exercised. |

## Practical drafting order

1. Freeze the report cutoff and create one claim/evidence ledger from the tables
   above. Begin Design, Results and Status from the strongest records.
2. Write Background/Introduction using a compact set of relevant primary
   studies and the verified source notes; correct mismatched citations first.
3. Connect the original need/impact analysis to current limitations, sensor
   failures and stakeholder feedback; add explicit global/environmental coverage.
4. Add a timeline with completed software milestones, October 22 schematic
   work, the current replacement-sensor dependency, and team-confirmed next dates.
5. Write the conclusion and abstract last. A useful 3,300-word body budget is:
   abstract 250; introduction 250; background 450; design 600; tools/constraints/
   standards 300; impact 450; results 500; status/timeline 350; conclusion 150.
   This budget totals 3,300 words and leaves 200 words below the assignment cap.

The report can proceed during the hardware wait. Any tests that remain unrun at
submission should stay explicitly Not run, with the dependency and next step
explained. Historical pilot/offline results remain useful when their original
hardware, split and scope limitations accompany the claims.
