import 'dart:math' as math;
import 'dart:typed_data';

import 'ble_packet.dart';

const trainedWords = <String>['hello', 'please', 'yes'];
const wordFeatureColumns = <String>[
  'flex_thumb_raw',
  'flex_index_raw',
  'flex_middle_raw',
  'flex_ring_raw',
  'flex_pinky_raw',
  'ax',
  'ay',
  'az',
  'gx',
  'gy',
  'gz',
];
const magneticWordFeatureColumns = <String>[
  ...wordFeatureColumns,
  'mx_ut',
  'my_ut',
  'mz_ut',
];

String displayWord(String word) => word
    .split('_')
    .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
    .join(' ');

class WordFrame {
  WordFrame(
    this.timestampMs,
    this.sequence,
    List<double> values, {
    List<double>? magneticValues,
  }) : values = List.unmodifiable(values),
       magneticValues = magneticValues == null
           ? null
           : List.unmodifiable(magneticValues);
  factory WordFrame.fromPacket(BlePacket packet) {
    if (!packet.isValid ||
        packet.deviceTimestampMs! < 0 ||
        packet.deviceSequence! < 0 ||
        packet.flexRaw.any((value) => value! < 0 || value > 4095)) {
      throw const FormatException('Incomplete glove sensor packet.');
    }
    return WordFrame(
      packet.deviceTimestampMs!,
      packet.deviceSequence!,
      [
        ...packet.flexRaw.map((value) => value!.toDouble()),
        packet.ax!,
        packet.ay!,
        packet.az!,
        packet.gx!,
        packet.gy!,
        packet.gz!,
      ],
      magneticValues: packet.hasMagneticData
          ? [packet.mx!, packet.my!, packet.mz!]
          : null,
    );
  }
  final int timestampMs;
  final int sequence;
  final List<double> values;
  final List<double>? magneticValues;
}

class WordModelSpec {
  WordModelSpec.fromJson(Map<String, dynamic> json)
    : windowSamples = json['window_samples'] as int,
      rateHz = (json['target_rate_hz'] as num).toDouble(),
      vocabulary = List<String>.from(json['vocabulary'] as List),
      featureColumns = List<String>.unmodifiable(
        json['feature_columns'] as List,
      ),
      windowPolicy =
          (json['preprocessing']?['window_policy'] as String?) ??
          'center_trim_edge_pad',
      mean = List<num>.from(
        json['standardizer']['mean'] as List,
      ).map((n) => n.toDouble()).toList(),
      scale = List<num>.from(
        json['standardizer']['scale'] as List,
      ).map((n) => n.toDouble()).toList() {
    bool same(List<dynamic> a, List<dynamic> b) =>
        a.length == b.length &&
        List.generate(a.length, (i) => a[i] == b[i]).every((v) => v);
    final preprocessing = json['preprocessing'];
    final featureSet = preprocessing?['feature_set'] ?? 'flex_imu6';
    final expectedFeatures = featureSet == 'flex_imu6'
        ? wordFeatureColumns
        : featureSet == 'flex_imu9'
        ? magneticWordFeatureColumns
        : <String>[];
    if (preprocessing != null &&
        (preprocessing['schema_version'] != 'sequence-preprocessing-v1' ||
            preprocessing['window_samples'] != windowSamples ||
            preprocessing['target_rate_hz'] != rateHz)) {
      throw const FormatException('Conflicting preprocessing metadata.');
    }
    if (json['architecture'] != 'tcn' ||
        json['trained'] != true ||
        windowSamples < 4 ||
        windowSamples > 400 ||
        !rateHz.isFinite ||
        rateHz < 25 ||
        rateHz > 50 ||
        ![
          'center_trim_edge_pad',
          'reject_overlength_edge_pad',
        ].contains(windowPolicy) ||
        !same(vocabulary, trainedWords) ||
        expectedFeatures.isEmpty ||
        !same(featureColumns, expectedFeatures) ||
        !same(
          json['standardizer']['feature_columns'] as List,
          featureColumns,
        ) ||
        json['standardizer']['method'] != 'per_feature_standardization' ||
        json['standardizer']['fitted_split'] != 'train' ||
        mean.length != featureCount ||
        scale.length != featureCount ||
        mean.any((n) => !n.isFinite) ||
        scale.any((n) => !n.isFinite || n <= 0)) {
      throw const FormatException('Incompatible word model metadata.');
    }
  }
  final int windowSamples;
  final double rateHz;
  final List<String> vocabulary;
  final List<String> featureColumns;
  final String windowPolicy;
  int get featureCount => featureColumns.length;
  final List<double> mean;
  final List<double> scale;

