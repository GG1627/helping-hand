# Beta Test Plan - Working Notes

October 5 word update: TCN inference and completion are integrated for complete
Hello, Please, and Yes attempts. Three native Android recorded replay checks
passed. Extend WORD procedures to cover Start attempt / Finish sign, wrong or
uncertain predictions, sensor interruption, cancellation/Back, and word progress
restart/sync. Fresh physical glove/phone and Firebase word-sync procedures are
Not run. See [the integration record](WORD_DEMO_INTEGRATION.md); the earlier
UI-only word assumptions below are retained as historical planning context.

This is the shared fact tracker for drafting the Helping Hand beta test plan.
Update items as the team confirms scope or runs tests. Mark unrun work as
`Not run` rather than assuming it passed.

The learner-facing screen and tracking proposal is in
[`BETA_APP_EXPERIENCE_PLAN.md`](BETA_APP_EXPERIENCE_PLAN.md).

The course prompts transcribed to Markdown are [`M4-Beta-Build.md`](../M4-Beta-Build.md)
and [`T2-Beta-Test-Plan.md`](../T2-Beta-Test-Plan.md).

## Milestone requirements to carry into the submission

The T2 prompt requires the final beta test plan to include all three of these
sections:

1. **Alpha test results:** report outcomes, how testing changed the project,
   and how those lessons shape beta testing. The detailed alpha plan is not
   evidence that a test was actually run; record only confirmed outcomes.
2. **Expected behavior:** define software and hardware behavior clearly enough
   to compare observed results against it. A flow chart, state chart, or
   behavior table can make the main flows easier to reproduce.
3. **Test procedures:** give unambiguous steps and measurable pass/fail
   criteria for expected behaviors; use automated tests and hardware
   measurements where they fit.

T2 describes the plan as a reproducible document usable by readers outside the
team. M4 additionally expects integrated features refined using alpha lessons,
usable and responsive controls, persistent state connected to the interface
and internal processing, known bugs documented in the README, and timestamped
third-party evidence of effort. Keep the beta report honest about incomplete
word-model and physical-device validation.

## Beta direction currently reported by the team

- Record real ASL word sequences with the glove and collect more data.
- Train and compare candidate sequence models; report which performs best.
- Add full account authentication with email/password sign-in.
- Save learner progress in Firebase/Cloud Firestore. Firestore organizes data
  in collections and documents.
- Clean up the app's progress tracking and user experience.
- Recorded sign data can be exported; the exported files download to the phone,
  are saved to a shared Google Drive, then shared with the team and added to
  the repository. This is team-reported behavior; capture a reproducible run
  and evidence for the beta test results.

## Evidence already in the repository

- `backend/recorded_data/` contains an unedited real-device pilot export from
  September 17, 2026: 35 static-sign trials, 5,518 valid BLE frames, one signer,
  neutral orientation, approximately 39.7-40.5 Hz. Most labels have one trial.
- That pilot shows a saved/exported recording dataset exists. It is not a
  dynamic-word dataset and is not sufficient for model accuracy claims or a
  leakage-safe train/test evaluation.
- `README.md` reports automated alpha checks passing: Flutter analyze, 16
  Flutter tests, Android debug APK build, ESP32-S3 build, and 23 backend tests.
- `README.md` describes historical physical glove-to-phone BLE/static
  prediction validation. It also says the current complete glove has not been
  physically regression-tested and real-device recording/export validation
  needs confirmation. Treat these as documented claims until the team confirms
  what was actually run for the alpha submission.
- `docs/T1_ALPHA_TEST_PLAN.md` defines detailed procedures, but is not a record
  of which tests were executed or their outcomes.

## Alpha test outcomes to collect

For each item, record: `Passed`, `Failed`, `Partial`, or `Not run`; when it was
run; build/commit and device; observed result; issue/fix; and evidence location.

