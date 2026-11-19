"""Derive offline static haptic references and exercise both cue directions."""

import argparse
import hashlib
import json
import math
from collections import defaultdict
from pathlib import Path
from statistics import median, quantiles

from backend.word_data import load_recording

from .control import Command, DryRunScheduler, Opcode, Pattern, Step
from .correction import Band

# Initial candidates from the captured vocabulary with broadly similar thumb
# and index bend. The coupled channels are excluded from every reference.
TARGETS = ("0", "3", "5", "c", "g", "l", "o")
FINGER_SLOTS = {"middle": 2, "ring": 3, "pinky": 4}


def steady_samples(packets):
    start = packets[0].device_timestamp_ms + 500
    end = packets[-1].device_timestamp_ms - 500
    central = [
        p for p in packets if start <= p.device_timestamp_ms <= end and p.packet_valid
    ]
    if len(central) < 40 or any(math.hypot(p.gx, p.gy, p.gz) > 30 for p in central):
        return []
    return central


def values_for(samples, finger):
    return [getattr(packet, f"flex_{finger}_raw") for packet in samples]


def cue_steps(finger, direction):
    # The manual Piezo Outputs screen uses these firmware slot IDs.
    vertical = (8, 7, 9) if direction == "bend" else (9, 7, 8)
    return (FINGER_SLOTS[finger], None, *vertical)


def dry_run(target, finger, direction):
    sequence = cue_steps(finger, direction)
    pattern = Pattern(
        tuple(Step(slot, 50 if slot is None else 100) for slot in sequence)
    )
    scheduler = DryRunScheduler({1: pattern})
    scheduler.connect(0)
    scheduler.begin_practice(target, 0)
    scheduler.set_enabled(True, 0)
    scheduler.receive(
        Command(Opcode.PLAY, scheduler.session, 1, 1, 500, 500).encode(), 0
    )
    for time_ms in range(25, 501, 25):
        scheduler.tick(time_ms)
    actual = [event.slot for event in scheduler.events if event.kind == "on"]
    if actual != [slot for slot in sequence if slot is not None] or scheduler.busy:
        raise RuntimeError(
            f"Incorrect dry-run sequence for {target}/{finger}/{direction}: {actual}"
        )
    return actual


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("csv", type=Path)
    parser.add_argument("manifest", type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    recording = load_recording(args.csv, manifest_path=args.manifest)
    if not recording.report.is_valid or recording.manifest.get("data_origin") != "real":
        raise ValueError("A matched real recording export is required.")

    captures = defaultdict(list)
    for (_, trial), packets in sorted(recording.trials().items()):
        captures[packets[0].word].append((trial, steady_samples(packets)))
    profiles = {}
    simulations = []
    for target in TARGETS:
        trials = captures[target]
        # Reserve the final two independent holds before fitting any bands.
        fit = [(trial, rows) for trial, rows in trials[:-2] if rows][:4]
        held_out = trials[-2:]
        if len(fit) < 3:
            raise ValueError(f"Need at least three steady fit holds for {target}.")
        bands = {}
        omitted = {"thumb": "coupled with index", "index": "coupled with thumb"}
        for finger in FINGER_SLOTS:
            runs = [values_for(rows, finger) for _, rows in fit]
            if any(not 0 < value < 4095 for run in runs for value in run):
                omitted[finger] = "ADC rail reached in a fit hold"
                continue
            percentiles = [quantiles(run, n=10, method="inclusive") for run in runs]
            # Cover measured between-hold variation and add the median within-hold spread.
            margin = max(1.0, median(row[8] - row[0] for row in percentiles))
            band = Band(
                max(1, math.floor(min(row[0] for row in percentiles) - margin)),
                min(4094, math.ceil(max(row[8] for row in percentiles) + margin)),
            )
            validation = []
            for trial, rows in held_out:
                readings = values_for(rows, finger)
                inside = sum(band.low <= value <= band.high for value in readings)
                validation.append(
                    {
                        "trial_id": trial,
                        "inside": inside,
                        "frames": len(readings),
                        "median_inside": bool(
                            readings and band.low <= median(readings) <= band.high
                        ),
                    }
                )
            bands[finger] = {
                "min_raw": band.low,
                "max_raw": band.high,
                "held_out": validation,
            }

            for raw in (max(1, band.low - 25), min(4094, band.high + 25)):
                error = band.error(raw)
                if error == 0:
                    continue
                # Measured bent endpoints are below the straight endpoints on these fingers.
                direction = "bend" if error < 0 else "straighten"
                simulations.append(
                    {
                        "target": target,
                        "finger": finger,
                        "synthetic_raw": raw,
                        "direction": direction,
                        "output_slots": dry_run(target, finger, direction),
                    }
                )
        profiles[target] = {
            "fit_trials": [trial for trial, _ in fit],
            "bands": bands,
            "omitted_channels": omitted,
        }

    output = {
        "scope": "Single-wearer offline reference and simulated cues. No physical output.",
        "source_session": recording.manifest["session_id"],
        "source_sha256": {
            path.name: hashlib.sha256(path.read_bytes()).hexdigest()
            for path in (args.csv, args.manifest)
        },
        "profiles": profiles,
        "synthetic_cue_checks": simulations,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(output, indent=2) + "\n", encoding="utf-8")
    print(f"{len(profiles)} targets, {len(simulations)} synthetic cue checks")
    for target, profile in profiles.items():
        print(
            target.upper(),
            [
                (finger, [f"{v['inside']}/{v['frames']}" for v in band["held_out"]])
                for finger, band in profile["bands"].items()
            ],
        )


if __name__ == "__main__":
    main()
