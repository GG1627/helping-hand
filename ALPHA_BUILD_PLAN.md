# M3 Alpha Build Completion Plan

**Course:** CEN3908C  
**Project:** Helping Hand  
**Target milestone:** M3 Alpha Build  
**Due:** September 11, 2026  
**Last updated:** September 10, 2026

## 1. Alpha objective

Deliver and document a stable vertical slice of Helping Hand that preserves the
previously working letter/number classifier while demonstrating the foundation
for the next word-recognition phase.

The minimum alpha should let a reviewer:

1. power the glove;
2. connect it to the Flutter app over BLE;
3. see live sensor data and a letter/number prediction;
4. complete at least one guided learner exercise with clear visual feedback;
5. close and reopen the app and see saved progress;
6. record, save, and export one labeled word trial; and
7. validate that export with the backend CLI.

Dynamic word classification does **not** need to be represented as trained or
validated unless enough real data has actually been collected and evaluated.
The alpha must clearly distinguish a working static baseline, a working word
data-collection pipeline, and future word-model training.

## 2. Current evidence and status

| Area | Current evidence | Alpha status |
| --- | --- | --- |
| Static letter/number classification | Team reports that the glove classified letters/numbers and displayed results in the app at the end of the previous semester. Current firmware still embeds and invokes the 36-class TFLite model. | Previously demonstrated; revalidate on current hardware/app build. |
| ESP32 firmware | Current PlatformIO build succeeds. Sensor packets include IMU, flex inputs, prediction, confidence, sequence ID, and device time. | Implemented; physical smoke/stress test pending. |
| Flutter app | Android debug APK builds, `flutter analyze` passes, and all six current Flutter tests pass. | Implemented; current-phone physical validation pending. |
| BLE interface | Scan/connect/reconnect, packet parsing, live telemetry, and status messages exist. | Implemented; sustained physical validation pending. |
| Progress UI | Alphabet and number tiles update dashboard progress. | Implemented only in memory; state is lost on restart and is not driven by classifier success. |
| Word recording | The Record Signs tab can label, record, review, discard, save, and export CSV/JSON sessions. | Implemented and unit-tested; physical phone/share validation pending. |
| Word preprocessing | Validation, resampling/window foundations, deterministic splits, and evaluation-report code exist. Fifteen non-TensorFlow backend tests pass in the currently available system Python environment. | Implemented; clean environment and exported-device sample validation pending. |
| Word models | TCN, CNN-GRU, and CNN-LSTM code and conversion smoke tests exist. | Architectures only; no real word model has been trained, selected, or deployed. |
| Firebase | Firebase packages, generated options, and `Firebase.initializeApp()` exist. | Configuration scaffolding only; no active auth, database reads/writes, rules, or persistence service. Existing project ownership is unavailable. |
| Haptic feedback | Actuator, placement, protocol, power, and test research is documented. | Research only; no glove haptic circuit or runtime exists. |
| Documentation | Root README describes the architecture and build commands. | Substantial, but alpha evidence, Firebase claims, schematic accuracy, and implemented-versus-planned labels need revision. |

## 3. Scope decisions

### Required for the alpha

- Preserve the working static 36-class classifier as the regression baseline.
- Revalidate at least a small representative set of letter/number gestures.
- Connect the physical glove from the Flutter app and show live packets.
- Add one classifier- or IMU-driven learner exercise with visual feedback.
- Persist and restore learner progress.
- Complete the word recording/export/validation path once on a real phone.
- Provide repeatable build, run, demo, and validation instructions.
- Record honest automated and physical test evidence.

### Stretch goals only after the required path is stable

- Synchronize progress to a new team-controlled Firebase project.
- Add temporary phone vibration for success/error feedback.
- Run a small real word-data pilot.
- Produce a non-reportable word-model pipeline smoke run.

### Explicitly outside the minimum alpha

- A validated dynamic word-recognition model.
- Reported word accuracy from synthetic fixtures.
- Five- or ten-actuator glove haptics.
- Quaternion/yaw normalization without confirmed hardware support.
- A polished production account system.

If the approved course design explicitly promised glove-mounted haptics as an
alpha requirement, the team must either implement one safe demonstrative
actuator channel or confirm the deferral with the instructor. Do not imply that
the researched multi-actuator design is installed.

## 4. Deadline-first execution plan

