"""Create deterministic synthetic word-sequence fixtures for tests/smoke runs.

The output is marked ``synthetic_fixture`` in its manifest. It is not training
data and must never be included in reported real-recording model performance.
The legacy static generator in generate_asl_data.py is intentionally separate.
"""

from __future__ import annotations

import argparse
import csv
import json
import math
import random
from datetime import datetime, timezone
from pathlib import Path

try:
    from .word_data import REQUIRED_COLUMNS, SCHEMA_VERSION
except ImportError:  # Direct execution from backend/.
    from word_data import REQUIRED_COLUMNS, SCHEMA_VERSION  # type: ignore[no-redef]


FIXTURE_VOCABULARY = ("fixture_wave", "fixture_tap")
FIXTURE_VOCABULARY_VERSION = "synthetic-fixture-v1"


def generate_fixture_session(
    output_directory: str | Path,
    *,
    seed: int = 7,
    sample_rate_hz: int = 40,
    samples_per_trial: int = 64,
) -> tuple[Path, Path]:
    """Write a deterministic two-trial CSV and manifest, returning both paths."""

    if sample_rate_hz <= 0 or samples_per_trial < 2:
        raise ValueError("sample_rate_hz must be positive and samples_per_trial >= 2")
    output = Path(output_directory)
    output.mkdir(parents=True, exist_ok=True)
    csv_path = output / "trials.csv"
    manifest_path = output / "manifest.json"
    rng = random.Random(seed)
    session_id = f"synthetic_fixture_seed_{seed}"
    device_start_ms = 100_000
    receive_start_ms = 1_800_000_000_000
    interval_ms = 1000.0 / sample_rate_hz
    sequence = 10_000
    rows: list[dict[str, object]] = []

    trial_specs = (
        ("trial_001", "fixture_wave", "neutral", 0.0),
        ("trial_002", "fixture_tap", "pitch_up", 0.7),
    )
    for trial_number, (trial_id, word, orientation, phase) in enumerate(trial_specs):
        trial_device_start_ms = device_start_ms + trial_number * 5_000
        trial_receive_start_ms = receive_start_ms + trial_number * 5_000
        for sample_index in range(samples_per_trial):
            # Trial two deliberately contains one missing device packet so the
            # validator's gap reporting is exercised by a deterministic fixture.
            has_gap = trial_number == 1 and sample_index >= samples_per_trial // 2
            if trial_number == 1 and sample_index == samples_per_trial // 2:
                sequence += 1
            progress = sample_index / (samples_per_trial - 1)
            envelope = math.sin(math.pi * progress) ** 2
            motion = math.sin((2.0 * math.pi * progress) + phase) * envelope
            time_index = sample_index + int(has_gap)
            device_timestamp_ms = round(
                trial_device_start_ms + time_index * interval_ms
            )
            receive_timestamp_ms = round(
                trial_receive_start_ms + time_index * interval_ms
            ) + 8 + rng.randint(0, 3)
            flex = [
                round(500 - finger * 12 - (180 + finger * 15) * envelope + rng.gauss(0, 2))
                for finger in range(5)
            ]
            orientation_ax = 0.0 if orientation == "neutral" else 0.30
            orientation_az = 0.0 if orientation == "neutral" else -0.08
            ax = 0.10 + orientation_ax + 0.55 * motion + rng.gauss(0, 0.005)
            ay = 0.05 + 0.25 * envelope + rng.gauss(0, 0.005)
            az = 0.99 + orientation_az - 0.12 * envelope + rng.gauss(0, 0.005)
            gx = 42.0 * motion + rng.gauss(0, 0.08)
            gy = 16.0 * envelope + rng.gauss(0, 0.08)
            gz = -22.0 * motion + rng.gauss(0, 0.08)
            raw_packet = (
                f"seq={sequence},t_ms={device_timestamp_ms},who=0x70,"
                f"ax={ax:.3f},ay={ay:.3f},az={az:.3f},"
                f"gx={gx:.3f},gy={gy:.3f},gz={gz:.3f},"
                + ",".join(f"flex{i}_raw={value}" for i, value in enumerate(flex))
            )
            rows.append(
                {
                    "schema_version": SCHEMA_VERSION,
                    "session_id": session_id,
                    "trial_id": trial_id,
                    "sample_index": sample_index,
                    "device_sequence": sequence,
                    "device_timestamp_ms": device_timestamp_ms,
                    "receive_timestamp_ms": receive_timestamp_ms,
                    "word": word,
                    "vocabulary_version": FIXTURE_VOCABULARY_VERSION,
                    "signer_id": "signer_fixture",
                    "orientation_condition": orientation,
                    "who": "0x70",
                    "ax": f"{ax:.6f}",
                    "ay": f"{ay:.6f}",
                    "az": f"{az:.6f}",
                    "gx": f"{gx:.6f}",
                    "gy": f"{gy:.6f}",
                    "gz": f"{gz:.6f}",
                    "flex_thumb_raw": flex[0],
                    "flex_index_raw": flex[1],
                    "flex_middle_raw": flex[2],
                    "flex_ring_raw": flex[3],
                    "flex_pinky_raw": flex[4],
                    "raw_packet": raw_packet,
                    "packet_valid": "true",
                }
            )
            sequence += 1

    with csv_path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=REQUIRED_COLUMNS)
        writer.writeheader()
        writer.writerows(rows)

    manifest = {
        "schema_version": SCHEMA_VERSION,
        "session_id": session_id,
        "data_origin": "synthetic_fixture",
        "synthetic_fixture": True,
        "seed": seed,
        "created_at": datetime.fromtimestamp(
            receive_start_ms / 1000, tz=timezone.utc
        ).isoformat(),
        "target_sample_rate_hz": sample_rate_hz,
        "vocabulary_version": FIXTURE_VOCABULARY_VERSION,
        "vocabulary": list(FIXTURE_VOCABULARY),
        "trial_count": len(trial_specs),
        "packet_count": len(rows),
        "accuracy_reporting_allowed": False,
    }
    manifest_path.write_text(
        json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    return csv_path, manifest_path


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output_directory", type=Path)
    parser.add_argument("--seed", type=int, default=7)
    parser.add_argument("--sample-rate-hz", type=int, default=40)
    parser.add_argument("--samples-per-trial", type=int, default=64)
    args = parser.parse_args(argv)
    csv_path, manifest_path = generate_fixture_session(
        args.output_directory,
        seed=args.seed,
        sample_rate_hz=args.sample_rate_hz,
        samples_per_trial=args.samples_per_trial,
    )
    print(f"Synthetic fixture CSV: {csv_path}")
    print(f"Synthetic fixture manifest: {manifest_path}")
    print("Synthetic fixture only; excluded from real-data accuracy reporting.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
