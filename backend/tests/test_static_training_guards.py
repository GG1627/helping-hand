"""Reject mislabeled smoke runs and stale trial splits before fitting a model."""
import faulthandler
import json
import sys

import pandas as pd
import pytest

from backend import train_static_recorded as trainer


@pytest.fixture
def recording(tmp_path, monkeypatch):
    rows = []
    for label in ('A', 'B'):
        for trial in range(3):
            rows.append(dict(session_id='fixture', trial_id=f'{label}_{trial}', word=label,
                             sample_index=0, packet_valid=True, vocabulary_version='static-asl-v1',
                             **{feature: 500 for feature in trainer.FEATURES}))
    path = tmp_path / 'trials.csv'
    pd.DataFrame(rows).to_csv(path, index=False)
    (tmp_path / 'manifest.json').write_text(json.dumps({'data_origin': 'synthetic_fixture'}))
    monkeypatch.setattr(trainer.tf.config.threading, 'set_inter_op_parallelism_threads', lambda _: None)
    monkeypatch.setattr(trainer.tf.config.threading, 'set_intra_op_parallelism_threads', lambda _: None)
    monkeypatch.setattr(trainer.tf.keras.utils, 'set_random_seed', lambda _: None)
    return path


def invoke(recording, monkeypatch, *options):
    monkeypatch.setattr(sys, 'argv', ['train_static_recorded.py', str(recording),
                                     '--output-directory', str(recording.parent / 'output'), *options])
    try:
        trainer.main()
    finally:
        faulthandler.cancel_dump_traceback_later()
    pytest.fail('Guard should have rejected the run before training')


def test_fixture_requires_explicit_smoke_flag(recording, monkeypatch):
    with pytest.raises(ValueError, match='require --allow-synthetic-smoke'):
        invoke(recording, monkeypatch)
    assert not (recording.parent / 'output').exists()


def test_fixture_cannot_generate_deployment_header(recording, monkeypatch):
    header = recording.parent / 'model.h'
    with pytest.raises(ValueError, match='must not be exported'):
        invoke(recording, monkeypatch, '--allow-synthetic-smoke', '--export-header', str(header))
    assert not header.exists()


@pytest.mark.parametrize('valid_coverage', [True, False])
def test_frozen_split_requires_same_sources_and_exact_trial_coverage(recording, monkeypatch, valid_coverage):
    assignments = {f'fixture/{label}_{index}': split for label in ('A', 'B')
                   for index, split in enumerate(('train', 'validation', 'test'))}
    if not valid_coverage:
        assignments.pop('fixture/A_0')
    path = recording.parent / 'split.json'
    path.write_text(json.dumps({'assignments': assignments, 'sources': [{'sha256': 'changed-source'}]}))
    expected = 'source CSV hashes' if valid_coverage else 'every selected trial'
    with pytest.raises(ValueError, match=expected):
        invoke(recording, monkeypatch, '--allow-synthetic-smoke', '--split-manifest', str(path))
    assert not (recording.parent / 'output').exists()