Work in this order. A later phase must not destabilize an earlier passing gate.

### Phase A: freeze and reproduce the build

- [ ] Record the exact branch and commit used for the alpha.
- [ ] Confirm the intended Android phone and ESP32 board.
- [ ] Create a clean Python environment and install `requirements.txt`.
- [ ] Run the complete backend test suite, including TensorFlow-dependent tests.
- [ ] Run `flutter analyze` and `flutter test`.
- [ ] Build the Android debug APK.
- [ ] Build the ESP32 firmware.
- [ ] Save command output or summarize it in the validation report.

**Gate A:** Both build artifacts are produced from documented commands, and the
test results are recorded without hiding skipped or unavailable tests.

### Phase B: revalidate the historical baseline

- [ ] Flash the current firmware.
- [ ] Boot the glove without opening a serial monitor.
- [ ] If startup blocks on `while (!Serial)`, replace the unlimited wait with a
  bounded diagnostic delay and retest battery/USB operation.
- [ ] Connect from the actual Flutter app, not only nRF Connect.
- [ ] Confirm complete packets, monotonically increasing sequence IDs, and a
  stable observed packet rate.
- [ ] Verify flex readings change in the expected direction for all installed
  sensors.
- [ ] Test a small set of historically reliable classes, for example two
  letters and two numbers.
- [ ] Record predicted label, confidence, expected label, success/failure, and
  any mounting/calibration conditions.
- [ ] Disconnect and reconnect at least three times.
- [ ] Stream for at least ten minutes while watching for resets, freezes,
  parser errors, packet gaps, and app crashes.

**Gate B:** At least one real letter/number classification is visible in the
current Flutter build, or a documented hardware problem and fallback exercise
has been selected.

### Phase C: complete one learner-facing vertical feature

Preferred path when the static classifier is reliable:

- [ ] Let the learner select one supported letter or number.
- [ ] Display the target, current prediction, confidence, and connection state.
- [ ] Require a stable matching prediction for a short interval rather than
  accepting one packet.
- [ ] Show clear `correct`, `try again`, and disconnected/error states near the
  practice control.
- [ ] Mark the item learned only after sensor-driven success.
- [ ] Provide reset/retry and return-to-list controls.

Fallback path when flex classification cannot be restored in time:

- [ ] Build one wrist-alignment exercise from the existing live IMU roll value.
- [ ] Provide calibration, direction-to-correct feedback, a tolerance band,
  and a stable-hold requirement.
- [ ] Label it as the demonstrative alpha learner exercise rather than a word
  classifier.

Optional after visual feedback works:

- [ ] Add phone vibration as a temporary alpha success/error cue.
- [ ] Label phone vibration separately from future glove-mounted haptics.

**Gate C:** A user can complete the exercise from glove input without manually
toggling a learned tile.

### Phase D: make progress persistent

Do not make Firebase the only path required to pass the alpha demo.

- [ ] Add a `ProgressRepository` abstraction.
- [ ] Persist learned letters, learned numbers, and the alpha exercise result
  locally, for example with `shared_preferences` or an app-private JSON file.
- [ ] Load progress before or during the main shell startup.
- [ ] Display loading, saved, and save-failure states where appropriate.
- [ ] Close the app fully, reopen it, and verify progress is restored.
- [ ] Add tests for save, restore, malformed state, and reset.
- [ ] Remove or replace hard-coded progress/streak values that look like real
  user data.

**Gate D:** The demonstrated learner result survives a complete process restart
and remains visible through the app interface.

### Phase E: establish a controlled Firebase project

#### Project-owner tasks

- [ ] Create a Firebase project owned by a responsive team member.
- [ ] Register the Android package `com.example.flutter_app` for the current
  alpha; avoid changing the package name during the deadline unless necessary.
- [ ] Enable Cloud Firestore.
- [ ] Enable anonymous authentication if the alpha has no account UI.
- [ ] Add the necessary teammates and instructor access at appropriate roles.
- [ ] Do not create or share a service-account private key for the Flutter app.
- [ ] Log in locally with the Firebase CLI; do not send credentials through
  chat or commit them.

#### Repository tasks

- [ ] Install/configure the Firebase CLI and FlutterFire CLI.
- [ ] Run `flutterfire configure --project <project-id> --platforms android`
  from `flutter_app/` and review the generated changes.
