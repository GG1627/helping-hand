# Release candidate report revision notes

Recorded November 12, 2026. This file inventories the existing M5 documents and
sets the reference for a later report revision; it is not the revised report.

**Current scope:** Gael requested saving the correct assignment and locating the
existing documents only, and explicitly asked not to start the updated submission
report. Wait for that request before drafting or exporting a replacement report.

## Correct assignment

Use [M5: Release Candidate](../M5-Release-Candidate.md), supplied by Gael on
November 12. Gael reported that the earlier release candidate document used the
wrong assignment reference, as had the alpha report before its correction.
The earlier incorrect reference has not been identified in this inventory.

The supplied M5 assignment requires:

- An approximately 1–2 page PDF report relating completed work to the
  specification and rubric criteria, with the project repository link.
- A polished beta refinement with all major elements integrated, complete and
  usable, clearly documented bugs, and no showstopper bugs.
- Coverage of Interface, Navigation, Perception, Responsiveness, Robustness,
  Consistency, and Aesthetic Rigor, including refinements informed by testing.
- An in-person stakeholder presentation and defense in the week following the
  assigned due date; the team must arrange the meeting.
- Repository source code, hardware designs, and a README describing completed
  work, architecture, and all known bugs.
- Time-stamped third-party effort evidence, such as remote repository pushes
  and online documents. Action logs alone do not qualify. The stated effort
  expectation is approximately 130 hours per member / 390–650 person-hours per
  team, excluding design documentation; this expectation is not proof of hours.

The prompt prints **CEN3908C**; existing project reports print **CEN4908C**.
Preserve that distinction until choosing the corrected report's course heading.
The supplied text contains no due date or separate scoring rubric. Existing
October documents state October 28, 2026 as the milestone date.

## Existing files found in this repository

| File | Contents and historical status |
| --- | --- |
| [M5_Work_Outline.pdf](../output/pdf/M5_Work_Outline.pdf) | **2 pages**, titled “Helping Hand Release Candidate / M5 Milestone Work Outline.” Summarizes IMU firmware, piezo control, PCB planning, sewing/insulation preparation, replacement sensors, TCN review, software checks, and unrun physical checks. Closest existing artifact to the requested brief report. |
| [RELEASE_CANDIDATE.pdf](../output/pdf/RELEASE_CANDIDATE.pdf) | **20 pages**, titled “Helping Hand - M5 Release Candidate.” Extended README-style documentation containing architecture, learning flow, rubric status, setup, evidence, hardware plans, and known bugs. Supporting material; its length exceeds the requested brief report. |
| [M5_Work_Outline.md](../M5_Work_Outline.md) | Editable work-outline source. Now includes a November 5 parts-arrival follow-up absent from the October PDF. |
| [RELEASE_CANDIDATE.md](../RELEASE_CANDIDATE.md) | Editable extended release candidate document. Now includes November 5 and November 6 follow-ups absent from the October PDF. |
| [README.md](../README.md) | Root project README with release candidate summary, architecture, and known issues, plus later development updates. It is a living document, not a frozen October report. |

Both PDFs were added in commit
[`5548a7b`](https://github.com/GG1627/helping-hand/commit/5548a7bd3d6eed13d2774cabc64c89dbecd22837),
“Added the PDFs to our PDF folder,” timestamped October 28, 2026,
21:10:57 -04:00. PDF metadata records creation at 21:09:50 -04:00 for the work
outline and 21:09:44 -04:00 for the extended document that day.
Their headings identify
[`ff6a9ab`](https://github.com/GG1627/helping-hand/commit/ff6a9ab763f12f60e3a327d0df4f00a8784894b8)
as the release candidate implementation snapshot; that is distinct from the
later commit adding the PDFs.

The latest source edits found during this inventory were November 5 for
`M5_Work_Outline.md` (`ea38c33`) and November 6 for `RELEASE_CANDIDATE.md`
(`2c5c9e8`). Use the saved PDFs or October Git versions when reviewing what the
October artifacts actually said.

Repository presence and commit metadata identify saved artifacts; they do not
confirm which files were uploaded to Canvas, a successful submission, stakeholder
meeting completion, remote push timestamps, or actual hours worked. No submission
receipt was found in the reviewed repository documents. If Gael's submitted
copies differ, obtain those copies before treating these as exact submissions.

## Initial implications for the rewrite

- The two-page outline is a useful starting source, but its work-list format
  does not explicitly organize the report around all seven criteria. Include
  a clear repository URL: <https://github.com/GG1627/helping-hand>.
- The longer document already contains a rubric table and bug list. Condense
  relevant, supported evidence into the brief report instead of copying the
  full README or treating planned improvements as completed work.
- The October artifact lists a potentially blocking USB Serial startup wait,
  static practice completing after leaving the page, BLE/power issues, and
  faulty flex readings. It also describes unfinished PCB work, haptic integration,
  and new-IMU installation/testing. These prevent an unqualified claim that all
  features were complete or that the artifact met the no-showstopper requirement.
  State the actual limits; do not erase them to match the assignment wording.
- Distinguish alpha evidence, beta carryover, M5 changes, and later November
  work. Software/emulator checks do not establish fresh glove performance,
  external-user usability, physical haptic output, or current hardware reliability.
- Identify the beta feedback or observed defect behind each refinement when
  evidence exists. Do not invent beta test results, hours, or stakeholder outcomes.
- Preserve both October PDFs when creating the corrected report under a distinct
  filename. Rewriting and exporting that report have not been done in this
  inventory session.

## Original PDF fingerprints

SHA-256 recorded for identifying the historical copies:

```text
output/pdf/M5_Work_Outline.pdf
a624239a5b7a6492e42ee4ac8708f253a0a28e2e76851bf448ac5ce13bcdbf83

output/pdf/RELEASE_CANDIDATE.pdf
85e0473c58e219917b86a9ae3900c1bb5c75694da2225b09793e1aa892b7957b
```
