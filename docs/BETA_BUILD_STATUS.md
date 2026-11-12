# Helping Hand Beta Build Status

October 5 follow-up: Hello, Please, and Yes now use the selected real-recording
TCN in Flutter with complete-attempt boundaries and saved word completion.
Three native Android recorded replay checks passed; fresh physical glove/phone
recognition and intended-phone latency remain Not run. See
[the integration record](WORD_DEMO_INTEGRATION.md). The October 2 snapshot below
preserves its original evidence and UI-only word scope.

Updated: October 2, 2026. App snapshot: commit [`d581d19`](https://github.com/GG1627/helping-hand/commit/d581d19); README snapshot: commit [`d807ef8`](https://github.com/GG1627/helping-hand/commit/d807ef8).
This records implementation scope; it is not a claim of completed M4 acceptance
or a substitute for the beta report and formal T2 test-plan PDF.

## Implemented app changes

- Email/password account creation, sign-in, password reset, and sign-out remain
  connected to the existing Firebase account flow.
- Login, signup, Home, Alphabet, Numbers, and Words share ivory, teal, mint,
  DM Sans interface typography, and a bundled Fraunces text wordmark. The old
  image logo has no runtime UI references. Home uses the compact single-line
  wordmark; learning pages use matching type, colors, and the curved accent.
- Home provides saved static progress, active learning-path rows, and account
  settings. Words opens normally, with no coming-soon/locked treatment.
- Alphabet and Numbers show progress and tappable targets without an inline
  practice panel. Words shows tappable starter vocabulary rows.
- Choosing a target opens a separate scrollable practice page with its title
  and Back button. Back returns to the originating picker/tab.
- Letter/number practice retains BLE connection feedback, prediction and
  confidence, hold progress, Retry, static acceptance thresholds, and existing
  local-first account-scoped progress persistence.
- The shell owns BLE, the tracker, and progress. A practice-state notifier plus
  BLE notifications refresh the pushed route after target, Retry, packet, and
  connection changes; the route does not own a second BLE connection.
- Word pages share the practice UI and connection feedback, but bypass the
  static tracker. They do not display fabricated matches or save completion.

## Known limitations and remaining beta gates

| Area | Remaining work / acceptance boundary |
| --- | --- |
| Dynamic words | The eight starter words are provisional. No trained/validated dynamic word model or word completion storage is connected to these pages. The UI being accessible does not establish recognition capability. |
| Instruction | Reviewed target-specific ASL instructional media is not yet integrated. Current practice provides a target and generic hold guidance. |
| Glove connection | Connection recovery still directs learners through Developer Mode > BLE Testing. A learner-facing connection flow remains future work. |
| Route regression | Real-device target selection, toolbar/system Back, scroll restoration, Retry, and live BLE updates on the new page still need execution and evidence. |
| Completion lifecycle | Static target selection persists after Back; the existing shell continues processing matching packets until another target or word is selected. Beta testing must establish whether this behavior is acceptable or completion should be limited to a visible practice session. |
| Persistence | Live Firebase account isolation, offline recovery, restart restoration, and cross-device synchronization need end-to-end beta evidence. No schema or backend changes were made in this navigation update. |
| Hardware/build | A production web build passed for the preceding visual redesign. The separate-route change has targeted analysis evidence, not a fresh Android/hardware validation result. |
| Accessibility/usability | The preceding visual redesign had widget-rendered large-text/reduced-motion checks. The new routes need on-device accessibility and non-team user testing. |

## Verification and evidence

- Visual redesign commit: [`9c5caab`](https://github.com/GG1627/helping-hand/commit/9c5caab) (Flutter analysis, five temporary
  responsive/interaction review checks, and production web build passed).
- Separate practice-route update: targeted Flutter analysis passed; physical
  navigation/BLE/persistence procedures remain Not run.
- [Beta test working notes](BETA_TEST_PLAN_WORKING_NOTES.md) define NAV-01 to
  NAV-03, LIVE-01 to LIVE-03, WORD-01, UI-01, and PROG-05 for this change.
- Record exact build/commit, device/OS, firmware, test date, observed results,
  and screenshots/packet/export evidence when executing the plan. Do not use
  older alpha or visual-only results as proof of route/hardware acceptance.

## M4 / T2 traceability

| Requirement | Current implementation or planned evidence |
| --- | --- |
| M4 interface/navigation | Shared visual identity, active learner destinations, separate practice pages, native navigation/Back, and preserved settings. NAV/UI procedures cover regression. |
| M4 feedback/responsiveness | Prediction, confidence, hold, Retry, connection state, and asynchronous existing BLE/Firebase services. LIVE procedures cover route refresh. |
| M4 persistent state | Existing UID-scoped local-first static progress and Firestore path. PROG procedures cover persistence and account isolation. |
| M4 integrated features/build quality | Static baseline preserved. Word recognition and current hardware regression are incomplete; report them explicitly. |
| T2 alpha results | Keep confirmed alpha results and unresolved evidence gaps in working notes; new design decisions are not fabricated alpha-user findings. |
| T2 expected behavior/procedures | App experience plan describes the current journey; working notes supply reproducible procedure IDs and expected results. All new device procedures are Not run until evidence exists. |

Course prompts are preserved in [M4 Beta Build](../M4-Beta-Build.md) and
[T2 Beta Test Plan](../T2-Beta-Test-Plan.md). The team still needs the required
report, formal test-plan PDF, and stakeholder presentation/defense.

## Next-session handoff

Start the beta report/test-plan session with
[BETA_SESSION_HANDOFF.md](BETA_SESSION_HANDOFF.md), which records the current
implementation, evidence boundaries, remaining decisions, and drafting order.
