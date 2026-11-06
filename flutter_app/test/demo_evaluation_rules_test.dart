import 'dart:convert';
import 'dart:io';

import 'package:flutter_app/services/ble_packet.dart';
import 'package:flutter_app/services/word_sequence.dart';
import 'package:flutter_test/flutter_test.dart';

import 'demo_evaluation_test.dart' show evaluateReplay;

List<Map<String, dynamic>> packets({bool gap = false}) => List.generate(33, (
  i,
) {
  final time = 1000 + i * 25 + (gap && i >= 16 ? 400 : 0);
  return {
    'received_ms': time,
    'raw_packet':
        'seq=$i,t_ms=${1000 + i * 25},who=0xEA,'
        'ax=0,ay=0,az=1,gx=0,gy=0,gz=0,pred=A,pred_conf=95,'
        'flex0_raw=500,flex1_raw=500,flex2_raw=500,flex3_raw=500,flex4_raw=500',
  };
});

Map<String, dynamic> trial(
  String key,
  String kind,
  String? performed, {
  bool gap = false,
}) {
  final capture = packets(gap: gap);
  return {
    'trial_key': key,
    'kind': kind,
    'performed_label': performed,
    'packets': capture,
    'start_ms': 999,
    'finish_ms': (capture.last['received_ms'] as int) + 1,
    'boundary_source': 'constructed_one_ms_around_recorded_packets',
  };
}

void main() {
  test(
    'actual hold tracker distinguishes misses and false target completions',
    () async {
      final report = await evaluateReplay({
        'schema_version': 'demo-replay-input-v1',
        'mode': 'static',
        'targets': ['A', 'B', '3'],
        'data_origin': 'synthetic_fixture',
        'timing': 'recorded_receive',
        'trials': [
          trial('correct', 'sign', 'A'),
          trial('wrong_sign', 'sign', 'B'),
          trial('idle', 'idle', null),
          trial('gap', 'sign', 'A', gap: true),
        ],
      });
      final a = report['per_target'][0];
      expect(a['positive_attempts'], 2);
      expect(a['correct_completions'], 1);
      expect(a['false_completions'], 2);
      expect(a['negative_target_exposures'], 2);
      expect(a['negative_by_kind']['idle']['false_completions'], 1);
      expect(report['per_target'][2]['correct_completion_rate'], isNull);
      expect(report['results'][0]['completion_after_first_packet_ms'], 750);
      expect(report['hardware_validation'], 'Not run');
      expect(report['final_accuracy_claim_ready'], isFalse);
    },
  );

  test(
    'production word controller gates timing, raw tensors and false completion',
    () async {
      final metadata = jsonDecode(
        File('assets/models/words_tcn/model_metadata.json').readAsStringSync(),
      );
      final spec = WordModelSpec.fromJson(metadata);
      Map<String, dynamic> wordTrial(
        String key,
        String kind, {
        bool gap = false,
      }) {
        final item = trial(key, kind, 'hello', gap: gap);
        final frames = (item['packets'] as List)
            .map(
              (p) => WordFrame.fromPacket(
                BlePacket.parse(
                  p['raw_packet'],
                  receivedAt: DateTime.fromMillisecondsSinceEpoch(
                    p['received_ms'],
                    isUtc: true,
                  ),
                ),
              ),
            )
            .toList();
        item['prepared_input'] = spec.prepare(frames);
        item['probabilities'] = [.95, .03, .02];
        return item;
      }

      final mismatch = wordTrial('mismatch', 'sign');
      mismatch['prepared_input'][0][0] += 10;
      final report = await evaluateReplay({
        'schema_version': 'demo-replay-input-v1',
        'mode': 'word',
        'targets': ['hello', 'please'],
        'data_origin': 'synthetic_fixture',
        'timing': 'recorded_receive',
        'word_metadata': metadata,
        'trials': [
          wordTrial('correct', 'sign'),
          wordTrial('incomplete', 'incomplete'),
          wordTrial('gap', 'sign', gap: true),
          mismatch,
        ],
      });
      final hello = report['per_target'][0];
      expect(hello['positive_attempts'], 3);
      expect(hello['correct_completions'], 1);
      expect(hello['false_completions'], 1);
      expect(hello['capture_or_preparation_failures'], 2);
      expect(hello['negative_inference_calls'], 1);
      expect(
        report['results']
            .where((row) => row['trial_key'] == 'mismatch')
            .first['failure'],
        contains('differs'),
      );
    },
  );
}
