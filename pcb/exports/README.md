# Schematic preview

- [PNG preview](pcb-schematic-preview.png): drawing bounds with a small margin,
  rendered at 160 dpi for convenient viewing.
- [SVG export](pcb-schematic-preview.svg): original vector export with the full
  drawing-sheet dimensions, for zooming without raster blur.
- [User-supplied color screenshot](pcb-schematic-screenshot.png): copied from
  the user's supplied `fnifi3nimage.png` on October 28 for reference.

Exported October 28, 2026 from the unmodified `../pcb.kicad_sch` using KiCad
CLI 9.0. The source file was last changed in commit `3983cfc` on October 22.
The user initially requested a preview only, then explicitly approved using
the exported image in the R3 report. The report uses the clean PNG export;
the color screenshot is retained as a reference copy. Both show the same
visible component values, labels and connection arrangement.
The export does not establish that this is the team's latest off-repo circuit.

```powershell
& 'C:/Program Files/KiCad/9.0/bin/kicad-cli.exe' sch export svg --exclude-drawing-sheet --black-and-white --output pcb/exports pcb/pcb.kicad_sch
```

The raw command names its output `pcb.svg`; the saved vector preview above
uses a descriptive filename. The PNG was rendered from that export with
PyMuPDF, framing the drawing paths plus a 12-point margin.

This remains a connection draft, not an as-built or fabrication-approved
schematic. The generic Feather symbol, board-specific pin assignments and
unshown sensor/actuator drive circuits need review. In particular, all ten
`PIEZO PIN` labels have the same local net name; they must be checked against
the intended independent actuator channels before layout. No schematic or
board connectivity was changed while preparing the preview.
