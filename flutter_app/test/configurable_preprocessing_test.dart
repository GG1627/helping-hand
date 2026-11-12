import 'dart:convert';
import 'dart:io';

import 'package:flutter_app/services/ble_packet.dart';
import 'package:flutter_app/services/word_sequence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fixture = jsonDecode(
    File('test/fixtures/sequence_preprocessing_v1.json').readAsStringSync(),
  );
  for (final item in fixture['cases'] as List) {
    test('matches Python float32 preparation: ${item['name']}', () {
      final spec = WordModelSpec.fromJson(
        Map<String, dynamic>.from(item['metadata']),
      );
      final frames = (item['frames'] as List)
          .map(
            (row) => WordFrame(
              row['t_ms'],
              row['seq'],
              (row['values'] as List)
                  .map((v) => (v as num).toDouble())
                  .toList(),
              magneticValues: (row['magnetic'] as List?)
                  ?.map((v) => (v as num).toDouble())
                  .toList(),
            ),
          )
          .toList();
      final actual = spec.prepare(frames);
      final expected = item['expected_input'] as List;
      expect(actual.length, spec.windowSamples);
      for (var t = 0; t < actual.length; t++) {
        expect(actual[t].length, spec.featureCount);
        for (var f = 0; f < spec.featureCount; f++) {
          expect(
            actual[t][f],
            closeTo((expected[t][f] as num).toDouble(), 1e-6),
            reason: 't=$t f=$f',
          );
        }
      }
    });
  }

  test(
    'strict windows reject overlength attempts and conflicting metadata',
    () {
      final json = Map<String, dynamic>.from(fixture['cases'][1]['metadata']);
      final spec = WordModelSpec.fromJson(json);
      expect(
        () => spec.prepare(
          List.generate(225, (i) => WordFrame(i * 25, i, List.filled(11, 0))),
        ),
        throwsFormatException,
      );
      json['window_samples'] = 96;
      expect(() => WordModelSpec.fromJson(json), throwsFormatException);
    },
  );

  test(
    'magnetic models reject missing vectors; packet extraction preserves raw fields',
    () {
      final spec = WordModelSpec.fromJson(
        Map<String, dynamic>.from(fixture['cases'][2]['metadata']),
      );
      const base =
          'who=0xEA,ax=0,ay=0,az=1,gx=0,gy=0,gz=0,'
          'flex0_raw=500,flex1_raw=450,flex2_raw=400,flex3_raw=350,flex4_raw=300';
      final valid = List.generate(
        3,
        (i) => WordFrame.fromPacket(
          BlePacket.parse(
            'seq=$i,t_ms=${i * 25},$base,mag=ok,mx=0,my=-12.5,mz=31.2',
          ),
        ),
      );
      expect(valid.first.values.length, 11);
      expect(valid.first.magneticValues, [0, -12.5, 31.2]);
      expect(spec.prepare(valid).first.length, 14);
      final missing = [...valid];
      missing[1] = WordFrame(25, 1, valid[1].values);
      expect(() => spec.prepare(missing), throwsFormatException);
    },
  );
}