| Area | Alpha plan tests to answer | Team result / notes |
| --- | --- | --- |
| Build and automated checks | AB-01 through AB-05 (Section 9.1) | Pending team confirmation |
| Current hardware and static baseline | HW-01 through HW-05 (Section 9.2) | Pending team confirmation; README only documents historical physical validation |
| BLE reliability | BLE-01 through BLE-05 (Section 9.3): discovery, packet quality, permission/Bluetooth recovery, reconnect, 10-minute stream | Pending team confirmation |
| Learner behavior | UI-01 and LL-01 through LL-04 (Section 9.4): navigation, only award on stable matching prediction, reject false matches, consistent progress | Pending team confirmation |
| Persistence | PS-01 through PS-06 (Section 9.5): restart, reset, malformed local state, offline fallback, cloud sync, Firestore access rules | Pending team confirmation; clarify which Firebase features existed in submitted alpha |
| Recording and export | RS-01 through RS-05 (Section 9.6): metadata/readiness, save/review, discard, phone export + unedited backend validation, malformed export handling | Team reports export downloads to phone and is transferred through shared Drive into repo; exact alpha run details pending |
| Word-data/model work | ML-01 through ML-09 (Section 9.7), only if attempted during alpha | Pending; existing repo pilot is static-sign data, not word-model evidence |
| External-user usability | US-01 and related usability procedures (Section 9.8) | Pending team confirmation |

These are the alpha plan's exact procedure IDs. The beta plan does not need to
repeat every alpha test if a test is no longer relevant; it should summarize
the important outcomes and carry forward unresolved risks into beta coverage.

## Beta configuration and decisions to fill in

### Build and devices

- Beta branch/commit or release identifier: TBD
- Android phone model and Android version: TBD
- ESP32 board, IMU identity, firmware version, and power source: TBD
- Flutter/app version and backend environment: TBD
- Testers/roles and any non-team usability participants: TBD

### Word collection and model evaluation

- Candidate list in `docs/T1_ALPHA_TEST_PLAN.md` ML-01: `hello`,
  `thank_you`, `please`, `sorry`, `yes`, `no`, `eat`, `drink`. This is an
  eight-word provisional list, not an approved/frozen vocabulary; ASL SME
  review and final `words-v1` selection remain pending.
- Approved word list and vocabulary version: TBD
- ASL review/approval and written signing instructions: TBD
- Number of signers and pseudonymous signer IDs: TBD
- Trials per word/signer and target total: TBD
- Orientation, speed, glove-fit, and session variations: TBD
- Consent/privacy procedure and raw-data storage location: TBD
- Candidate models and preprocessing variants: TBD
- Train/validation/test split, including held-out signers: TBD
- Metrics to report (suggested: top-1/top-5, macro F1, confusion matrix,
  orientation results, model size, and inference latency): TBD
- Deployment target (ESP32, Flutter phone, or undecided): TBD
- Model selection criteria and whether dynamic recognition is a beta feature
  or experimental: TBD

### Authentication, cloud progress, and app behavior

- Authentication: Firebase email/password with user-chosen passwords and a
  password-reset flow; no shared hardcoded password.
- Existing Firestore path `users/{uid}/progress/current` stores current static
  learner progress; any dynamic-word progress fields remain TBD until the
  vocabulary and curriculum are decided.
- Expected behavior for login/logout, invalid credentials, offline use, and
  sync after reconnect: TBD
- Whether progress is account-specific and expected across devices: TBD
- Firebase security rules/emulator test approach: TBD
- Progress states/screens included in beta: TBD

### Provisional account-data boundary

- Firebase Authentication should own login credentials. Never save passwords
  in Firestore.
- The app already stores progress at
  `users/{uid}/progress/current`, with learned letters, learned numbers,
  completed exercises, a schema version, and update timestamp. Beta work should
  make this account-specific and expand it only for learning features that are
  actually in scope.
- Current progress document fields are `schema_version`, `learned_letters`,
  `learned_numbers`, `completed_exercises`, and server-managed `updated_at`.
