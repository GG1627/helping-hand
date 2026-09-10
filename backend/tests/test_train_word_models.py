from __future__ import annotations

from pathlib import Path

from backend.generate_word_sequence_fixtures import generate_fixture_session
from backend.train_word_models import main


def test_training_cli_requires_explicit_synthetic_smoke_flag(
    tmp_path: Path, capsys
) -> None:
    csv_path, _ = generate_fixture_session(tmp_path / "fixture")
    output = tmp_path / "model-run"

    exit_code = main(
        [
            str(csv_path),
            "--data-version",
            "synthetic-test-v1",
            "--output-directory",
            str(output),
            "--window-samples",
            "16",
        ]
    )

    assert exit_code == 2
    assert "requires --allow-synthetic-smoke" in capsys.readouterr().out
    assert not output.exists()