- [ ] Add an authentication/progress service rather than placing database calls
  directly in widgets.
- [ ] Store only the small progress document needed for the alpha.
- [ ] Suggested path: `users/{uid}/progress/current`.
- [ ] Suggested fields: learned letters, learned numbers, completed exercise,
  schema version, and server update time.
- [ ] Add and deploy restrictive Firestore security rules keyed to the signed-in
  user's UID.
- [ ] Show sync status and retain the working local copy when cloud sync fails.
- [ ] Test first launch, repeat launch, offline launch, denied write, and cloud
  reload.
- [ ] Update README setup instructions and remove references to the inaccessible
  Firebase project.

Official configuration reference:
<https://firebase.google.com/docs/flutter/setup>

Firestore and rules references:
<https://firebase.google.com/docs/firestore/quickstart>  
<https://firebase.google.com/docs/firestore/security/get-started>

**Gate E:** Firebase is a demonstrated synchronized copy with secure rules and
visible failure handling. If this gate is not met by the documentation cutoff,
submit the passing local-persistence path and list Firebase sync as beta work.

### Phase F: validate the word-data vertical slice

- [ ] Approve a small draft vocabulary and vocabulary version for collection.
- [ ] Connect the glove and wait for valid, fresh packets.
- [ ] Record one real trial with pseudonymous signer metadata.
- [ ] Stop and review it.
- [ ] Save the trial locally.
- [ ] Record and verify at least one discard reason on a separate trial.
- [ ] Export the CSV and JSON through the phone share sheet.
- [ ] Copy the exported files to the development computer without hand-editing.
- [ ] Run `python backend/prepare_word_sequences.py <exported.csv>`.
- [ ] Confirm the manifest and validator agree on schema, vocabulary, signer,
  orientation, packet count, and sampling rate.
- [ ] Save a privacy-safe sample export or redacted validator output as alpha
  evidence.

**Gate F:** The real glove-to-export-to-validator flow completes without manual
repair. This proves readiness to begin real word-data collection; it does not
prove word-recognition accuracy.

### Phase G: documentation and artifact audit

- [ ] Rewrite the root README around the tested alpha rather than the intended
  final product.
- [ ] Add an implemented/validated/partial/planned status table.
- [ ] Remove the claim that Firebase persistence is connected unless Gate E
  passes.
- [ ] Link the exact tested commit or release tag.
- [ ] Add actual screenshots from the current app.
- [ ] Label Figma screens as design concepts, not implemented UI.
- [ ] Correct the schematic to match the Feather ESP32-S3 and installed
  MPU-class IMU, including the real flex-sensor circuits and pin mapping.
- [ ] If the schematic cannot be corrected, label the existing ESP32-C3/
  LSM9DS1 image as obsolete and do not present it as the build schematic.
- [ ] Add a bill of materials and physical assembly notes.
- [ ] Add automated and physical validation results.
- [ ] Add a concise known-limitations section.
- [ ] Complete `CONTRIBUTIONS.md` with names, dates, and work descriptions.
- [ ] Confirm repository access with the instructors.
- [ ] Create a final `m3-alpha` tag only after the documented commit is tested.

**Gate G:** A person outside the team can identify what is implemented, build
the software, operate the demonstrated flow, and understand the limitations
without verbal interpretation.

## 5. Physical validation checklist

Physical validation is evidence for the README; it does not necessarily mean
that the glove itself is uploaded or handed in. Based on the provided page, the
explicit submission is a text/Markdown README with the repository link and
instructions. Page 1, Canvas, and instructor announcements must be checked for
any separate live-demo or physical-delivery requirement.

Record the following in `docs/alpha_validation_report.md`:

| Test | Required evidence | Result |
| --- | --- | --- |
| Standalone boot | Glove reaches BLE advertising without a serial monitor. | Pending |
| App discovery | App finds `HelpingHand-Glove`. | Pending |
| Connection | App reports connected and listening. | Pending |
| Live packets | Complete IMU/flex/prediction packet visible. | Pending |
| Static baseline | Selected real letter/number predictions demonstrated. | Pending revalidation |
| Learner feedback | Sensor-driven success/error flow demonstrated. | Pending implementation |
| Persistent progress | Completion survives app restart. | Pending implementation |
| Recording | Real labeled trial reaches review/save state. | Pending physical validation |
| Export | CSV and manifest export from target phone. | Pending physical validation |
| Backend validation | Export accepted without hand edits. | Pending physical validation |
| Reconnection | Three disconnect/reconnect cycles. | Pending |
| Short stress test | Ten-minute stream without crash/reset. | Pending |