- Keep raw glove recordings in the CSV/JSON export and team dataset workflow
  (phone -> shared Google Drive -> team/repository) unless the team separately
  decides on a privacy-reviewed cloud data design. Do not put raw sensor
  sequences in a user profile or progress document.
- A separate Firestore profile document may not be needed: Firebase Auth
  already holds the account identity. Add one only for specific app profile
  fields the team decides to support.

### Beta account-flow work

- The app now opens directly to sign-in/account creation instead of the former
  Get Started screen.
- The app now has a Firebase email/password account screen with create-account,
  sign-in, password-reset, and sign-out flows.
- Creating an account while an old anonymous Firebase session exists links
  that session to the email credential. Sign-in to an existing account switches
  to that account.
- Local progress is stored in a file scoped to the Firebase UID. On new account
  creation, the previous unscoped local progress file is migrated once and
  preserved with a `.migrated` suffix.
- Firestore progress reads/writes now require the matching authenticated UID;
  automatic anonymous sign-in was removed from the progress store.
- The team reports that email/password account creation and sign-in succeeded.
  The exact Firebase project, app build/device, and cold-restart behavior were
  not recorded. Cross-account isolation, offline recovery, and progress sync
  remain to be validated end to end.
- Words lists the eight provisional Alpha-plan candidates and opens individual
  practice pages without a coming-soon notice. It does not run a dynamic word
  recognizer or save word completion. Developer Mode reveals a
  Developer hub for Record Signs and BLE Testing; normal learner navigation
  hides those research tools.

### Proposed beta account/progress tests

These are draft procedures for the beta test plan, not completed results:

| ID | Check | Expected result |
| --- | --- | --- |
| AUTH-01 | Create an account, close/reopen the app, and sign in again. | Account is created once; the session restores or accepts the same credentials; dashboard opens. |
| AUTH-02 | Try a wrong password, then use password reset. | Access is denied with understandable feedback; reset email flow responds without exposing whether an email is registered. |
| AUTH-03 | Create an account from an existing anonymous alpha session. | The account keeps the same Firebase UID and its existing cloud/local progress. |
| PROG-01 | Complete a learner item while online, then inspect the signed-in user's progress document. | Only the current user's `progress/current` document changes and values match the app. |
| PROG-02 | Sign out, sign in as a second account on the same phone, and compare progress. | The second account cannot see or change the first account's progress; local progress stays separated by UID. |
| PROG-03 | Go offline, complete an item, reconnect, and retry sync. | Local progress remains usable and eventually syncs to the same account. |
| PROG-04 | Attempt cross-user and unauthenticated Firestore reads/writes with emulator rules. | Rules deny access outside the authenticated user's allowed progress document. |

## Session log

| Date | What was collected/tested | Result or issue | Evidence path |
| --- | --- | --- | --- |
| 2026-10-01 | Firebase email/password account creation and subsequent sign-in | Team-reported successful. Device/build and cold-restart persistence were not recorded. | User report |
| 2026-10-01 | Progress repository account-isolation regression suite | Passed: 8 Flutter progress repository tests, including two separate UID-scoped local stores and independent fake remotes. This does not validate live Firestore rules or cross-account requests against Firebase. | `flutter_app/test/progress_repository_test.dart`; commit `873b589` |

## Alpha-to-beta lessons

Fill this after the team confirms alpha outcomes. For every meaningful alpha
failure or limitation, record the change made for beta and the beta test that
will check the fix.

| Alpha finding | Change made/planned for beta | Beta test that verifies it | Status |
| --- | --- | --- | --- |
| TBD | TBD | TBD | TBD |

## Separate practice-page beta procedures

**Status: Not run on physical devices.** These procedures cover the current
picker-to-practice implementation, not the earlier inline panel. Record the
commit, app build, device/OS, firmware, tester, date, and evidence for every run.
Use two test accounts where persistence checks require account isolation.
Record unexpected behavior as a failure or issue rather than changing the
expected result to match it.

