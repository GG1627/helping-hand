# Beta Test Plan - Working Notes

This is the shared fact tracker for drafting the Helping Hand beta test plan.
Update items as the team confirms scope or runs tests. Mark unrun work as
`Not run` rather than assuming it passed.

The learner-facing screen and tracking proposal is in
[`BETA_APP_EXPERIENCE_PLAN.md`](BETA_APP_EXPERIENCE_PLAN.md).

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

### Account work started on branch `gael`

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
- Account creation/sign-in still needs Firebase Console Email/Password
  provider enablement and real-project validation. The current environment
  could not run Flutter analysis because the Flutter SDK cache lockfile is not
  writable here; formatting and whitespace checks completed.

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
| 2026-10-01 | Firebase email/password account creation and subsequent sign-in | Team-reported successful. Device/build and cold-restart persistence were not recorded. | User report; branch `gael` |

## Alpha-to-beta lessons

Fill this after the team confirms alpha outcomes. For every meaningful alpha
failure or limitation, record the change made for beta and the beta test that
will check the fix.

| Alpha finding | Change made/planned for beta | Beta test that verifies it | Status |
| --- | --- | --- | --- |
| TBD | TBD | TBD | TBD |
