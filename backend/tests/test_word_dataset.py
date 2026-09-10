from __future__ import annotations

from dataclasses import replace
from pathlib import Path

import numpy as np

from backend.generate_word_sequence_fixtures import generate_fixture_session
from backend.word_data import FEATURE_COLUMNS, load_recording
from backend.word_dataset import (
    SequenceExample,
    SequenceStandardizer,
    SplitManifest,
    create_split_manifest,
    examples_by_split,
    model_arrays,
    prepare_examples,
    validate_split_manifest,
)


def _example(
    index: int,
    *,
    signer: str,
    word: str,
    value: float | None = None,
) -> SequenceExample:
    return SequenceExample(
        session_id=f"session_{index // 4}",
        trial_id=f"trial_{index:03d}",
        word=word,
        signer_id=signer,
        orientation_condition="neutral" if index % 2 == 0 else "pitch_up",
        schema_version="word-sequence-v1",
        vocabulary_version="words-test-v1",
        data_origin="synthetic_fixture",
        target_rate_hz=40.0,
        feature_columns=tuple(FEATURE_COLUMNS),
        values=np.full(
            (8, len(FEATURE_COLUMNS)),
            float(index if value is None else value),
            dtype=np.float32,
        ),
        source_sample_count=8,
        valid_sample_count=8,
        resampled_sample_count=8,
        trimmed_samples=0,
        padded_samples=0,
    )


def test_prepare_examples_preserves_provenance_and_shape(tmp_path: Path) -> None:
    csv_path, _ = generate_fixture_session(tmp_path / "fixture")
    recording = load_recording(csv_path)

    examples = prepare_examples([recording], window_samples=80)

    assert len(examples) == 2
    assert all(item.data_origin == "synthetic_fixture" for item in examples)
    assert all(item.values.shape == (80, len(FEATURE_COLUMNS)) for item in examples)
    assert len({item.trial_key for item in examples}) == len(examples)


def test_user_dependent_split_is_deterministic_and_trial_safe() -> None:
    examples = tuple(
        _example(
            index,
            signer=f"signer_{index // 10}",
            word="hello" if index % 10 < 5 else "thanks",
        )
        for index in range(20)
    )

    first = create_split_manifest(
        examples,
        data_version="dataset-v1",
        strategy="user_dependent",
        seed=19,
    )
    second = create_split_manifest(
        tuple(reversed(examples)),
        data_version="dataset-v1",
        strategy="user_dependent",
        seed=19,
    )

    assert first.to_dict() == second.to_dict()
    assert not validate_split_manifest(first, examples)
    assert len({item.trial_key for item in first.assignments}) == len(examples)
    grouped = examples_by_split(examples, first)
    assert {name: len(items) for name, items in grouped.items()} == {
        "train": 12,
        "validation": 4,
        "test": 4,
    }


def test_user_independent_split_keeps_each_signer_in_one_split() -> None:
    examples = tuple(
        _example(
            index,
            signer=f"signer_{index // 4}",
            word="hello" if index % 2 == 0 else "thanks",
        )
        for index in range(20)
    )
    manifest = create_split_manifest(
        examples,
        data_version="dataset-v1",
        strategy="user_independent",
        seed=23,
    )

    signer_splits: dict[str, set[str]] = {}
    for item in manifest.assignments:
        signer_splits.setdefault(item.signer_id, set()).add(item.split)
    assert all(len(splits) == 1 for splits in signer_splits.values())
    assert {item.split for item in manifest.assignments} == {
        "train",
        "validation",
        "test",
    }


def test_standardizer_fits_training_values_only_and_round_trips() -> None:
    train = (
        _example(0, signer="signer_1", word="hello", value=0),
        _example(1, signer="signer_1", word="thanks", value=2),
    )
    held_out = _example(2, signer="signer_2", word="hello", value=10)

    standardizer = SequenceStandardizer.fit(train)
    transformed = standardizer.transform(held_out.values)
    restored = SequenceStandardizer.from_dict(standardizer.to_dict())

    assert standardizer.mean == (1.0,) * len(FEATURE_COLUMNS)
    assert standardizer.scale == (1.0,) * len(FEATURE_COLUMNS)
    assert np.all(transformed == 9.0)
    assert restored == standardizer


def test_split_manifest_round_trip_and_metadata_tamper_detection(
    tmp_path: Path,
) -> None:
    examples = tuple(
        _example(index, signer="signer_1", word="hello" if index % 2 else "thanks")
        for index in range(10)
    )
    manifest = create_split_manifest(
        examples,
        data_version="dataset-v1",
        strategy="user_dependent",
    )
    path = manifest.write(tmp_path / "split.json")

    loaded = SplitManifest.read(path)
    assert loaded == manifest
    tampered = replace(
        loaded,
        assignments=(
            replace(loaded.assignments[0], signer_id="signer_wrong"),
            *loaded.assignments[1:],
        ),
    )
    assert any(
        "signer_id mismatch" in problem
        for problem in validate_split_manifest(tampered, examples)
    )


def test_model_arrays_use_fixed_vocabulary_order() -> None:
    examples = (
        _example(0, signer="signer_1", word="thanks", value=0),
        _example(1, signer="signer_1", word="hello", value=2),
    )
    standardizer = SequenceStandardizer.fit(examples)

    values, labels = model_arrays(examples, ("hello", "thanks"), standardizer)

    assert values.shape == (2, 8, len(FEATURE_COLUMNS))
    assert labels.tolist() == [1, 0]
