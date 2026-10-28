# R3 preliminary report: draft review and build notes

Prepared October 27, 2026 for the October 28 submission. Course confirmed by
the user: **CEN4908C**. Original assignment wording remains unchanged in
[R3-Preliminary-Report.md](../R3-Preliminary-Report.md).

## Draft artifacts

- [PDF draft](../output/pdf/R3_Preliminary_Report.pdf)
- [Editable LaTeX source](R3_Preliminary_Report.tex)
- [Evidence/readiness notes](R3_REPORT_READINESS.md)
- [Research source notes](../research/R3_REPORT_SOURCE_NOTES.md)
- [Current TCN review](R3_TCN_IMPROVEMENT_REVIEW.md)

The PDF is a first complete draft for team content review, not a record of new
hardware tests. It covers all assignment topics and uses the evidence cutoff
October 27. It contains six report pages and two reference pages, a system
architecture figure, candidate comparison and milestone table. No source-code
listings are included.

Review update, October 27: the user reviewed the PDF by skimming, said it looked
good, and explicitly authorized committing/pushing it. The additional rubric
assessment and reminder organization below were requested in that same update.
The approved PDF/source content was not changed during this rubric review.

## Rubric coverage and candid assessment

The user supplied ten equally weighted categories, each worth four points
(40 total). The rubric itself gives no further performance descriptors; the
assignment specification remains the detailed content standard. The assessment
below describes coverage and risks, not predicted or awarded grades.

| Category | Points available | Coverage in the current draft | Main review consideration |
| --- | ---: | --- | --- |
| Formatting | 4 | Letter paper, configured 0.65-inch margins, approximately 3,060 report words, readable figures/tables, no source-code listings | Previously verified on all eight PDF pages. Recheck after later edits. |
| Abstract | 4 | 245-word synopsis covering purpose, approach, results, limitations and next work | Meets the 200-300-word requirement. |
| Introduction | 4 | Hearing-beginner practice need, educational purpose and bounded system scope | Clearly connects the problem to the proposed aid; benefits remain intended rather than measured. |
| Background | 4 | Peer-reviewed wearable, orientation, haptic and educator research, plus a clearly labeled TCN preprint | Stronger than a tutorial-only background. Different sensing systems/results are qualified. |
| Design | 4 | Architecture figure, hardware/data paths, inference placement, practice interfaces, persistence, communication and risks | Adequate system explanation; an updated as-built schematic and real UI/hardware illustration would make it more concrete. A fabricated/routed PCB is not documented. |
| Status | 4 | Implemented/in-progress/planned states, sensor blocker, PCB/TCN work, timeline and upcoming milestones | Future work has a credible sequence, but owners and several dates remain broad/unconfirmed. |
| Impact | 4 | Cultural/social, global, economic, environmental and professional/ethical discussion with limitations | Covers each required dimension without claiming measured learning or sustainability benefits. More fluent/Deaf educator input would strengthen project evidence. |
| Results | 4 | Historical software checks, static pilot, recorded static/word methods and outcomes, model comparison, Android replay and lessons | Highest evidence risk: no fresh physical beta validation, limited independent trials and incomplete historical run metadata. Clear disclosure does not replace missing executed tests. |
| Conclusion | 4 | Connects achieved integration, limitations, repair dependency and next steps | Consistent with the reported evidence and project goals. |
| References | 4 | 35 cited research, official documentation and versioned project records; all citation keys resolve | Broad bibliography with appropriate scholarly sources. Check link access and any team-specific factual corrections before submission. |

Overall assessment: a technically credible, organized preliminary report with
strong coverage and honest interpretation. Its main weakness is limited current
experimental evidence, not missing section headings or formatting. Some passages
are dense with model/protocol detail; a real prototype/UI figure could improve
accessibility, but is an enhancement rather than a stated mandatory artifact.
Additional general literature is a lower priority than obtaining the specific
missing hardware facts and test records. No full-marks guarantee is warranted.

## Prioritized reminders

