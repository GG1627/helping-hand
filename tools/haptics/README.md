# Offline haptic prototype

Run from the repository root with Python 3.10 or later. No extra packages,
glove, phone, Bluetooth, or GPIO access are needed.

```powershell
python -m tools.haptics.dry_run
python -m unittest discover -s tools/haptics/tests -v
```

Use `--scenario scheduler` or `--scenario correction` to limit the trace.
The command prints JSON lines to stdout; it does not write recordings or progress.

| File | Purpose |
| --- | --- |
| `control.py` | Draft 20-byte command codec, bounded sequential scheduler, lifecycle cancellation |
| `correction.py` | Explicit reference/health validation and a separate static correction evaluator |
| `fixtures.py` | Invented timing and pose examples, explicitly labeled synthetic |
| `dry_run.py` | Three-second abstract playback and static-correction traces |
| `hardware_inventory.template.json` | Blank assembly/driver/placement record; no enable path |
| `tests/` | Software checks with virtual clocks and invented sensor values |

This is an executable design prototype, not firmware or Flutter integration.
It contains no hardware adapter, actual BLE writes, verified drive frequency,
amplitude setting, real sign reference, or completion-award logic. Setting the
simulator's `enabled` flag only enables trace generation.

Slot IDs follow the existing firmware's electrical order. The fixture's dorsal
sequences have no validated physical direction or ASL meaning. Test values must
not be copied into a live glove configuration.

The detailed architecture, draft protocol, remaining implementation work,
research sources, physical procedures, and verification record are in
[the engineering handoff](../../docs/HAPTIC_ENGINEERING_HANDOFF.md).
