# Helping Hand post-mortem · first draft

Presentation: **November 19, 2026**. Draft prepared November 6 while project
development continues. Open [index.html](index.html) directly in Chrome or Edge.
No build, package installation, web server, or internet connection is required
for the slides. Keep this folder and its local assets together.

Eight main slides target **6:10 including a 90-second live demo**, leaving
approximately 50 seconds within the seven-minute assignment for interruptions
and transitions. Two backup slides are outside the normal forward sequence.

This draft follows the beta deck's ivory/teal identity, typography, thin progress
line, and keyboard controls. The beta submission is preserved separately.

## Controls

| Key | Action |
| --- | --- |
| Left / Right, Page Up / Down | Previous / next slide within the main or backup group |
| Space / Shift+Space | Next / previous slide |
| Home / End | First / last main slide |
| O | Overview with separate main and backup groups |
| B | Open backups / return to the last main slide |
| N | Notes for the current slide |
| F | Toggle fullscreen |
| ? | Help and backup-print option |
| P | Print / save PDF |
| Escape | Close a dialog or exit fullscreen |

**Notes open on the same screen.** Keep them closed when projecting; use
[speaker_notes.md](speaker_notes.md) on another device for rehearsal/presentation.

## Draft content

The goals are a mounted PCB, new ICM-20948, integrated haptics, A-Z, 0-9, and
Hello, Thank You, Please, Sorry, Yes, No, Eat, Drink. Current baseline support
is described separately; those goals are not claimed as completed or validated.

October hardware photos and app screenshots are historical references. The
practice screenshot is disconnected. Final assembly photos, PCB close-up,
screenshots, haptic meaning, recognition coverage, results, team reflection,
and speaker assignments still need updating. Use
[CONTENT_REVIEW.md](CONTENT_REVIEW.md) to track the remaining content.

## Export

The default print/PDF includes **eight main slides**, regardless of which slide
is active. To include the two backup slides, open `?` and select **Include backup
slides when printing** before exporting. Draft labels and pending-content fields
remain visible in both exports. Print does not imply final-submission readiness.

Use Save as PDF, background graphics on, headers/footers off, and the CSS page
size (16:9). The exports folder contains a main-deck draft PDF and contact sheet.
Regenerate exports after any content/layout changes. Check every exported page.

## Files and references

- [Speaker notes](speaker_notes.md): narration, timing, and draft content boundaries.
- [Demo checklist](demo_checklist.md): proposed live scenario and presentation setup.
- [Content review](CONTENT_REVIEW.md): remaining decisions and content slots.
- [Sources](sources.md): implementation/evidence references and asset provenance.
- [Presentation plan](../docs/POST_MORTEM_PRESENTATION_PLAN.md): creative brief and preparation schedule.
- [P3 assignment](../P3-Post-Mortem-Presentation.md): course requirements.
- [Style guide](../docs/BETA_PRESENTATION_STYLE_GUIDE.md): palette/type reference.

Local fonts are DM Sans and Fraunces Italic; SIL Open Font License texts are
included in `assets/fonts/`. No new AI-generated images are used in this draft.

## Verification

See [verification.md](verification.md) for the recorded browser and PDF checks.
These checks validate presentation behavior/layout, not the glove, model,
haptics, learning effectiveness, or final product readiness.