For each physical run, record:

- tested commit;
- firmware build flags;
- board and sensor identity;
- phone model and Android version;
- app version;
- target and observed sample rate;
- duration and packet count;
- pass/fail result; and
- notes or known defects.

## 6. Alpha demonstration script

Keep the live or recorded demonstration short and repeatable:

1. Show the glove and identify the ESP32, IMU, and flex sensors.
2. Launch the app and show restored progress.
3. Open the BLE interface and connect the glove.
4. Move the glove/fingers and show live sensor values changing.
5. Perform one supported letter/number or wrist exercise.
6. Show live correction and successful completion.
7. Show the dashboard/progress update.
8. Open Record Signs and enter word, signer, orientation, and trial metadata.
9. Record, stop, review, and save one trial.
10. Export the CSV/JSON session.
11. Show the backend validator accepting the export.
12. State clearly that dynamic word-model training and glove haptics are the
    next phase.

Prepare a prerecorded backup of this exact flow in case classroom BLE or
hardware conditions disrupt a live demonstration.

## 7. Submission contents

The provided assignment page explicitly asks for a text or Markdown README.
The final repository README should contain:

1. complete project description;
2. alpha scope and tested status;
3. repository URL and instructor-access confirmation;
4. architecture and vertical-slice explanation;
5. hardware components and accurate schematic;
6. prerequisites and clean build instructions;
7. firmware upload and phone installation instructions;
8. navigation and demonstration instructions;
9. persistent-state behavior;
10. automated test results;
11. physical validation results;
12. actual screenshots and demonstration-video link;
13. sample privacy-safe export/validator evidence;
14. known limitations and beta plan;
15. team contributions; and
16. required AI-use disclosure.

Recommended submission package:

- Root `README.md` as the primary submission document.
- GitHub repository at the exact tested commit/tag.
- `docs/alpha_validation_report.md`.
- `docs/alpha_demo_script.md` or the script above folded into the README.
- Accurate schematic and hardware photos.
- Current app screenshots.
- Short demonstration video link.
- Optional privacy-safe sample recording export.

## 8. Definition of alpha-ready

The build is ready to submit when all of the following are true:

- [ ] Current firmware and Android app build from documented commands.
- [ ] Flutter and backend test outcomes are recorded honestly.
- [ ] The historical static classifier is revalidated on the current glove, or
  the alpha uses and documents the IMU fallback exercise.
- [ ] At least one learner-facing feature uses live glove input and gives clear
  feedback.
- [ ] Learner progress survives an app restart.
- [ ] The app handles Bluetooth-off, permission, disconnect, and invalid-packet
  states without crashing.
- [ ] One real word trial is saved, exported, and accepted by the backend.
- [ ] The README contains the exact repository link and full build/demo steps.
- [ ] Screenshots, schematic, and claims match the actual implementation.
- [ ] Dynamic word ML, Firebase, and haptic status are not overstated.
- [ ] Instructors can access the repository.
- [ ] The submitted commit/tag is the same build that was physically tested.

## 9. Stop/go rules for the deadline

- If the historical classifier fails, stop word-model work and repair the
  baseline or use the IMU learner exercise.
- If Firebase blocks progress, keep local persistence as the alpha path and
  continue the cloud work after submission.
- If a real export fails backend validation, fix the collection contract before
  training anything.
- If haptic hardware is unavailable, document the deferral; do not simulate a
  glove actuator in the results.
- Do not report synthetic or same-signer smoke metrics as real word-recognition
  performance.
- Do not add late features after the final physical validation run; fix only
  submission-blocking defects and rerun affected tests.

## 10. Commit and review discipline

Every AI-assisted repository change must follow `ai-policy/AI-USAGE.md`:

- the team reviews changes before staging/committing;
- commit subjects use the required `GENAI=Yes` convention and model label; and
- commits contain the `AI-Assisted: codex` trailer when Codex modified content.

Use small commits for the learner loop, persistence, Firebase configuration,
validation evidence, and final README so failures can be isolated without
discarding unrelated work.
