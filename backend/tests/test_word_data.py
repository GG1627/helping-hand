from __future__ import annotations

import csv
import json
from pathlib import Path

import pytest

from backend.generate_word_sequence_fixtures import (
    FIXTURE_VOCABULARY,
    generate_fixture_session,
)
from backend.word_data import (
    FEATURE_COLUMNS,
    REQUIRED_COLUMNS,
    fixed_window,
    load_recording,
    resample_trial,
)


def _read_rows(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8", newline="") as handle:
        return list(csv.DictReader(handle))


def _write_rows(path: Path, rows: list[dict[str, str]], fieldnames=REQUIRED_COLUMNS) -> None:
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)


def test_generated_fixture_is_deterministic_and_valid(tmp_path: Path) -> None:
    first = tmp_path / "first"
    second = tmp_path / "second"
    first_csv, first_manifest = generate_fixture_session(first, seed=11)
    second_csv, second_manifest = generate_fixture_session(second, seed=11)

    assert first_csv.read_bytes() == second_csv.read_bytes()
    assert first_manifest.read_bytes() == second_manifest.read_bytes()

    recording = load_recording(first_csv, expected_labels=FIXTURE_VOCABULARY)
    assert recording.report.is_valid
    assert recording.report.error_count == 0
    assert len(recording.report.trials) == 2
    assert all(summary.packet_count == 64 for summary in recording.report.trials)
    assert all(summary.observed_rate_hz == pytest.approx(40, rel=0.02) for summary in recording.report.trials)
    assert recording.manifest is not None
    assert recording.manifest["data_origin"] == "synthetic_fixture"
    assert any(issue.code == "device_sequence_gap" for issue in recording.report.issues)


def test_missing_column_and_bad_numeric_are_reported(tmp_path: Path) -> None:
    fixture_dir = tmp_path / "fixture"
    csv_path, _ = generate_fixture_session(fixture_dir)
    rows = _read_rows(csv_path)
    rows[0]["ax"] = "not-a-number"
    reduced_fields = tuple(name for name in REQUIRED_COLUMNS if name != "raw_packet")
    broken_path = fixture_dir / "broken.csv"
    _write_rows(broken_path, rows, reduced_fields)

    recording = load_recording(broken_path, manifest_path=fixture_dir / "manifest.json")
    codes = {issue.code for issue in recording.report.issues}
    assert not recording.report.is_valid
    assert "missing_columns" in codes
    assert "invalid_numeric" in codes
    assert recording.report.parsed_row_count == recording.report.row_count - 1
    assert recording.report.trials[0].packet_count == 64
    assert recording.report.trials[0].valid_packet_count == 63


def test_label_timestamp_sequence_and_metadata_checks(tmp_path: Path) -> None:
    fixture_dir = tmp_path / "fixture"
    csv_path, _ = generate_fixture_session(fixture_dir)
    rows = _read_rows(csv_path)
    rows[1]["device_timestamp_ms"] = str(int(rows[0]["device_timestamp_ms"]) - 1)
    rows[2]["device_sequence"] = rows[1]["device_sequence"]
    rows[3]["word"] = "NOT VALID"
    rows[4]["signer_id"] = "Real Person"
    _write_rows(csv_path, rows)

    recording = load_recording(csv_path, expected_labels=FIXTURE_VOCABULARY)
    codes = {issue.code for issue in recording.report.issues}
    assert "timestamp_not_monotonic" in codes
    assert "device_sequence_not_monotonic" in codes
    assert "invalid_label" in codes
    assert "invalid_signer_id" in codes
    assert "inconsistent_trial_metadata" in codes


def test_resample_and_fixed_window_preserve_trial_boundaries(tmp_path: Path) -> None:
    csv_path, _ = generate_fixture_session(
        tmp_path / "fixture", sample_rate_hz=40, samples_per_trial=64
    )
    recording = load_recording(csv_path)
    trial = next(iter(recording.trials().values()))

    resampled = resample_trial(trial, target_rate_hz=40)
    padded = fixed_window(resampled, window_size=80)
    trimmed = fixed_window(resampled, window_size=32)

    assert 63 <= len(resampled.values) <= 64
    assert len(resampled.values[0]) == len(FEATURE_COLUMNS)
    assert len(padded.values) == 80
    assert padded.padded_samples == 80 - len(resampled.values)
    assert padded.trimmed_samples == 0
    assert len(trimmed.values) == 32
    assert trimmed.trimmed_samples == len(resampled.values) - 32
    assert trimmed.padded_samples == 0


def test_manifest_vocabulary_is_used_when_no_override_is_given(tmp_path: Path) -> None:
    fixture_dir = tmp_path / "fixture"
    csv_path, manifest_path = generate_fixture_session(fixture_dir)
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    manifest["vocabulary"] = ["fixture_wave"]
    manifest_path.write_text(json.dumps(manifest), encoding="utf-8")

    recording = load_recording(csv_path)
    assert any(issue.code == "unknown_label" for issue in recording.report.issues)
