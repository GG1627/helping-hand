# Helping Hand Beta App Experience Plan

**Status:** Draft direction for beta design and implementation
**Purpose:** Keep the learner-facing app focused while retaining the tools the
team needs to collect and validate data.

## Product goal

Help a learner practice a sign, understand whether the glove is connected, see
clear feedback, and know what to practice next. Make sign-data collection and
BLE diagnostics available to the team without making them part of the normal
learner journey.

## Recommended learner flow

**Sign in / create account -> Home -> Learn -> Choose a sign -> Practice ->
Feedback -> Progress**

Account creation and email/password sign-in have been reported working. The
app should continue directly to Home when the account session is already
active.

## Beta navigation direction

For the current beta iteration, keep four learner destinations visible:

| Destination | Main purpose |
| --- | --- |
| Home | Welcome the learner, show a concise progress summary, offer a clear Continue Learning action, and show account/sync status. |
| Alphabet | Browse and practice the static letter curriculum. |
| Numbers | Browse and practice the static number curriculum. |
| Words | Preview the provisional starter vocabulary; keep practice unavailable until the words and dynamic model are validated. |

The Home screen currently summarizes progress; a dedicated Progress tab can be
considered after usability feedback. Put account settings behind a
profile/avatar action in the app bar. Developer Mode adds one **Developer**
destination with links to Record Signs and BLE Testing, so the normal learner
navigation remains uncluttered. The current toggle is session-only; decide
whether it should persist across launches before release.

## Screen behavior

### Home

- Show a friendly greeting and one primary action: **Continue learning**.
- Summarize alphabet, number, and (when available) word progress without fake
  streaks or activity.
- Show a small glove connection/sync status. Link to connection help when the
  glove is unavailable; keep diagnostic packet details out of this screen.

### Alphabet and Numbers

- Show per-item states such as Not started, In progress, and Completed only
  after the product defines the progress rules below.
- Keep individual sign instructions visible before practice starts.

### Words

The alpha test plan ML-01 contains eight **candidate** words: `hello`,
`thank_you`, `please`, `sorry`, `yes`, `no`, `eat`, and `drink`. This is not an
approved `words-v1` vocabulary. Show them as a preview only; do not imply that
the static 36-class model recognizes dynamic words or award word progress. ASL
SME review, recording coverage, model evaluation, and runtime validation remain
gates before word practice becomes active.

### Practice

- Show the target sign and concise instructions, with a visible glove
  connection state and a Retry action.
- Keep prediction/confidence feedback close to the practice task.
- Preserve the current static acceptance gate for letters/numbers (matching
  label, at least 80% confidence, five packets, and at least 750 ms) unless
  beta testing supports a deliberate change.
- For words, select and document a separate gate after the word model is
  evaluated. Show an understandable retry state when confidence is low.
- After completion, confirm what was recorded and offer the next item.

### Progress

- Show completed counts separately for letters, numbers, and words.
- Make it easy to identify items not yet completed and resume an in-progress
  item.
- Describe one accepted practice as **Completed practice**, not mastery, unless
  the team defines and validates a mastery rule.

### Account

- Keep sign-in, account creation, password reset, and sign-out in the account
  flow.
- Display whether progress is saved locally, syncing, synced, or unavailable.
- Firebase Authentication owns credentials. Never store passwords in
  Firestore.

## Keep team tools out of learner navigation

Keep **BLE Testing** and **Record Signs** available in a developer/researcher
mode or dedicated test build while hardware validation and word collection
continue. The normal learner build should not expose packet inspection,
recording metadata, or dataset export as ordinary learning tabs.

The learner flow still needs a simple connection status and recovery guidance
where practice uses the glove. Hiding diagnostics must not hide essential
connection feedback.

## Progress tracking direction

The current implementation stores each account's learned letters and numbers
plus completed exercise IDs in `users/{uid}/progress/current`. A letter or
number is added after one stable successful practice. This is useful as a
completion checklist, but it does not distinguish an untouched item from an
item the learner has started, nor does it retain attempt history.

Recommended tracking in stages:

1. **Keep now:** account-scoped completed letter/number sets and local-first
   sync. Define these as completed practice, not proof of mastery.
2. **Add for the next curriculum:** a `learned_words` set using the approved
   word IDs once a validated dynamic-word model is ready.
3. **Add if it supports the learning design:** per-item aggregate counts for
   attempts and successful practices, a last-practiced timestamp, and a
   `last_practiced_item` to power Continue Learning and review suggestions.
4. **Do not upload:** raw BLE packets, IMU sequences, or full trial recordings
   as learner progress. Keep those in the consented CSV/JSON dataset workflow.

Before adding new Firestore fields, decide whether one successful hold is
enough for a completed practice and what repeated practice should change. If
the schema changes, increment the progress schema version, migrate local
progress safely, and update Firestore owner/schema rules together.

## Suggested release sequence

1. Keep Record Signs and BLE Testing usable through Developer Mode for the
   team's collection and verification work.
2. Refine Home, Alphabet, Numbers, and the Words preview using learner feedback;
   decide whether the navigation should later consolidate into Learn/Progress.
3. Finalize the first word vocabulary and learning rules with an ASL reviewer;
   keep Words unavailable until the model is validated on held-out signers.
4. Expand progress tracking only for agreed learner-visible states and
   add tests for account isolation, offline sync, and progress restoration.

## Decisions still open

- What counts as a completed practice versus mastery?
- Should the app remember the last item only, or also attempts and successful
  practice counts per item?
- What is the approved introductory word list and when is a word model ready to
  appear in the learner curriculum?
- Should development tools live in a separate test build or a developer mode
  inside the same app?
- Which fields should carry over when progress is viewed on a second device?
