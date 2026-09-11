"""Validate word-recording exports and preview fixed sequence preparation.

No model is trained by this command. Synthetic fixture input remains clearly
identified in its manifest and must not be used for real-data accuracy claims.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

try:
    from .word_data import (
        DEFAULT_MIN_PACKET_COUNT,
        DEFAULT_TARGET_RATE_HZ,
        fixed_window,
        load_recording,
        resample_trial,
    )
except ImportError:  # Direct execution from backend/.
    from word_data import (  # type: ignore[no-redef]
        DEFAULT_MIN_PACKET_COUNT,
        DEFAULT_TARGET_RATE_HZ,
        fixed_window,
        load_recording,
        resample_trial,
    )


def _load_vocabulary(path: Path | None) -> list[str] | None:
    if path is None:
        return None
    text = path.read_text(encoding="utf-8")
    if path.suffix.lower() == ".json":
        value = json.loads(text)
        if isinstance(value, dict):
            value = value.get("vocabulary")
        if not isinstance(value, list) or not all(isinstance(item, str) for item in value):
            raise ValueError("JSON vocabulary must be a list or an object with a vocabulary list")
        return value
    return [line.strip() for line in text.splitlines() if line.strip() and not line.startswith("#")]


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Validate Helping Hand word CSV exports without training a model."
    )
    parser.add_argument(
        "csv", nargs="+", type=Path, help="Path(s) to exported trials.csv files"
    )
    parser.add_argument(
        "--manifest",
        type=Path,
        help="Manifest path (defaults to manifest.json beside the CSV)",
    )
    parser.add_argument(
        "--vocabulary",
        type=Path,
        help="Optional newline-delimited or JSON vocabulary used for label validation",
    )
    parser.add_argument(
        "--min-packets", type=int, default=DEFAULT_MIN_PACKET_COUNT
    )
    parser.add_argument(
        "--target-rate-hz", type=float, default=DEFAULT_TARGET_RATE_HZ
    )
    parser.add_argument(
        "--window-samples",
        type=int,
        help="Preview resample + center-trim/edge-pad shapes for valid trials",
    )
    parser.add_argument("--report-json", type=Path, help="Also write the report as JSON")
    parser.add_argument(
        "--fail-on-warning",
        action="store_true",
        help="Return nonzero when quality warnings are present",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        vocabulary = _load_vocabulary(args.vocabulary)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"Vocabulary error: {exc}")
        return 2

    if args.manifest is not None and len(args.csv) != 1:
        print("--manifest can only be used with one CSV path")
        return 2

    recordings = [
        load_recording(
            csv_path,
            manifest_path=args.manifest,
            expected_labels=vocabulary,
            min_packet_count=args.min_packets,
            target_rate_hz=args.target_rate_hz,
        )
        for csv_path in args.csv
    ]
    reports: list[dict[str, object]] = []
    for recording in recordings:
        report = recording.report.to_dict()
        if args.window_samples is not None:
            previews: list[dict[str, object]] = []
            for (session_id, trial_id), samples in recording.trials().items():
                try:
                    resampled = resample_trial(
                        samples, target_rate_hz=args.target_rate_hz
                    )
                    window = fixed_window(resampled, window_size=args.window_samples)
                    previews.append(
                        {
                            "session_id": session_id,
                            "trial_id": trial_id,
                            "resampled_samples": len(resampled.values),
                            "window_samples": len(window.values),
                            "feature_count": len(window.values[0]),
                            "trimmed_samples": window.trimmed_samples,
                            "padded_samples": window.padded_samples,
                        }
                    )
                except ValueError as exc:
                    previews.append(
                        {
                            "session_id": session_id,
                            "trial_id": trial_id,
                            "error": str(exc),
                        }
                    )
            report["preprocessing_preview"] = previews
        reports.append(report)

    output = {
        "is_valid": all(recording.report.is_valid for recording in recordings),
        "recording_count": len(recordings),
        "recordings": reports,
    }

    rendered = json.dumps(output, indent=2, sort_keys=True)
    print(rendered)
    if args.report_json is not None:
        args.report_json.parent.mkdir(parents=True, exist_ok=True)
        args.report_json.write_text(f"{rendered}\n", encoding="utf-8")

    if not all(recording.report.is_valid for recording in recordings):
        return 1
    if args.fail_on_warning and any(
        recording.report.warning_count for recording in recordings
    ):
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
