import 'dart:convert';
import 'dart:io';

import 'package:flutter_app/services/ble_packet.dart';
import 'package:flutter_app/services/word_sequence.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> metadata() =>
    jsonDecode(
          File(
            'assets/models/words_tcn/model_metadata.json',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>;

void main() {
  final references =
      (jsonDecode(
                File(
                  'test/fixtures/word_preprocessing.json',
                ).readAsStringSync(),
              )
              as Map)['trials']
          as List;
  for (final trial in references) {
    test('BLE to float32 input matches Python for ${trial['label']}', () {
      final spec = WordModelSpec.fromJson(metadata());
      final packets = (trial['raw_packets'] as List).cast<String>();
      final frames = packets
          .map((raw) => WordFrame.fromPacket(BlePacket.parse(raw)))
          .toList();
      final actual = spec.prepare(frames);
      final expected = trial['expected_input'] as List;
      expect(actual.length, 96);
      for (var t = 0; t < 96; t++) {
        for (var f = 0; f < 11; f++) {
          expect(
            actual[t][f],
            closeTo((expected[t][f] as num).toDouble(), 1e-6),
            reason: 't=$t f=$f',
          );
        }
      }
      expect(
        frames.first.values.take(5),
        (trial['frames'] as List).first['values'].take(5),
      );
    });
  }

  test(
    'device-clock interpolation and odd edge padding match the training rule',
    () {
      final json = metadata();
      json['standardizer']['mean'] = List.filled(11, 0);
      json['standardizer']['scale'] = List.filled(11, 1);
      final spec = WordModelSpec.fromJson(json);
      final result = spec.prepare(
        [0, 40, 100].indexed
            .map(
              (entry) => WordFrame(
                entry.$2,
                entry.$1,
                List.filled(11, entry.$2.toDouble()),
              ),
            )
            .toList(),
      );
      expect(result[44][0], 0);
      expect(result.sublist(45, 50).map((row) => row[0]), [0, 25, 50, 75, 100]);
      expect(result[95][0], 100);
      final longer = spec.prepare(
        List.generate(
          97,
          (i) => WordFrame(i * 25, i, List.filled(11, i.toDouble())),
        ),
      );
      expect(longer.first.first, 0);
      expect(longer.last.first, 95);
    },
  );

  test('incompatible features and invalid scales cannot load', () {
    final reordered = metadata();
    reordered['feature_columns'][0] = 'ax';
    expect(() => WordModelSpec.fromJson(reordered), throwsFormatException);
    final invalid = metadata();
    invalid['standardizer']['scale'][0] = 0;
    expect(() => WordModelSpec.fromJson(invalid), throwsFormatException);
  });

  test('reversed clock and non-finite frames cannot reach inference', () {
    final spec = WordModelSpec.fromJson(metadata());
    expect(
      () => spec.prepare([
        WordFrame(100, 1, List.filled(11, 0)),
        WordFrame(0, 2, List.filled(11, 0)),
      ]),
      throwsFormatException,
    );
    expect(
      () => spec.prepare([
        WordFrame(0, 1, List.filled(11, double.nan)),
        WordFrame(25, 2, List.filled(11, 0)),
      ]),
      throwsFormatException,
    );
  });

  test(
    'argmax keeps actual model confidence; invalid probabilities rejected',
    () {
      final prediction = WordPrediction.fromProbabilities([
        0.01,
        0.02,
        0.97,
      ], trainedWords);
      expect(prediction.label, 'yes');
      expect(prediction.confidence, 97);
      expect(
        () =>
            WordPrediction.fromProbabilities([double.nan, 0, 1], trainedWords),
        throwsFormatException,
      );
      expect(
        () => WordPrediction.fromProbabilities([0, 0, 0], trainedWords),
        throwsFormatException,
      );
    },
  );
}
