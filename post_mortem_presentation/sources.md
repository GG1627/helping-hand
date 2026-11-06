# Sources and asset provenance

This draft uses repository evidence, not new physical tests or new recognition
results. Prepared November 6 for the November 19, 2026 presentation.

## Content

- [P3 assignment](../P3-Post-Mortem-Presentation.md): seven minutes, questions throughout, final state/live use, three successes, three challenges, Canvas slides/props.
- [Presentation plan](../docs/POST_MORTEM_PRESENTATION_PLAN.md): confirmed HTML format, date, intended final scope, narrative/timing.
- [Current glove/model handoff](../docs/GLOVE_MODEL_SESSION_HANDOFF.md): 34-class recorded static default, preserved 36-class baseline, three-word TCN, calibration/input contracts, hardware/haptic status, evidence limits.
- [WordsTab](../flutter_app/lib/screens/tabs/words_tab.dart): eight UI word candidates.
- [Word sequence contract](../flutter_app/lib/services/word_sequence.dart): current trained words and model metadata validation.
- [Training record](../docs/WORD_MODEL_DEMO_TRAINING.md): current TCN, historical 48,324 bytes, 15 attempts, 9/3/3 whole-trial split and tiny historical reserved-test result. These are not final eight-word results.
- [Word integration](../docs/WORD_DEMO_INTEGRATION.md): complete-attempt inference, completion behavior, recorded replay and evidence boundaries.
- [October physical observations](../docs/R3_DEMO_OBSERVATIONS.md): retrospective team report of live sign/word practice and progress checked in app/Firebase. No controlled accuracy percentages derived from the sign list.
- [Model audit](../docs/DEMO_MODEL_OPTIMIZATION.md): sensor input/clipping and sequence-window findings. These are not measured effects of a final replacement model.
- [M5 outline](../M5_Work_Outline.md): PCB/mounting/IMU/piezo work with historical status limits.

## Visual material

- `assets/hardware/glove-beta-october.jpg`: exact copy of supplied `beta_presentation/assets/hardware/glove-current.jpg`.
- `assets/hardware/circuit-beta-october.jpg`: exact copy of supplied `beta_presentation/assets/hardware/circuit-current.jpg`. Shows perfboard, not a fabricated custom PCB.
- `assets/screenshots/beta-home.png`, `beta-static-practice.png`, `beta-words.png`: exact copies of beta screenshot assets. Historical UI; static practice is disconnected. The word picker does not establish eight-word trained recognition or a fresh completion.
- Pipeline, feedback return line, cover circles, closing trail, and inline icons are editable SVG/HTML/CSS. The return path is conceptual/planned until final trigger integration is documented.
- Palette/fonts/layout reference: [beta style guide](../docs/BETA_PRESENTATION_STYLE_GUIDE.md). DM Sans and Fraunces Italic font files and their SIL OFL license texts are copied from beta's local assets.
- Favicon: copied from `beta_presentation/assets/diagrams/favicon.svg`.

No new AI-generated raster images or fabricated sensor traces/results are used.
Record provenance and date/configuration when replacing historical assets.
