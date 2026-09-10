from __future__ import annotations

import numpy as np
import pytest

from backend.evaluate_word_models import evaluate_probabilities
from backend.word_data import FEATURE_COLUMNS
from backend.word_dataset import SequenceExample


def _example(index: int) -> SequenceExample:
    return SequenceExample(
        session_id="session_test",
        trial_id=f"trial_{index:03d}",
        word=f"word_{index}",
        signer_id=f"signer_{index % 2}",
        orientation_condition="neutral" if index % 2 == 0 else "pitch_up",
        schema_version="word-sequence-v1",
        vocabulary_version="words-test-v1",
        data_origin="synthetic_fixture",
        target_rate_hz=40,
        feature_columns=tuple(FEATURE_COLUMNS),
        values=np.zeros((8, len(FEATURE_COLUMNS)), dtype=np.float32),
        source_sample_count=8,
        valid_sample_count=8,
        resampled_sample_count=8,
        trimmed_samples=0,
        padded_samples=0,
    )


def test_evaluation_reports_required_metrics_and_groups() -> None:
    vocabulary = tuple(f"word_{index}" for index in range(6))
    expected = np.arange(6)
    probabilities = np.full((6, 6), 0.02, dtype=np.float64)
    probabilities[np.arange(6), expected] = 0.90
    probabilities[:, 0] += 1.0 - probabilities.sum(axis=1)

    report = evaluate_probabilities(
        expected,
        probabilities,
        vocabulary=vocabulary,
        examples=tuple(_example(index) for index in range(6)),
        split_name="test",
        data_origin="real",
    )

    assert report["accuracy_reporting_allowed"] is True
    assert report["final_accuracy_claim_ready"] is False
    assert report["overall"]["top_1_accuracy"] == pytest.approx(1.0)
    assert report["overall"]["top_5_accuracy"] == pytest.approx(1.0)
    assert report["overall"]["macro_f1"] == pytest.approx(1.0)
    assert set(report["by_signer"]) == {"signer_0", "signer_1"}
    assert set(report["by_orientation"]) == {"neutral", "pitch_up"}
    assert len(report["confusion_matrix"]["rows_expected_columns_predicted"]) == 6
    assert report["latency_ms"] is None


def test_fixture_metrics_are_non_reportable_and_top_five_is_not_applicable() -> None:
    report = evaluate_probabilities(
        np.asarray([0, 1]),
        np.asarray([[0.8, 0.2], [0.1, 0.9]]),
        vocabulary=("hello", "thanks"),
        examples=(_example(0), _example(1)),
        split_name="validation",
        data_origin="synthetic_fixture",
    )

    assert report["accuracy_reporting_allowed"] is False
    assert report["final_accuracy_claim_ready"] is False
    assert report["result_scope"] == "synthetic_fixture_software_smoke_only"
    assert report["overall"]["top_5_accuracy"] is None
    assert "must not be reported" in report["warning"]


def test_evaluation_rejects_non_probability_output() -> None:
    with pytest.raises(ValueError, match="normalized probabilities"):
        evaluate_probabilities(
            np.asarray([0, 1]),
            np.asarray([[2.0, 1.0], [1.0, 2.0]]),
            vocabulary=("hello", "thanks"),
            examples=(_example(0), _example(1)),
            split_name="test",
            data_origin="synthetic_fixture",
        )
