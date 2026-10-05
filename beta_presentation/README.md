# Helping Hand beta presentation

Ten-slide HTML deck for October 6, 2026. Open `index.html` directly in a browser; all images and fonts are local. No build step, package install, or internet connection is needed.

- Format: HTML, 16:9, with a PDF export for submission.
- Timing: 5–6 minutes including the live demo; 1–2 minutes for questions (user correction to the repository guidelines).
- Deck: 10 slides, approximately 5 minutes 30 seconds, including the live demo.
- Dynamic demo target: **Hello**, from the provisional beginner vocabulary.
- Main next milestone: haptic feedback.
- Speakers: Srinitha Srikanth, Brian Paz, Gael Garcia, Kali Schuchhardt.

The outline targets dynamic recognition integration by presentation day. It is not evidence that integration or validation has happened. Update claims to match the demonstrated build; label simulated behavior and unrun tests accurately. Preserve the static baseline.

## Files

- `../docs/BETA_PRESENTATION_SESSION_HANDOFF.md`: Codex session progress, confirmed decisions, reviewed commit, and next-session work order.
- `index.html`, `styles.css`, `presentation.js`: slide content, styles, and presentation controls.
- `speaker_notes.md`: outline, timing, and speaker assignments.
- `demo_checklist.md`: live demo preparation.
- `CONTENT_REVIEW.md`: required slide 6 update after model selection/integration, plus remaining content decisions.
- `sources.md`: statistic attribution and implementation references.
- `assets/ASSET_CHECKLIST.md`: image requests and destination filenames.
- `assets/prompts.md`: optional illustration prompts.
- `assets/screenshots/`: current app screenshots and clearly named historical alpha screenshots.
- `assets/hardware/`: real glove and circuit photos.
- `assets/illustrations/`: conceptual generated artwork.
- `assets/diagrams/`: editable pipeline and timeline visuals.
- `assets/fonts/`: local presentation fonts.
- `exports/helping-hand-beta.pdf`: exported slide PDF; regenerate after changing the deck.

Use the palette and typography in `../docs/BETA_PRESENTATION_STYLE_GUIDE.md`. Keep assets local. Do not commit credentials or screenshots containing personal account information.

## Presenting

- Left/Right arrows or Space: navigate; Shift+Space goes back.
- Home/End: first/last slide.
- F: full screen. O: slide overview. N: speaker notes. ?: shortcuts.
- P: export all ten slides, regardless of the active slide.
- For a manual PDF export, choose Save as PDF, enable background graphics, and disable browser headers/footers. The stylesheet declares a 16:9 page size. The supplied export already uses that size.
- Share the whole folder or the PDF; the HTML alone needs its assets, CSS, and JavaScript beside it.

Speaker notes are shown on the same screen when opened. Close them before projecting, or rehearse from `speaker_notes.md` on a separate device. The final slide stays available during 1–2 minutes of Q&A.

The visible toolbar has been removed. A thin 4px line at the bottom tracks slide progress; keyboard shortcuts provide presentation controls. The line is omitted from printed output, so this change does not affect the existing PDF.

## Replace the two hardware placeholders

1. Add `assets/hardware/glove-current.jpg` and/or `assets/hardware/circuit-current.jpg`.
2. Uncomment the matching entries in `assets/asset-manifest.js` (or update filenames there and the corresponding `data-asset` attribute in `index.html`).
3. Reload. The slots replace their placeholders after each image loads; a missing file retains its placeholder.
4. Export a fresh PDF. The existing PDF is a snapshot and does not update automatically.

## Content to review before presenting

- Dynamic recognition uses the requested provisional 3–4-word experimental scope. Confirm the actual build and vocabulary; these slides are not evidence of integration or accuracy.
- **Slide 6 must be updated after the actual model is trained, selected, and integrated.** It now illustrates the proposed CNN-GRU pipeline and CNN-LSTM comparison; follow `CONTENT_REVIEW.md` before treating the architecture as final. A Hello screenshot is optional future supporting evidence, not a current slide placeholder.
- Slide 2's >90% figure is sourced to NIH/NIDCD and its 2004 reference; see `sources.md`. The feedback gap refers to books and prerecorded videos alone.
- Current screenshots show UI; the static practice screenshot is disconnected.
- Haptic plan: five piezo elements in an X pattern plus one per finger. Error estimation, actuator response, and calibration are future work.
- Slide 9 dates (Oct 7–Nov 3) are proposed milestones for team review, not an agreed final deadline.
- Speaker assignments remain TBD. Current physical-device beta procedures remain Not run in the repository record.

## Deck verification

Reviewed all ten rendered slides in Chrome at 1660×1000. Checked keyboard/button navigation, boundary controls, overview jump, notes, full-screen entry/exit, 390×844 viewport fit, local-file opening, and bundled image loading. No slide text overflow or browser errors/warnings were observed in those checks. This verifies the presentation, not the glove/app demonstration.

After toolbar removal, keyboard navigation, progress fill/boundaries, mobile fit, and print visibility passed. Slide content revisions are checked against the updated sources and implementation references.

The exported PDF contains ten nonblank pages. All ten exported pages were rendered and visually inspected. Images in the export were recompressed to reduce the file to approximately 5 MB; source assets remain at their original quality.

Fonts: DM Sans and the app's bundled Fraunces Italic. Their SIL Open Font License texts are included in `assets/fonts/`.
