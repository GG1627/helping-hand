from __future__ import annotations

from pathlib import Path

import numpy as np
import pytest
import tensorflow as tf
from tensorflow import keras

from backend.word_models import (
    ARCHITECTURES,
    WordModelConfig,
    build_word_model,
    convert_to_tflite,
)


def _config(architecture: str) -> WordModelConfig:
    return WordModelConfig(
        architecture=architecture,
        window_samples=16,
        num_classes=6,
        feature_count=11,
        conv_filters=4,
        recurrent_units=4,
        dense_units=4,
        dropout=0.1,
    )


@pytest.mark.parametrize("architecture", ARCHITECTURES)
def test_model_candidate_has_expected_contract(architecture: str) -> None:
    model = build_word_model(_config(architecture))
    probabilities = model(np.zeros((2, 16, 11), dtype=np.float32), training=False)

    assert model.input_shape == (None, 16, 11)
    assert model.output_shape == (None, 6)
    assert probabilities.shape == (2, 6)
    assert np.allclose(np.sum(probabilities.numpy(), axis=1), 1.0)
    assert model.count_params() > 0
    keras.backend.clear_session()


@pytest.mark.parametrize("architecture", ARCHITECTURES)
def test_model_candidate_converts_with_builtin_tflite_ops(
    architecture: str, tmp_path: Path
) -> None:
    model = build_word_model(_config(architecture), compile_model=False)
    converted = convert_to_tflite(model, temporary_parent=tmp_path)
    interpreter = tf.lite.Interpreter(model_content=converted)
    interpreter.allocate_tensors()
    input_detail = interpreter.get_input_details()[0]
    output_detail = interpreter.get_output_details()[0]
    interpreter.set_tensor(
        input_detail["index"], np.zeros((1, 16, 11), dtype=np.float32)
    )
    interpreter.invoke()
    probabilities = interpreter.get_tensor(output_detail["index"])

    assert len(converted) > 0
    assert tuple(input_detail["shape"]) == (1, 16, 11)
    assert tuple(output_detail["shape"]) == (1, 6)
    assert np.allclose(np.sum(probabilities, axis=1), 1.0, atol=1e-5)
    keras.backend.clear_session()


def test_model_configuration_round_trip_and_validation() -> None:
    config = _config("cnn_gru")

    assert WordModelConfig.from_dict(config.to_dict()) == config
    with pytest.raises(ValueError, match="architecture"):
        WordModelConfig(architecture="transformer", window_samples=16, num_classes=6)
    with pytest.raises(ValueError, match="num_classes"):
        WordModelConfig(architecture="tcn", window_samples=16, num_classes=1)