  /// Matches Python resample_trial, fixed_window and float32 standardization.
  /// Takes a complete attempt, never a mixture of separate gestures.
  List<List<double>> prepare(List<WordFrame> frames) {
    if (frames.length < 2) {
      throw const FormatException('Not enough sensor data.');
    }
    final values = frames.map((frame) {
      if (featureCount == 14 && frame.values.length == 11) {
        if (frame.magneticValues == null || frame.magneticValues!.length != 3) {
          throw const FormatException(
            'This model needs complete magnetic readings.',
          );
        }
        return [...frame.values, ...frame.magneticValues!];
      }
      return frame.values;
    }).toList();
    for (var i = 0; i < frames.length; i++) {
      if (values[i].length != featureCount ||
          values[i].any((n) => !n.isFinite) ||
          (i > 0 && frames[i].timestampMs <= frames[i - 1].timestampMs)) {
        throw const FormatException('Invalid sensor sequence.');
      }
    }
    final start = frames.first.timestampMs;
    final count =
        ((frames.last.timestampMs - start) / (1000 / rateHz)).floor() + 1;
    if (count > (rateHz * 10).floor()) {
      throw const FormatException('Gesture recording is too long.');
    }
    if (count > windowSamples && windowPolicy == 'reject_overlength_edge_pad') {
      throw const FormatException(
        'The complete attempt exceeds this model’s window.',
      );
    }
    var right = 1;
    final resampled = List.generate(count, (index) {
      final timestamp = start + index * (1000 / rateHz);
      while (right < frames.length - 1 &&
          frames[right].timestampMs < timestamp) {
        right++;
      }
      final left = frames[right - 1];
      final next = frames[right];
      final ratio =
          (timestamp - left.timestampMs) /
          (next.timestampMs - left.timestampMs);
      return List.generate(
        featureCount,
        (f) =>
            values[right - 1][f] +
            ratio * (values[right][f] - values[right - 1][f]),
      );
    });
    final trim = math.max(0, count - windowSamples) ~/ 2;
    final pad = math.max(0, windowSamples - count) ~/ 2;
    double f32(double value) => (Float32List(1)..[0] = value)[0];
    return List.generate(windowSamples, (i) {
      final row = resampled[(i + trim - pad).clamp(0, count - 1)];
      return List.generate(
        featureCount,
        (f) => f32(f32(f32(row[f]) - f32(mean[f])) / f32(scale[f])),
      );
    });
  }
}

class WordPrediction {
  WordPrediction.fromProbabilities(
    List<double> probabilities,
    List<String> vocabulary, {
    this.inferenceMs,
  }) {
    if (probabilities.length != vocabulary.length ||
        probabilities.isEmpty ||
        probabilities.any((v) => !v.isFinite || v < 0 || v > 1) ||
        (probabilities.reduce((a, b) => a + b) - 1).abs() > 0.01) {
      throw const FormatException('Invalid word model output.');
    }
    var best = 0;
    for (var i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > probabilities[best]) best = i;
    }
    label = vocabulary[best];
    confidence = probabilities[best] * 100;
  }
  late final String label;
  late final double confidence;
  final double? inferenceMs;
}

abstract interface class WordClassifier {
  Future<void> initialize();
  Future<WordPrediction> predict(List<WordFrame> frames);
  void dispose();
}
