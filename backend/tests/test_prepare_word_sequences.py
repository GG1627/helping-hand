from __future__ import annotations

import json
from pathlib import Path

from backend.generate_word_sequence_fixtures import generate_fixture_session
from backend.prepare_word_sequences import main


def test_cli_validates_and_previews_fixture(tmp_path: Path, capsys) -> None:
    csv_path, _ = generate_fixture_session(tmp_path / "fixture")

    exit_code = main(
        [
            str(csv_path),
            "--target-rate-hz",
            "40",
            "--window-samples",
            "80",
        ]
    )

    assert exit_code == 0
    output = json.loads(capsys.readouterr().out)
    assert output["is_valid"] is True
    assert output["recording_count"] == 1
    previews = output["recordings"][0]["preprocessing_preview"]
    assert len(previews) == 2
    assert all(item["window_samples"] == 80 for item in previews)
    assert all(item["feature_count"] == 11 for item in previews)
