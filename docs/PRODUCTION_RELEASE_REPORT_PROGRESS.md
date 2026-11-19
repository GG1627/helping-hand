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

## Hardware and feedback reported November 18

- The team fabricated a PCB and built around it, then returned to perfboard
  after breakage, unreliable connections, and poor engraved copper quality.
  A conductive-thread version used multiple fabric layers for insulation.
  Performance remained unreliable and the team suspected shorts. The current
  assembly uses perfboard with discrete wiring. Preserve the failure sequence,
  photos, and as-built wiring details when available.
  [Assembly history](FINAL_REPORT_EVIDENCE_CHECKLIST.md#build-01-pcb-and-glove-assembly-history)
- The actual piezo layout is five finger elements and a five-position plus
  on the back of the hand. Serial testing produced audible output across all
  ten positions and very faint tactile sensation, as reported by the wearer.
  [Piezo output check](FINAL_REPORT_EVIDENCE_CHECKLIST.md#hapt-01-piezo-output-check)
- The developer app has a manual BLE output tester and a separately labeled
  visual preview in word practice. End-to-end phone/glove actuation and
  reliable perception need live evidence. Automatic finger correction and
  physical word-motion guidance remain unfinished.
  [Haptic handoff](HAPTIC_ENGINEERING_HANDOFF.md#november-18-demonstration-controls)

## Evidence boundaries

- Current reference handoff: [glove/model handoff](GLOVE_MODEL_SESSION_HANDOFF.md).
  Its earlier selected-sign demo goal is distinct from the broader final scope
  agreed above. Recheck implementation as other sessions make changes.
- Last inspected baseline: recorded 34-class static model excluding J/Z,
  preserved original 36-class baseline, and phone recognition for Hello/Please/Yes.
- The team reports a wired-perfboard final assembly and successful live
  practice for G, I, 1, Hello, Please, and Yes on the rehearsal builds.
  Repeatability on the final release build, complete vocabulary coverage,
  power behavior, and live BLE haptic output still need evidence.
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
- Next: collect final build photographs and wiring details. Record the exact
  release firmware, app, models, phone, power source, and measured test results.
- Refresh the README's current release section with the wired-perfboard
  hardware, actual model coverage, haptic scope, architecture, setup
  instructions, and known bugs. Preserve historical milestone sections.
- Test the final phone/glove flow, including saved progress after relaunch and
  reconnect, and record real piezo output separately from the word preview.
- Record non-team-member testing rounds, feedback, changes, and retest outcomes.
- Recheck known bugs, especially static completion after leaving practice.
- Before submission: replace placeholders, revise tense only for confirmed work,
  retain unresolved issues, keep accurate AI disclosure, and review the final
  1-2 page Word/PDF layout if requested.
