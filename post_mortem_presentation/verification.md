# Draft 01 presentation verification

Checked November 6, 2026 using Playwright Chromium on Windows, opening the
local `index.html` directly. No application or hardware behavior was tested.

## Browser

- Eight main slides, two backups, and 370 seconds of prepared content confirmed.
- All bundled images loaded; no page errors or console errors observed.
- Main flow stops at slide 8; backup flow stays separate. B returns to the last
  main slide. Home/End, arrows, Space/Shift+Space, overview selection, and direct
  hash entry were exercised.
- Current-slide notes, dialog dismissal, fullscreen entry/exit, progress values,
  and the backup-print checkbox were exercised.
- At 1660 × 1000, all ten slides were captured and checked for content outside
  the slide, footer collisions, and reflection-note overlap. Initial spacing
  issues on slides 3/6 were fixed; the final checks reported no such issues.
- At 390 × 844, the full 16:9 slide fits the viewport and overview/dialog access
  works. This is scaled presentation viewing, not a mobile reading layout.
- Reduced-motion preference was enabled for the recorded captures; the CSS
  disables slide animation under that preference.

## Export and visual review

- Default export contains eight nonblank main pages. Optional backup export
  contains ten pages. Both were generated through browser print layout.
- The main PDF is approximately 0.84 MB; page size is approximately 1200 × 675
  PDF points. All pages retain searchable text and draft labels.
- Raster images in the PDF were recompressed with PyMuPDF to reduce export size;
  HTML/source photos are unchanged. Text and diagrams remain vector content.
- All eight final PDF pages were rendered and visually inspected in a contact
  sheet. Main-slide browser captures and the two backup slides were also checked.
- [draft-overview.png](exports/draft-overview.png) shows the eight-slide browser
  overview; [draft PDF](exports/helping-hand-post-mortem-draft.pdf) is the current
  main-deck export.

Speaker notes were extracted from the HTML templates for consistency. Local
document/asset references and Git whitespace checks were verified before commit.

These checks establish presentation layout and control behavior only. Final
photos, supported vocabulary, haptic behavior, results, team stories, actual
speaking time, and physical demonstration rehearsal remain content work.
