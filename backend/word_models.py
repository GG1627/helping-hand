"""Configurable sequence-model candidates for Helping Hand word recognition.

The builders define untrained Keras models only. Model accuracy cannot be
claimed until the same candidates are trained and evaluated on approved real
recordings and identical split manifests.
"""

from __future__ import annotations

import json
import math
import tempfile
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any

import tensorflow as tf
from tensorflow import keras

try:
    from .word_data import FEATURE_COLUMNS
except ImportError:  # Direct execution from backend/.
    from word_data import FEATURE_COLUMNS  # type: ignore[no-redef]


ARCHITECTURES = ("tcn", "cnn_gru", "cnn_lstm")
MODEL_SCHEMA_VERSION = "word-model-config-v1"


@dataclass(frozen=True)
class WordModelConfig:
    """Shape and capacity settings shared by all model candidates."""

    architecture: str
    window_samples: int
    num_classes: int
    feature_count: int = len(FEATURE_COLUMNS)
    conv_filters: int = 32
    recurrent_units: int = 32
    dense_units: int = 32
    kernel_size: int = 5
    dropout: float = 0.25
    l2_regularization: float = 1e-4
    learning_rate: float = 1e-3

    def __post_init__(self) -> None:
        if self.architecture not in ARCHITECTURES:
            raise ValueError(
                f"architecture must be one of {ARCHITECTURES}; "
                f"got {self.architecture!r}"
            )
        for name in (
            "window_samples",
            "num_classes",
            "feature_count",
            "conv_filters",
            "recurrent_units",
            "dense_units",
            "kernel_size",
        ):
            if getattr(self, name) < 1:
                raise ValueError(f"{name} must be positive")
        if self.window_samples < 4:
            raise ValueError("window_samples must be at least 4")
        if self.num_classes < 2:
            raise ValueError("num_classes must be at least 2")
        if not math.isfinite(self.dropout) or not 0 <= self.dropout < 1:
            raise ValueError("dropout must be finite and in [0, 1)")
        if not math.isfinite(self.l2_regularization) or self.l2_regularization < 0:
            raise ValueError("l2_regularization must be finite and nonnegative")
        if not math.isfinite(self.learning_rate) or self.learning_rate <= 0:
            raise ValueError("learning_rate must be finite and positive")

    def to_dict(self) -> dict[str, object]:
        return {"schema_version": MODEL_SCHEMA_VERSION, **asdict(self)}

    @classmethod
    def from_dict(cls, value: dict[str, Any]) -> "WordModelConfig":
        if value.get("schema_version") not in {None, MODEL_SCHEMA_VERSION}:
            raise ValueError("unsupported word model configuration schema")
        fields = {
            name: value[name] for name in cls.__dataclass_fields__ if name in value
        }
        try:
            return cls(**fields)
        except (TypeError, ValueError) as exc:
            raise ValueError(f"invalid word model configuration: {exc}") from exc


def _regularizer(config: WordModelConfig) -> keras.regularizers.Regularizer | None:
    if config.l2_regularization == 0:
        return None
    return keras.regularizers.l2(config.l2_regularization)


def _tcn_residual_block(
    inputs: keras.KerasTensor,
    *,
    config: WordModelConfig,
    dilation_rate: int,
    block_index: int,
) -> keras.KerasTensor:
    regularizer = _regularizer(config)
    residual = inputs
    x = keras.layers.Conv1D(
        config.conv_filters,
        config.kernel_size,
        padding="causal",
        dilation_rate=dilation_rate,
        use_bias=False,
        kernel_regularizer=regularizer,
        name=f"tcn_{block_index}_conv_1",
    )(inputs)
    x = keras.layers.BatchNormalization(name=f"tcn_{block_index}_bn_1")(x)
    x = keras.layers.Activation("relu", name=f"tcn_{block_index}_relu_1")(x)
    x = keras.layers.SpatialDropout1D(
        config.dropout, name=f"tcn_{block_index}_dropout"
    )(x)
    x = keras.layers.Conv1D(
        config.conv_filters,
        config.kernel_size,
        padding="causal",
        dilation_rate=dilation_rate,
        use_bias=False,
        kernel_regularizer=regularizer,
        name=f"tcn_{block_index}_conv_2",
    )(x)
    x = keras.layers.BatchNormalization(name=f"tcn_{block_index}_bn_2")(x)
    x = keras.layers.Add(name=f"tcn_{block_index}_residual")([residual, x])
    return keras.layers.Activation("relu", name=f"tcn_{block_index}_relu_2")(x)


