# Beta Build / Beta Test Plan Session Handoff

Prepared October 2, 2026 for the user's next session using GPT Luna.
Snapshot: beta application commit `d581d19`; README commit `d807ef8`.
The subsequent handoff commit changes documentation only.

## Next session objective

Prepare the Helping Hand M4 Beta Build report and T2 Beta Test Plan from the
current implementation and verified evidence. Draft the required deliverables,
identify missing team inputs, and distinguish completed results from planned
or unrun tests. Do not assume the beta is complete because the UI is polished.

## Read first

1. Root `AGENTS.md` and `ai-policy/AI-USAGE.md` for project and commit policy.
2. `M4-Beta-Build.md` and `T2-Beta-Test-Plan.md`: course requirements, with the
   original prompts preserved above repository companion links.
3. `docs/BETA_BUILD_STATUS.md`: current scope, known limitations, traceability.
4. `docs/BETA_TEST_PLAN_WORKING_NOTES.md`: confirmed evidence, missing alpha
   outcomes/configuration, and draft reproducible beta procedures.
5. `docs/BETA_APP_EXPERIENCE_PLAN.md`: current journey and future requirements.
6. `README.md`: current beta notes plus historical M3 alpha evidence. Do not
   present historical alpha validation as a fresh beta result.
7. `docs/APP_DESIGN_GUIDE.md` for visual identity; `docs/T1_ALPHA_TEST_PLAN.md`
   for original alpha procedures; Issue #7 research and the word-data protocol
   when describing dynamic word collection/model plans.

## Current implementation to preserve

- Text-based Helping Hand branding; no old image logo in runtime UI.
- Login/signup/Home define the ivory, teal, mint, DM Sans/Fraunces identity.
- Alphabet and Numbers contain progress and a target grid only. Words contains
  tappable vocabulary rows. No embedded live-practice panel in the pickers.
- Every letter, number, and word opens a dedicated live-practice route with
  its title and Back control. Words has no coming-soon notice or locked row.
- The shell retains BLE, prediction tracking, and progress ownership; a
  notifier and BLE notifications refresh practice independently of the shell.
- Static matching, confidence, hold, Retry, and UID-scoped progress are retained
  for A-Z and 0-9. Word pages share the practice UI/connection state, but do not
  recognize words or award word completion. Do not feed words to the static
  tracker: it rejects targets outside A-Z/0-9.

## Evidence boundary

- `9c5caab`: reviewed visual redesign, targeted analysis, production web build,
  and five temporary responsive/interaction widget checks passed.
- `d581d19`: separate practice routes, active word navigation, notifier updates,
  and beta documentation. Targeted analysis passed for the route changes.
- Temporary visual review harnesses were removed; their generated screenshots
  may remain in ignored `flutter_app/build/design-review/` locally. They are
  not reproducible checked-in test evidence or physical-device results.
- Route navigation, live BLE, Android beta build, Firebase end-to-end isolation
  and sync, accessibility on devices, and external-user beta tests are Not run
  for the current change. Do not mark them Passed without new evidence.
- Dynamic word training/validation/deployment, approved vocabulary, word
  progress storage, and target-specific ASL instructional media are incomplete.

## Work order for the next session

1. Review the requirements against current scope; draft an M4 report outline
   with a status/evidence table and known limitations.
2. Draft T2's three required sections: confirmed alpha results and lessons,
   expected behavior, and reproducible test procedures with measurable criteria.
3. Use the existing AUTH/PROG and NAV/LIVE/WORD/UI procedure IDs; specify test
   setup, reset/cleanup, evidence capture, and result fields. Keep pending runs
   explicitly Not run. Define performance acceptance targets before measuring.
4. Ask the team for the beta build/version, phone/OS, glove/IMU and firmware,
   tester roles, confirmed alpha outcomes, actual test evidence, and milestone
   dates. Continue independent drafting while those facts are pending.
5. Resolve whether static practice should stop on Back. Current selection
   persists and the shell can complete a target after leaving its lesson.
   Document the decision and add coverage before claiming the behavior is final.
6. Decide beta word scope: UI-only practice pages versus validated dynamic
   recognition. Do not silently claim the latter or rewrite the model pipeline.
7. Produce the required 1-2 page M4 report and T2 plan PDFs when content is
   reviewable; use the document/PDF skills for those deliverables. Stakeholder
   presentation/defense and missing empirical results remain team obligations.

## Commit and session rules

The user reviewed and authorized the completed UI work and requested all
changes be committed/pushed. That does not substitute for review of new
implementation in the next session. Follow the AI usage policy: reviewed work,
`(GENAI=Yes)` subjects, exact exposed model ID or `[Model: Unknown]`, and
`AI-Assisted: codex` trailer. Explain nontrivial logic before its review/commit.
Do not add new tests or run implementation tests unless the user requests
verification; beta procedure drafting is separate from test execution.

## Suggested opening message

> Work on the Helping Hand Beta Build and Beta Test Plan. Read
> docs/BETA_SESSION_HANDOFF.md first, then the listed requirements and status
> documents. Draft the deliverables using confirmed evidence, keep unrun tests
> marked Not run, and identify the team information still needed. Preserve the
> reviewed UI and distinguish accessible word practice pages from unsupported
> dynamic word recognition. Start with a requirements/evidence outline.
