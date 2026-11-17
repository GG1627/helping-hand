# Preliminary report figures

Prepared for the Word rewrite, keeping October 28, 2026 as the project
reporting viewpoint. These assets are illustrations, not new physical-test
evidence or proof of October hardware completion.

- `glove-planned-layout.jpg`: unchanged copy of the team-supplied photograph,
  originally `C:/Users/gael8/Downloads/50370A6D-5362-4B72-8A5A-1C59B66C3F06.jpg`.
  It shows flex sensors, piezo elements, an IMU breakout and an ESP32 board
  arranged on the glove. The custom PCB is not pictured. The user explicitly
  confirms it was planned and not fabricated at the report cutoff.
- `helping-hand-architecture-basic.png`: recommended simplified version,
  1800 by 860 PNG at 300 dpi for Word. Plain white boxes, short labels,
  a small solid/dashed line legend, and no embedded title or caption.
- `helping-hand-architecture-basic.svg`: matching scalable vector copy.
- `helping-hand-architecture-basic.drawio`: matching editable diagrams.net file.
- `helping-hand-architecture.png`: earlier detailed version, 1800 by 1280 PNG.
- `helping-hand-architecture.svg`: scalable vector copy with editable text.
- `helping-hand-architecture.drawio`: editable diagrams.net XML, with named
  nodes and attached current/planned connector endpoints.

The diagram was constructed as native shapes/text/connectors and exported
with SVG and Windows drawing APIs. It was not generated with ImageGen or
exported from an opened draw.io application. No external AI API was used.
The earlier version uses a blue/green/yellow palette; the recommended basic
version uses plain boxes and gray connectors. Solid lines/boxes represent
implemented paths; dashed lines/boxes represent planned integration.

## Insertions for the Word report

Replace the red photo placeholder after Glove Hardware with:

> Figure 1 shows the proposed component layout, with final mounting and
> connections still planned.

Insert the photograph, followed by this caption:

> Figure 1. Proposed placement of flex sensors, piezo elements, the nine-axis
> IMU, and ESP32. Final assembly and wiring remain planned.

Replace the architecture placeholder after Recognition and Communication with:

> Figure 2 summarizes the implemented processing paths and planned hardware
> integration.

Insert the diagram, followed by this caption:

> Figure 2. Helping Hand system architecture. Dashed boxes and arrows indicate
> planned components and connections, including the unfabricated PCB.

The surrounding Design prose can retain its current/planned distinctions:
the perfboard prototype is the current implementation; wrist relocation,
new IMU integration, custom PCB, and useful piezo cues are future work.
Do not describe the staged photo as a completed October assembly or claim
the photo shows a custom PCB. No new bibliography numbers are introduced.

Use In Line with Text placement. The architecture image is intended to span
most of the text width; the tall photo can be narrower. Keep each caption
with its image, and inspect the final PDF after insertion. The report still
needs the small corrections listed in `../../R3_WORD_REVIEW.md` if the user
has not already made them. Update the disclosure to include figure preparation
as appropriate to the assistance actually used.

## Semantic checks

- Static MLP on ESP32; three-word TCN on phone.
- Six-axis current IMU; nine-axis replacement dashed and calibration pending.
- Existing word inputs remain flex/acceleration/gyro. No magnetic input is
  shown as already consumed by the trained model.
- Local JSON progress is on the phone; Firebase is reached over HTTPS through
  phone Wi-Fi/cellular internet. No glove-to-cloud connection is implied.
- Piezo driver/cue work and correction mapping remain planned. Word output
  alone is not a finger-level corrective signal.
- Custom PCB is a proposed perfboard mounting/wiring replacement, explicitly
  not fabricated. It is not an additional inference processor.

PNG labels were visually inspected and revised to avoid clipping. SVG and
draw.io XML were parsed locally. An actual draw.io application import was
not performed. No Word edits, hardware operation, model training, or physical
validation was performed as part of figure preparation. No commit was made.
