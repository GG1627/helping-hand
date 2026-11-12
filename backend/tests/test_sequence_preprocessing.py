from dataclasses import replace
import json
from pathlib import Path

import pytest

from backend.generate_word_sequence_fixtures import generate_fixture_session
from backend.prepare_word_sequences import main as preview
from backend.sequence_preprocessing import SequencePreprocessing, FEATURE_SETS
from backend.word_data import load_recording, resample_trial, fixed_window
from backend.word_dataset import prepare_examples
from backend.export_preprocessing_fixtures import fixture_cases


def test_longer_strict_window_keeps_the_resampled_attempt(tmp_path):
    csv, _ = generate_fixture_session(tmp_path / "fixture", samples_per_trial=133)
    recording = load_recording(csv)
    baseline = prepare_examples([recording], window_samples=96)
    config = SequencePreprocessing(224, 40, window_policy="reject_overlength_edge_pad")
    longer = prepare_examples([recording], window_samples=224, preprocessing=config)
    assert any(e.trimmed_samples > 0 for e in baseline)
    assert all(e.trimmed_samples == 0 and e.values.shape == (224, 11) for e in longer)
    assert [e.trial_key for e in longer] == [e.trial_key for e in baseline]
    with pytest.raises(ValueError, match="refusing to trim"):
        prepare_examples([recording], window_samples=96,
                         preprocessing=SequencePreprocessing(96, window_policy="reject_overlength_edge_pad"))


def test_magnetic_features_require_every_valid_sample(tmp_path):
    csv, _ = generate_fixture_session(tmp_path / "fixture")
    recording = load_recording(csv)
    config = SequencePreprocessing(96, feature_set="flex_imu9")
    with pytest.raises(ValueError, match="complete magnetic"):
        prepare_examples([recording], window_samples=96, preprocessing=config)
    samples = next(iter(recording.trials().values()))
    magnetic = [replace(s, mag_status="ok", mx_ut=0, my_ut=-12.5, mz_ut=31.2) for s in samples]
    values = resample_trial(magnetic, feature_columns=FEATURE_SETS['flex_imu9']).values
    assert len(values[0]) == 14
    assert values[0][-3:] == (0, -12.5, 31.2)
    magnetic[1] = replace(magnetic[1], mx_ut=None)
    with pytest.raises(ValueError, match="finite and present"):
        resample_trial(magnetic, feature_columns=FEATURE_SETS['flex_imu9'])


def test_explicit_metadata_cannot_disagree_with_features_or_dimensions():
    config = SequencePreprocessing(224, window_policy="reject_overlength_edge_pad")
    metadata = {'window_samples': 224, 'target_rate_hz': 40,
                'feature_columns': list(config.feature_columns),
                'standardizer': {'feature_columns': list(config.feature_columns)},
                'preprocessing': config.to_dict()}
    assert SequencePreprocessing.from_metadata(metadata) == config
    metadata['window_samples'] = 96
    with pytest.raises(ValueError, match="conflicts"):
        SequencePreprocessing.from_metadata(metadata)


def test_preview_returns_failure_for_rejected_windows(tmp_path, capsys):
    csv, _ = generate_fixture_session(tmp_path / "fixture", samples_per_trial=133)
    assert preview([str(csv), '--window-samples', '96', '--window-policy',
                    'reject_overlength_edge_pad']) == 1
    result = json.loads(capsys.readouterr().out)
    assert result['is_valid'] is False
    assert any('error' in p for p in result['recordings'][0]['preprocessing_preview'])


@pytest.mark.parametrize('kwargs', [{'window_samples': 0}, {'window_samples': 401},
    {'window_samples': True}, {'target_rate_hz': 0}, {'feature_set': 'fusion'},
    {'window_policy': 'guess'}])
def test_invalid_configurations_are_rejected(kwargs):
    with pytest.raises(ValueError):
        SequencePreprocessing(**kwargs)


def test_shared_flutter_fixture_is_current_and_software_only():
    path = Path(__file__).resolve().parents[2] / 'flutter_app/test/fixtures/sequence_preprocessing_v1.json'
    saved = json.loads(path.read_text())
    assert saved == fixture_cases()
    assert saved['accuracy_reporting_allowed'] is False