def _build_tcn(inputs: keras.KerasTensor, config: WordModelConfig) -> keras.KerasTensor:
    x = keras.layers.Conv1D(
        config.conv_filters,
        1,
        padding="same",
        kernel_regularizer=_regularizer(config),
        name="tcn_input_projection",
    )(inputs)
    for block_index, dilation_rate in enumerate((1, 2, 4), start=1):
        x = _tcn_residual_block(
            x,
            config=config,
            dilation_rate=dilation_rate,
            block_index=block_index,
        )
    return keras.layers.GlobalAveragePooling1D(name="temporal_average")(x)


def _build_cnn_recurrent(
    inputs: keras.KerasTensor, config: WordModelConfig
) -> keras.KerasTensor:
    regularizer = _regularizer(config)
    x = keras.layers.Conv1D(
        config.conv_filters,
        config.kernel_size,
        padding="same",
        use_bias=False,
        kernel_regularizer=regularizer,
        name="cnn_conv_1",
    )(inputs)
    x = keras.layers.BatchNormalization(name="cnn_bn_1")(x)
    x = keras.layers.Activation("relu", name="cnn_relu_1")(x)
    x = keras.layers.MaxPooling1D(pool_size=2, name="cnn_pool")(x)
    x = keras.layers.SpatialDropout1D(config.dropout, name="cnn_dropout")(x)
    x = keras.layers.Conv1D(
        config.conv_filters * 2,
        3,
        padding="same",
        activation="relu",
        kernel_regularizer=regularizer,
        name="cnn_conv_2",
    )(x)
    recurrent_kwargs = {
        "units": config.recurrent_units,
        "dropout": 0.0,
        "recurrent_dropout": 0.0,
        "return_sequences": False,
        # The input window is fixed for deployment. Unrolling avoids TensorList
        # ops that require Select TensorFlow/Flex during TFLite conversion.
        "unroll": True,
        "kernel_regularizer": regularizer,
        "recurrent_regularizer": regularizer,
        "name": config.architecture.removeprefix("cnn_"),
    }
    if config.architecture == "cnn_gru":
        return keras.layers.GRU(**recurrent_kwargs)(x)
    return keras.layers.LSTM(**recurrent_kwargs)(x)


def build_word_model(
    config: WordModelConfig, *, compile_model: bool = True
) -> keras.Model:
    """Build one untrained candidate with a fixed deployment input shape."""

    inputs = keras.Input(
        shape=(config.window_samples, config.feature_count),
        dtype="float32",
        name="sensor_sequence",
    )
    if config.architecture == "tcn":
        x = _build_tcn(inputs, config)
    else:
        x = _build_cnn_recurrent(inputs, config)
    x = keras.layers.Dense(
        config.dense_units,
        activation="relu",
        kernel_regularizer=_regularizer(config),
        name="classifier_hidden",
    )(x)
    x = keras.layers.Dropout(config.dropout, name="classifier_dropout")(x)
    outputs = keras.layers.Dense(
        config.num_classes,
        activation="softmax",
        name="word_probabilities",
    )(x)
    model = keras.Model(inputs=inputs, outputs=outputs, name=config.architecture)
    if compile_model:
        metrics: list[keras.metrics.Metric] = [
            keras.metrics.SparseCategoricalAccuracy(name="top_1_accuracy")
        ]
        if config.num_classes >= 5:
            metrics.append(
                keras.metrics.SparseTopKCategoricalAccuracy(k=5, name="top_5_accuracy")
            )
        model.compile(
            optimizer=keras.optimizers.Adam(learning_rate=config.learning_rate),
            loss=keras.losses.SparseCategoricalCrossentropy(),
            metrics=metrics,
        )
    return model


def convert_to_tflite(
    model: keras.Model, *, temporary_parent: str | Path | None = None
) -> bytes:
    """Convert a float model with built-in TFLite operators only.

    Quantization is intentionally deferred until representative real training
    data exists. Failure here is a deployment-compatibility signal and is not
    hidden by automatically enabling Select TensorFlow operators.
    """

    # TensorFlow 2.21 paired with Keras 3 can fail in the direct
    # ``from_keras_model`` trace path. Exporting the same fixed signature to a
    # temporary SavedModel is stable and is also closer to the release flow.
    with tempfile.TemporaryDirectory(
        prefix="helping_hand_word_model_",
        dir=temporary_parent,
    ) as temporary:
        model.export(temporary, format="tf_saved_model", verbose=False)
        converter = tf.lite.TFLiteConverter.from_saved_model(temporary)
        converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS]
        return converter.convert()


def write_model_config(config: WordModelConfig, path: str | Path) -> Path:
    output = Path(path)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(
        json.dumps(config.to_dict(), indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    return output
