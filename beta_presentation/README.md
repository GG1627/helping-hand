# Helping Hand beta presentation

Ten-slide HTML deck for October 6, 2026. Open `index.html` directly in a browser; all images and fonts are local. No build step, package install, or internet connection is needed.

- Format: HTML, 16:9, with a PDF export for submission.
- Timing: 5–6 minutes including the live demo; 1–2 minutes for questions (user correction to the repository guidelines).
- Deck: 10 slides, approximately 5 minutes 30 seconds, including the live demo.
- Trained word vocabulary: **Hello, Please, Yes**. Rehearse and choose two demo words.
- Main next milestone: haptic feedback.
- Speakers: Srinitha Srikanth, Brian Paz, Gael Garcia, Kali Schuchhardt.

The selected TCN is integrated in Flutter for complete word attempts and saved completion. Android recorded replay passed. Fresh glove/phone rehearsal and intended-phone latency remain **Not run**. The deck distinguishes implementation and offline results from live validation and preserves the static baseline.

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

- Slide 6 shows the integrated **TCN**: 96 samples at 40 Hz, 11 raw flex/motion channels, dilated residual blocks, temporal averaging, and three-word softmax. The native diagram is editable; its sensor traces are illustrative.
- All three candidates scored 3/3 on validation. TCN won the predefined size tie-break at 48,324 bytes and scored 3/3 on reserved test trials from the small demo-wearer dataset. This does not establish general accuracy. See `CONTENT_REVIEW.md` and the training record.
- Slide 7 uses explicit Start attempt / Finish sign word attempts. Choose two words after live rehearsal. Slide 8 separates completed recognition software from pending validation and robustness work.
- Slide 2's >90% figure is sourced to NIH/NIDCD and its 2004 reference; see `sources.md`. The feedback gap refers to books and prerecorded videos alone.
- Current screenshots show UI; the static practice screenshot is disconnected.
- Haptic plan: five piezo elements in an X pattern plus one per finger. Error estimation, actuator response, and calibration are future work.
- Slide 9 dates (Oct 7–Nov 3) are proposed milestones for team review, not an agreed final deadline.
- Speaker assignments remain TBD. Current physical-device beta procedures remain Not run in the repository record.

## Deck verification

Reviewed all ten rendered slides in Chrome at 1660×1000. Checked keyboard/button navigation, boundary controls, overview jump, notes, full-screen entry/exit, 390×844 viewport fit, local-file opening, and bundled image loading. No slide text overflow or browser errors/warnings were observed in those checks. This verifies the presentation, not the glove/app demonstration.

After toolbar removal, keyboard navigation, progress fill/boundaries, mobile fit, and print visibility passed. Slide content revisions are checked against the updated sources and implementation references.

The TCN update was checked at 1660×1000 and 390×844, including text bounds and keyboard navigation. All local images loaded. The regenerated PDF contains ten nonblank 16:9 pages; all ten were rendered and visually inspected. Images in the export were recompressed to approximately 3.4 MB while retaining the slide text and editable diagram in the HTML source. Source image assets remain at their original quality. These are presentation checks, not live recognition validation.

Fonts: DM Sans and the app's bundled Fraunces Italic. Their SIL Open Font License texts are included in `assets/fonts/`.
