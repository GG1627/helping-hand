# Preliminary report Word review

Reviewed November 13, 2026. Source:
`C:/Users/gael8/OneDrive/Desktop/Preliminary_Report.docx`.
File inspected before opening in Word: 38,362 bytes, last saved November 13
at 1:47:07 p.m. Source text was not edited. Review notes remain local and
uncommitted under the user's revised batching preference.

## Checks completed

- Read the document body, tables, references, header, and section properties
  from OOXML. Compared citation use with the active citation ledger.
- Inspected all nine pages in native Word at full-page zoom; also viewed
  the opening and final-reference pages at normal reading zoom. No major
  clipping, overlapping text, broken table rows, or unreadable layout was
  observed. The model and timeline tables fit on their respective pages.
- A connected document-control session was unavailable; the native Word
  visual check used the computer-use skill. The packaged DOCX renderer was
  not run, and no PDF was exported. This is not final post-image layout QA.
- Abstract: **230 whitespace-delimited words**, one paragraph, no citations.
- Main text including abstract, headings, tables, and image placeholders,
  excluding References: **3,262 whitespace-delimited words**. This is an
  approximate count rather than a live Word selection statistic. The source
  package's saved whole-document count is 4,162 and includes the reference
  material; do not compare that total directly with the 3,500-word body cap.
- Paper: US Letter, 8.5 by 11 inches. All four margins: **0.75 inches**.
- All required report sections are present. No source-code listings.
- Bibliography contains [1]-[22] once each, in expected order. All but [15]
  are cited in the current body because of the PlatformIO typo below.
- The report retains the October project viewpoint: November engineering
  dates are planned targets, not completed upgrades. Informal observations,
  recorded evaluations, and software/replay checks remain distinguished.
- No embedded figures yet; the two Design placeholders are still present.

## Small corrections before finalizing

1. **Tools first paragraph:** change the PlatformIO citation from **[14] to
   [15]**. [14] identifies the flex sensor. With this correction, first-use
   order matches the ledger and no bibliography source remains uncited.
2. **Status table, November 13 row:** change **"Fabricated and assemble the
   PCB"** to **"Fabricate and assemble the PCB"**. Keep Planned target.
3. **Results final sentence:** replace "remain to be implemented" with a
   clear statement that the tests have not been run. Suggested sentence:

   > Post-repair recognition checks, sustained BLE testing, intended-phone
   > latency measurements, and broader outside-user testing have not yet
   > been run.

4. **Results, Integration and Follow-Up:** remove the raw parenthesized GitHub
   URL following **[11]**. The reference entry already supplies the link.
   Keep the in-text citation as [11].
5. **AI-assistance disclosure:** the existing sentence mentions organization,
   grammar, and wording. Make the assistance description include drafting,
   because whole paragraph drafts were provided during this session. Suggested
   wording accurately credits both the team's inputs/review and assistance:

   > The team provided project details and reviewed the content. Codex
   > assisted with drafting, organization, and editing.

No wording should claim that Codex fully authored every contribution, or that
assistance was limited to grammar when it also included drafting.

## Image completion and final check

- Replace the two red placeholders with the prototype photo and system
  diagram, with short numbered captions. Refer to the figures from the text.
- Use hardware imagery consistent with the October prototype, or clearly
  distinguish later hardware if it is shown. Do not show the nine-axis IMU,
  finished PCB, or haptic system as already integrated at the cutoff.
- The system diagram should distinguish sensor acquisition, static inference
  on ESP32, BLE transfer, word inference on the phone, and local/cloud storage.
  Planned hardware should be labeled or omitted from the implemented path.
- A date line under the title, such as **October 28, 2026**, would clarify
  the reporting viewpoint. It is currently implicit rather than explicit.
- Keep captions concise: approximately 238 words remain under the cap using
  the current approximate count, before removing placeholder text. Check the
  actual Word body count after figures/captions are added.
- Recheck pagination and references after images are inserted, then export
  the final PDF and inspect it. No Canvas submission has been performed.
