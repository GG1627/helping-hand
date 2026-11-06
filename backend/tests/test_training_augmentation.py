from dataclasses import replace
import json

import numpy as np
import pytest

from backend.training_augmentation import AugmentationConfig, TrainingTrial, augment_training_trials


FEATURES = ('flex_thumb_raw', 'gx')


def run(trials=None, config=None, splits=None):
    return augment_training_trials(trials or [TrainingTrial('session/a', 'a', np.full((4, 2), 500.0))],
        feature_columns=FEATURES, split_assignments=splits or {'session/a': 'train'},
        config=config or AugmentationConfig(2, noise_bounds={'flex_thumb_raw': 1},
            offset_bounds={'gx': .5}, measurement_reference='synthetic software test'),
        data_origin='synthetic_fixture')


def test_off_is_identity_and_input_cannot_be_mutated_through_descendants():
    values = np.full((4, 2), 500, dtype=np.float32)
    descendants, manifest = run([TrainingTrial('session/a', 'a', values)], config=AugmentationConfig())
    assert len(descendants) == 1
    np.testing.assert_array_equal(descendants[0].values, values)
    assert descendants[0].weight_multiplier == 1
    assert not descendants[0].values.flags.writeable
    assert manifest['generated_training_descendants'] == 0
    assert manifest['independent_evaluation_evidence_added'] is False


def test_bounded_deterministic_noise_coherent_offset_and_parent_weight():
    descendants, manifest = run()
    repeated, other = run()
    assert manifest == other
    assert len(descendants) == 3
    assert sum(item.weight_multiplier for item in descendants) == pytest.approx(1)
    for item, again in zip(descendants, repeated):
        np.testing.assert_array_equal(item.values, again.values)
        if item.copy_index:
            assert np.max(np.abs(item.values[:, 0] - 500)) <= 1.0001
            assert np.max(np.abs(item.values[:, 1] - 500)) <= .5001
            np.testing.assert_array_equal(item.values[:, 1], np.repeat(item.values[0, 1], 4))
    assert not np.array_equal(descendants[1].values, descendants[2].values)
    assert manifest['records'][1]['origin'] == 'augmented_training'
    assert manifest['records'][1]['parent_split'] == 'train'


@pytest.mark.parametrize('split', ['validation', 'test', 'unknown'])
def test_no_heldout_parent_can_enter_generator(split):
    with pytest.raises(ValueError, match='only training'):
        run(splits={'session/a': split})


def test_seeds_are_parent_specific_and_independent_of_input_order():
    a = TrainingTrial('session/a', 'a', np.full((4, 2), 500))
    b = replace(a, key='session/b', label='b')
    splits = {'session/a': 'train', 'session/b': 'train'}
    forward, _ = run([a, b], splits=splits)
    reverse, _ = run([b, a], splits=splits)
    expected = {(d.parent_key, d.copy_index): d.values for d in forward}
    for item in reverse:
        np.testing.assert_array_equal(item.values, expected[item.parent_key, item.copy_index])
    assert not np.array_equal(forward[1].values, forward[4].values)


def test_padding_is_recreated_from_augmented_observations():
    values = np.array([[500, 500], [500, 500], [600, 600], [600, 600], [600, 600]], dtype=np.float32)
    descendants, _ = run([TrainingTrial('session/a', 'a', values, padded_samples=3)])
    for item in descendants[1:]:
        np.testing.assert_array_equal(item.values[0], item.values[1])
        np.testing.assert_array_equal(item.values[2], item.values[3])
        np.testing.assert_array_equal(item.values[3], item.values[4])


def test_incorrect_padding_provenance_is_rejected():
    values = np.array([[499, 500], [500, 500], [600, 600]], dtype=np.float32)
    with pytest.raises(ValueError, match='padding provenance'):
        run([TrainingTrial('session/a', 'a', values, padded_samples=2)])


def test_noise_and_offset_sum_bound_and_seed_changes_output():
    config = AugmentationConfig(1, noise_bounds={'gx': .25}, offset_bounds={'gx': .5},
                                measurement_reference='fixture only')
    descendants, _ = run(config=config)
    changed, _ = run(config=replace(config, seed=8))
    assert np.max(np.abs(descendants[1].values[:, 1] - 500)) <= .7501
    np.testing.assert_array_equal(descendants[1].values[:, 0], np.full(4, 500))
    assert not np.array_equal(descendants[1].values, changed[1].values)


@pytest.mark.parametrize('kwargs', [{'copies_per_trial': -1}, {'copies_per_trial': True},
    {'seed': -1}, {'noise_bounds': {'gx': float('nan')}}, {'offset_bounds': {'gx': -1}},
    {'copies_per_trial': 1}, {'copies_per_trial': 1, 'measurement_reference': 'missing limits'}])
def test_invalid_or_unmeasured_enabled_settings_are_rejected(kwargs):
    with pytest.raises(ValueError):
        AugmentationConfig(**kwargs)


def test_bad_features_and_adc_overflow_fail_instead_of_clipping_or_filling():
    with pytest.raises(ValueError, match='outside this model'):
        run(config=AugmentationConfig(1, noise_bounds={'missing': 1}, measurement_reference='fixture'))
    with pytest.raises(ValueError, match='ADC range'):
        run([TrainingTrial('session/a', 'a', np.array([[5000, 0]], dtype=np.float32))])
    with pytest.raises(ValueError, match='finite complete'):
        run([TrainingTrial('session/a', 'a', np.array([[np.nan, 0]], dtype=np.float32))])


def test_config_round_trip_and_unknown_keys_are_not_silently_ignored(tmp_path):
    path = tmp_path / 'augmentation.json'
    value = {'schema_version': 'training-augmentation-v1', 'copies_per_trial': 1,
             'noise_bounds': {'gx': .1}, 'measurement_reference': 'fixture only'}
    path.write_text(json.dumps(value))
    assert AugmentationConfig.read(path).noise_bounds['gx'] == .1
    path.write_text(json.dumps(AugmentationConfig.read(path).to_dict()))
    assert AugmentationConfig.read(path).copies_per_trial == 1
    value['enable_on_test'] = True
    path.write_text(json.dumps(value))
    with pytest.raises(ValueError):
        AugmentationConfig.read(path)
