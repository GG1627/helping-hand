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

## Hardware and feedback status through November 19

- The team fabricated a PCB and built around it, then returned to perfboard
  after breakage, unreliable connections, and poor engraved copper quality.
  A conductive-thread version used multiple fabric layers for insulation.
  Performance remained unreliable and the team suspected shorts. The pictured
  assembly uses perfboard with discrete wiring and will use laptop USB power
  for the demo. The final assembly and prototype PCB photos are on file.
  [Assembly history](FINAL_REPORT_EVIDENCE_CHECKLIST.md#build-01-pcb-and-glove-assembly-history)
- The actual piezo layout is five finger elements and a five-position plus
  on the back of the hand. Serial testing produced audible output across all
  ten positions and very faint tactile sensation, as reported by the wearer.
  [Piezo output check](FINAL_REPORT_EVIDENCE_CHECKLIST.md#hapt-01-piezo-output-check)
- Gael confirmed manual output mapping and the automatic Number 3 cue on the
  glove. The latter starts after five seconds, uses middle or pinky, repeats
  after a two-second pause if needed, and stops at recognition completion.
  [Number 3 rehearsal](FINAL_REPORT_EVIDENCE_CHECKLIST.md#hapt-03-automatic-number-3-demo-rehearsal)
- In the current Developer Mode build, Hello and Please play preset word
  cues three seconds after opening the lesson and replay after two-second
  pauses. Starting an attempt pauses guidance before recording and a
  successful match ends it. Live word guidance remains unverified.
  [Word guidance evidence](FINAL_REPORT_EVIDENCE_CHECKLIST.md#hapt-05-word-guidance-before-practice)

## Evidence boundaries

- Current implementation and limits are in the
  [glove/model handoff](GLOVE_MODEL_SESSION_HANDOFF.md). The 34-class held-pose
  MLP runs on the ESP32. J/Z use a separate phone TCN with offline results.
  Hello, Please, and Yes use the rehearsal word model. The expanded TCN adds
  scored practice for Sorry and No, with offline evidence and live testing
  pending. The app renders all eight lesson rows and highlights saved word
  completions in green. [Expanded word evidence](FINAL_REPORT_EVIDENCE_CHECKLIST.md#eval-06-expanded-word-tcn)
- The team reports a wired-perfboard final assembly and successful live
  practice for G, I, 1, Hello, Please, and Yes on the rehearsal builds.
  The completion counts and configuration limits are in LIVE-04. The full
  timed demo and live tests of Z and the word cues remain open.
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
- Final glove and PCB photos are on file. Record the exact demonstrated
  firmware, app, models, phone, and any new measured outcomes. Check that the
  report diagram includes the separate J/Z TCN and app-to-glove cue path.
- The README has a current working-build summary. Run the
  [current demo](../post_mortem_presentation/demo_checklist.md), confirm the
  new word cues, and preserve saved-progress and reconnect observations.
- Two lab tryouts and their hardware fixes are in USER-01. A further outside
  tryout on the wired build and timestamped third-party evidence are pending.
- Recheck known bugs, especially static completion after leaving practice.
- Before submission: replace placeholders, revise tense only for confirmed work,
  retain unresolved issues, keep accurate AI disclosure, and review the final
  1-2 page Word/PDF layout if requested.