| ID | Preconditions and steps | Measurable expected result |
| --- | --- | --- |
| NAV-01 | Sign in; open each of Home's Alphabet, Numbers, and Words rows, then each bottom-navigation destination. | All six entry points reach the correct picker; zero locked Words controls or coming-soon notices. |
| NAV-02 | For each of the 26 letters and 10 numbers, tap its tile, inspect the practice title/target, then use Back. Repeat for all eight words, including Thank You. | 44 of 44 choices open the matching practice page. Practice appears only on the separate route, never with the picker grid/list. Each Back action returns to the originating tab. |
| NAV-03 | Scroll Alphabet to the final row and Words to Drink; open a lesson and use both toolbar Back and Android system Back in separate runs. Repeat the open/back cycle 20 times. | Correct picker and scroll position restored every time; zero duplicate pages, crashes, or lost completion checks. |
| LIVE-01 | Connect the glove through Developer Mode > BLE Testing; open Letter A. Perform A, then a different sign, and disconnect/reconnect the glove while the route is open. | Target remains A. Reading, confidence, hold feedback, and connection labels update on the visible route without returning to the picker. Record measured update delays and packet evidence; any frozen route fails. |
| LIVE-02 | Open a selected letter/number; produce an incomplete hold and tap Retry. Repeat after a completed hold. | Retry immediately clears hold progress and matching feedback on the visible page. The next eligible packet starts a fresh hold; no stale Matched state persists. Already saved completion remains intact. |
| LIVE-03 | Using controlled packets or a recorded stream, submit a wrong label, confidence below 80%, fewer than five matching packets, a hold shorter than 750 ms, and a gap above 250 ms. Then submit a valid stable match. | No completion from the invalid cases. A valid matching hold at >=80% confidence, >=5 packets, and >=750 ms completes once; returning to the picker updates the check/count. Retain the current tracker threshold tests as regression coverage. |
| WORD-01 | Complete or partially practice a static target, return, open each word page, tap Retry, and stream static predictions. Inspect local and cloud progress before/after. | Correct word title and target; connection state is visible. No invalid-target exception, static completion caused by the word page, word completion, or invented confidence/hold success. Word-model acceptance is a separate future test. |
| UI-01 | Inspect Home, all pickers, and a short/long-target practice page at 320px and 375px phone widths, landscape, tablet, and largest system text size; enable reduced motion. | No overflow, clipped actions, unreachable targets, raster logo, or practice panel on a picker. Back/Retry stay reachable; scroll accommodates long content. Confirm at least 48 logical-pixel touch targets and meaningful screen-reader target/Back labels. |
| PROG-05 | Complete a valid letter/number from its practice page online and offline. Back out, restart, reconnect, and compare the same account's progress. Repeat with a second account. | Saved progress survives navigation/restart, syncs to the same UID, and remains isolated between accounts. Merely tapping a tile or word adds no completion. |

### Current evidence boundary

- The visual redesign at commit `9c5caab` passed Flutter analysis, a production
  web build, and five temporary widget review checks covering phone, landscape,
  tablet, 3x text scaling, reduced motion, selection/Retry callbacks, and
  idle/complete presentation. Those checks preceded separate practice routes;
  they are not evidence that the new navigation or physical BLE behavior passed.
- The subsequent separate-route change passed targeted Flutter analysis.
  Target/Retry/packet refresh now uses a shell-owned notifier alongside BLE
  notifications so the route can rebuild independently of the shell.
- Real-device navigation, live BLE on the pushed route, word-model behavior,
  Android beta build, Firebase end-to-end persistence, and external-user testing
  remain Not run for this change. Add measured results and evidence after runs.
- [Beta build status](BETA_BUILD_STATUS.md) separates implemented UI from
  remaining model, hardware, and submission requirements.

## Next-session handoff

Start the beta report/test-plan session with
[BETA_SESSION_HANDOFF.md](BETA_SESSION_HANDOFF.md), which records the current
implementation, evidence boundaries, remaining decisions, and drafting order.