| Priority | Missing input / work | Effect on the report or project |
| --- | --- | --- |
| First | **Piezo-buzzer product link, exact model and datasheet** | Required to substantiate actuator/driver specifications. Ten buzzers and their intended layout are already confirmed. This remains the explicit reminder requested by the user. |
| First | Haptic driver/power arrangement, directional cue pattern and method for identifying finger error | Needed to turn the planned haptic behavior into an implementable design; a TCN word label is not already a correction vector. |
| First | Any available physical-test/demo evidence: actual build, phone/OS, hardware, date/place, procedure, observations, failures and fixes | Most useful addition for the Results category. Keep unknown fields and unrun tests honest. Do not delay drafting for nonexistent records or fabricate a run. |
| Next | Failed finger channels, failure timing/symptoms, affected sessions, actual replacement arrival and recalibration | Supports the blocker explanation and determines whether older data remain representative. |
| Next | Old IMU identity, as-built schematic/pin map, power source/battery and actual paid BOM costs | Strengthens Design and Constraints; the replacement flex and ICM-20948 product identities are already recorded. |
| Next | Task owners, internal integration/test dates and final written-report deadline | Makes the roadmap actionable. November 19 is the presentation date; December 3 showcase remains tentative. |
| Later validation | Fresh glove/phone recognition, rejection of wrong/idle gestures, sustained BLE delivery, phone latency, account isolation/sync and external-user/cue-perception testing | Important project completion work, not a result already established by the draft or by code review. |
| Later validation | Fluent ASL/Deaf educator review and defined learning/retention evaluation | Needed before stronger linguistic or educational-effectiveness claims; current remote learner feedback is formative only. |

The first three items offer the clearest immediate improvement to the report if
the team can provide them. Missing parts of planned subsystems can remain
identified as unresolved in a preliminary report; this list is not a claim
that every item must be completed before tomorrow's submission.

## Verification completed

- Built with Tectonic 0.17.0; final compilation had no TeX layout, missing
  citation or undefined-reference warnings. A nonfatal Fontconfig message was
  emitted; the resulting embedded Latin Modern text rendered correctly.
- US Letter, 11-point main text, configured 0.65-inch margins with footer
  included. Extracted text bounds, including the footer, remain within at
  least 0.5 inch of all page edges.
- Abstract: **245 word tokens**. Report including abstract, headings, diagram
  labels, captions and tables: **3,058 word tokens**, excluding title/author
  metadata, footers and references. Counts use normalized rendered PDF text,
  join typeset line-break hyphenation and treat hyphenated words as one token.
  This is a working count rather than an instructor-specific counting rule;
  there is substantial room below 3,500.
- Eight nonblank pages; all eight rendered and visually inspected after the
  final build. Diagram labels, table order, references and page breaks reviewed.
- No unresolved citation markers; 90 PDF link annotations present.
- Poppler was unavailable on PATH; PyMuPDF rendered the verification images.
  No training, implementation tests or physical experiments were rerun to
  generate these report checks.

## Team review and outstanding inputs

- [x] User reviewed the first PDF draft and authorized commit/push on October 27.
- [ ] **Reminder: obtain the piezo-buzzer product name/link and datasheet.**
  Ten buzzers and the five-finger/five-dorsal-X layout are confirmed. Driver
  voltage/current requirements, exact cue patterns and error mapping remain
  unconfirmed. Do not fill these with assumed specifications.
- [ ] Confirm team spelling/order and report date; CEN4908C is already confirmed.
- [ ] Identify the failed finger channels, fault onset, actual replacement
  arrival and repair owner. Replacements were expected this week, not received
  or installed as of the supplied update.
- [ ] Confirm installed old IMU identity, power source/battery, as-built wiring,
  actual paid costs and any additional physical-run metadata the team has.
- [ ] Review the alpha/beta results against original evidence. Missing physical
  location/device/run details remain limitations in the draft; do not invent
  them. Live checks explicitly marked Not run remain unrun.
- [ ] Review the distinction between preserved synthetic 36-class baseline,
  default recorded 34-class static candidate and three-word phone TCN.
- [ ] Confirm proposed engineering milestones/owners. November 19 presentation
  is scheduled; December 3 showcase is tentative. Final written-report due
  date remains unconfirmed.
- [ ] Review citations and the original-design/SME interpretations. The draft
  does not treat remote ASL-learner comments as worn comfort or learning evidence.
- [ ] After edits, rebuild, recount and visually inspect the resulting PDF
  before Canvas submission. Canvas upload has not been performed.

## Rebuilding

From the repository root, with Tectonic installed:

```powershell
tectonic --outdir output/pdf docs/R3_Preliminary_Report.tex
```

The bibliography and TikZ figure are in the single source file, so no separate
BibTeX or diagram build is needed. Tectonic may download missing TeX resources
on the first build. Modify content in the LaTeX file; update these verification
counts after changes. Temporary compilation logs and page renders are not
submission deliverables.

The draft and its wording were prepared with Codex assistance. The user has
reviewed and authorized the current commit; remaining factual/team checks are
listed above. Follow the repository's AI disclosure/review rules for later edits.
