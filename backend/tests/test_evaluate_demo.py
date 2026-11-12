import csv
import json

import pytest

from backend.evaluate_demo import prepare_plan
from backend.generate_word_sequence_fixtures import generate_fixture_session


def plan(tmp_path):
    csv_path, _ = generate_fixture_session(tmp_path / 'fixture')
    with csv_path.open(newline='') as handle:
        rows = list(csv.DictReader(handle))
    first = rows[0]
    value = {'schema_version': 'demo-evaluation-plan-v1', 'mode': 'static',
             'data_origin': 'synthetic_fixture', 'targets': ['A', 'B'],
             'trials': [{'csv': 'fixture/trials.csv', 'session_id': first['session_id'],
                         'trial_id': first['trial_id'], 'kind': 'sign', 'performed_label': 'A'}]}
    path = tmp_path / 'plan.json'
    path.write_text(json.dumps(value))
    return path, value


def test_replay_preserves_raw_evidence_and_labels_timing_assumptions(tmp_path):
    path, _ = plan(tmp_path)
    replay = prepare_plan(path)
    assert replay['timing'] == 'recorded_receive'
    assert replay['model']['source'] == 'predictions_in_original_raw_packets'
    assert replay['trials'][0]['packets'][0]['raw_packet'].startswith('seq=')
    assert replay['trials'][0]['boundary_source'].startswith('constructed')
    assert replay['hardware_validation'] == 'Not run'
    assert replay['final_accuracy_claim_ready'] is False


@pytest.mark.parametrize('change,match', [
    ('origin', 'origin'), ('duplicate', 'Duplicate'), ('kind', 'kind'),
    ('timing', 'timing'), ('target', 'target'), ('boundary', 'both'),
])
def test_invalid_or_misrepresented_plans_are_rejected(tmp_path, change, match):
    path, value = plan(tmp_path)
    if change == 'origin': value['data_origin'] = 'real'
    if change == 'duplicate': value['trials'] *= 2
    if change == 'kind': value['trials'][0]['kind'] = 'unknown_kind'
    if change == 'timing': value['timing'] = 'silently_repair'
    if change == 'target': value['targets'] = ['not_a_letter']
    if change == 'boundary': value['trials'][0]['start_ms'] = 1
    path.write_text(json.dumps(value))
    with pytest.raises(ValueError, match=match):
        prepare_plan(path)


def test_static_candidate_preserves_raw_source_and_tracks_split(tmp_path, monkeypatch):
    class Runtime:
        def __init__(self, directory, mode):
            self.splits = {}
            self.evidence = {'test': 'synthetic_stub'}

        def static_predictions(self, rows):
            return [{'pred': 'A', 'pred_conf': '90.0'} for _ in rows]

    monkeypatch.setattr('backend.evaluate_demo.ModelRuntime', Runtime)
    path, _ = plan(tmp_path)
    result = prepare_plan(path, static_bundle=tmp_path)
    packet = result['trials'][0]['packets'][0]
    assert packet['prediction_override'] == {'pred': 'A', 'pred_conf': '90.0'}
    assert len(packet['candidate_flex_raw']) == 5
    assert packet['raw_packet'].startswith('seq=')
    assert result['trials'][0]['model_split'] == 'not_in_training_manifest'


def test_word_predictions_use_the_explicit_capture_subset(tmp_path, monkeypatch):
    import numpy as np
    from backend.sequence_preprocessing import SequencePreprocessing

    class Runtime:
        def __init__(self, directory, mode):
            self.config = SequencePreprocessing()
            self.splits = {}
            self.evidence = {'test': 'synthetic_stub'}
            self.metadata = {'standardizer': {'method': 'per_feature_standardization',
                'fitted_split': 'train', 'feature_columns': list(self.config.feature_columns),
                'mean': [0] * 11, 'scale': [1] * 11}}

        def predict(self, values):
            return np.array([.9, .05, .05], dtype=np.float32)

    monkeypatch.setattr('backend.evaluate_demo.ModelRuntime', Runtime)
    path, value = plan(tmp_path)
    with (tmp_path / 'fixture/trials.csv').open(newline='') as handle:
        rows = [row for row in csv.DictReader(handle) if row['trial_id'] == value['trials'][0]['trial_id']]
    first_receive = int(rows[0]['receive_timestamp_ms'])
    first_device = int(rows[0]['device_timestamp_ms'])
    value.update(mode='word', targets=['hello'], timing='simulated_device')
    value['trials'][0].update(performed_label='hello',
        start_ms=first_receive + int(rows[2]['device_timestamp_ms']) - first_device,
        finish_ms=first_receive + int(rows[40]['device_timestamp_ms']) - first_device)
    path.write_text(json.dumps(value))
    result = prepare_plan(path)
    prepared = result['trials'][0]
    assert 'prediction_error' not in prepared
    assert prepared['boundary_source'] == 'operator_supplied'
    assert prepared['prepared_input'][0][0] == float(rows[2]['flex_thumb_raw'])
