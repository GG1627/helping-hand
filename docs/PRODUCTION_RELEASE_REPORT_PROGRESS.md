# Production Release Report Progress

## Working arrangement

- Gael is maintaining the actual report in Word. Provide proposed report text
  directly in chat for copying and pasting.
- Do not create a standalone report source, Word document, or PDF unless asked.
- The earlier `docs/Production_Release_Report_DRAFT.md` was deleted at Gael's
  request. This file tracks decisions, progress, and missing evidence only.
- Do not commit or push anything until Gael explicitly instructs it. This
  session instruction overrides the automatic document-commit workflow.
- M6 rough wording was supplied in chat. R4 final report instructions have now
  been supplied and discussed; use the preliminary report as its foundation.
- Shared build/test evidence for both reports is tracked in the
  [final report evidence checklist](FINAL_REPORT_EVIDENCE_CHECKLIST.md).

## Assignment and references

- Governing prompt: [M6: Production Release](../M6-Production-Release.md).
- Submission report: approximately 1-2 pages, PDF, including the repository link.
- Relate work to Interface, Navigation, Perception, Responsiveness, Robustness,
  Consistency, Aesthetic Rigor, and complete features connecting External
  Interface, Internal Systems, and Persistent State.
- Assignment expects multiple rounds of user testing, including non-team
  members. README, architecture, known bugs, timestamped third-party evidence,
  and stakeholder presentation/defense are additional requirements.
- The stated effort totals are expectations, not evidence of actual hours.
- Assignment prints CEN3908C; previous team reports use CEN4908C. Confirm before
  submission. No due date or separate scoring rubric has been supplied here.
- Style references reviewed: Gael's Alpha Build, Beta Build, Preliminary, and
  Release Candidate PDFs. Use a straightforward team voice, concrete behavior,
  reasons for decisions, actual observations, and honest limitations.

## Agreed intended final scope

These are targets, not confirmed completed work:

- Fully assembled glove with installed PCB, secure wiring, and insulation.
- All five flex sensors working and calibrated, including replacements for the
  damaged sensors.
- New ICM-20948 installed, calibrated, and integrated with the actual pipeline.
- Recognition and practice completion for A-Z, 0-9, and all eight app words.
- Ten functioning piezo elements with integrated haptic feedback.
- Working app instructions, visual feedback, account access, and saved progress.
- Battery-powered operation is the goal; USB is an acknowledged fallback.

## Haptic decisions and open questions

- Placement: one element per finger and five in an X on the back of the hand.
- Intended static feedback: identify a finger and use a directional X sequence
  to communicate bend more versus straighten more.
- Word-motion feedback remains undecided. Directional guidance and a short
  demonstration pattern are candidate ideas, not implemented/validated claims.
- Gael has started a separate session for haptic research and implementation.
  Obtain its actual findings and test results before updating report claims.
- Distinguish actuator activation, automatic correction selection, and user
  understanding of cues; each needs its own evidence.

## Evidence boundaries

- Current reference handoff: [glove/model handoff](GLOVE_MODEL_SESSION_HANDOFF.md).
  Its earlier selected-sign demo goal is distinct from the broader final scope
  agreed above. Recheck implementation as other sessions make changes.
- Last inspected baseline: recorded 34-class static model excluding J/Z,
  preserved original 36-class baseline, and phone recognition for Hello/Please/Yes.
- Physical assembly, expanded coverage, new hardware performance, and final
  haptic behavior have not been established in this report discussion.
- Orientation/motion information does not establish reliable hand location
  relative to the body. Flex sensors do not directly measure finger spread.
- Magnetic telemetry alone does not establish calibrated orientation.
- Historical tests and demonstrations must remain dated historical evidence.
  Do not present them as final-release acceptance runs or measured live accuracy.
- Unperformed procedures are Not run. Results unavailable to this report are
  not yet documented; do not assume no other session has performed them.

## Report progress and next updates

- Assignment discussed and preserved; intended scope and limitations agreed.
- Initial rough wording is supplied in chat for Gael's Word document, with
  unfinished work in future tense and bracketed result placeholders.
- Planned sections: overview; work since release candidate; usability/build
  quality; integrated learning flow and storage; testing; limitations.
- Next: review Gael's wording preferences, then incorporate actual assembly,
  firmware/app/model revisions, final vocabulary, calibration, power, recognition,
  haptic, and saved-progress results as available.
- Record non-team-member testing rounds, feedback, changes, and retest outcomes.
- Recheck known bugs, especially static completion after leaving practice.
- Before submission: replace placeholders, revise tense only for confirmed work,
  retain unresolved issues, keep accurate AI disclosure, and review the final
  1-2 page Word/PDF layout if requested.
