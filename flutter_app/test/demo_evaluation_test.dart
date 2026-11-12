// Offline command harness, not a physical-device or fresh accuracy test.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_app/services/ble_packet.dart';
import 'package:flutter_app/services/stable_prediction_tracker.dart';
import 'package:flutter_app/services/word_practice_controller.dart';
import 'package:flutter_app/services/word_sequence.dart';
import 'package:flutter_test/flutter_test.dart';

class ReplayWordClassifier implements WordClassifier {
  ReplayWordClassifier(this.spec, this.trial);
  final WordModelSpec spec;
  final Map<String, dynamic> trial;
  bool invoked = false;
  String? error;
  @override
  Future<void> initialize() async {}
  @override
  Future<WordPrediction> predict(List<WordFrame> frames) async {
    invoked = true;
    try {
      if (trial['prediction_error'] != null) {
        throw FormatException(trial['prediction_error']);
      }
      final tensor = spec.prepare(frames);
      final expected = trial['prepared_input'] as List;
      if (tensor.length != expected.length) {
        throw const FormatException(
          'Capture boundary changed model input shape.',
        );
      }
      for (var t = 0; t < tensor.length; t++) {
        if (tensor[t].length != (expected[t] as List).length) {
          throw const FormatException('Feature count mismatch.');
        }
        for (var f = 0; f < tensor[t].length; f++) {
          if ((tensor[t][f] - (expected[t][f] as num)).abs() > 1e-6) {
            throw const FormatException(
              'Raw packet replay differs from the inferred CSV tensor. Recompute predictions for the selected capture boundary.',
            );
          }
        }
      }
      return WordPrediction.fromProbabilities(
        (trial['probabilities'] as List)
            .map((v) => (v as num).toDouble())
            .toList(),
        spec.vocabulary,
      );
    } on FormatException catch (failure) {
      error = failure.message;
      rethrow;
    }
  }

  @override
  void dispose() {}
}

BlePacket replayPacket(Map<String, dynamic> input) {
  final received = DateTime.fromMillisecondsSinceEpoch(
    input['received_ms'],
    isUtc: true,
  );
  final packet = BlePacket.parse(input['raw_packet'], receivedAt: received);
  if (input['prediction_override'] == null || !packet.isValid) return packet;
  final expected = (input['candidate_flex_raw'] as List)
      .map((v) => int.tryParse(v.toString()))
      .toList();
  if (expected.length != 5 ||
      !List.generate(
        5,
        (i) => expected[i] == packet.flexRaw[i],
      ).every((v) => v)) {
    throw const FormatException(
      'Candidate CSV flex values differ from the original raw packet.',
    );
  }
  final fields = {
    ...packet.fields,
    ...Map<String, String>.from(input['prediction_override']),
  };
  return BlePacket.parse(
    fields.entries.map((e) => '${e.key}=${e.value}').join(','),
    receivedAt: received,
  );
}

Map<String, dynamic> summarizeTarget(
  String target,
  List<Map<String, dynamic>> rows,
) {
  final positive = rows.where((r) => r['expected_completion'] == true).toList();
  final negative = rows
      .where((r) => r['expected_completion'] == false)
      .toList();
  final correct = positive.where((r) => r['completed'] == true).length;
  final falseCompletions = negative.where((r) => r['completed'] == true).length;
  return {
    'target': target,
    'positive_attempts': positive.length,
    'correct_completions': correct,
    'missed_completions': positive.length - correct,
    'correct_completion_rate': positive.isEmpty
        ? null
        : correct / positive.length,
    'negative_target_exposures': negative.length,
    'false_completions': falseCompletions,
    'false_completion_rate': negative.isEmpty
        ? null
        : falseCompletions / negative.length,
    'capture_or_preparation_failures': rows
        .where((r) => r['capture_or_preparation_failed'] == true)
        .length,
    'negative_inference_calls': negative
        .where((r) => r['inference_invoked'] == true)
        .length,
    'model_split_counts': {
      for (final split in rows.map((r) => r['model_split'] as String).toSet())
        split: {
          'positive_attempts': positive
              .where((r) => r['model_split'] == split)
              .length,
          'correct_completions': positive
              .where((r) => r['model_split'] == split && r['completed'] == true)
              .length,
          'negative_target_exposures': negative
              .where((r) => r['model_split'] == split)
              .length,
          'false_completions': negative
              .where((r) => r['model_split'] == split && r['completed'] == true)
              .length,
        },
    },
    'negative_by_kind': {
      for (final kind in ['sign', 'idle', 'incomplete', 'unrelated'])
        kind: {
          'exposures': negative.where((r) => r['kind'] == kind).length,
          'false_completions': negative
              .where((r) => r['kind'] == kind && r['completed'] == true)
              .length,
        },
    },
  };
}

Future<Map<String, dynamic>> evaluateReplay(
  Map<String, dynamic> request,
) async {
  if (request['schema_version'] != 'demo-replay-input-v1') {
    throw const FormatException('Unsupported replay schema.');
  }
  final mode = request['mode'];
  final spec = mode == 'word'
      ? WordModelSpec.fromJson(
          Map<String, dynamic>.from(request['word_metadata']),
        )
      : null;
  final rows = <Map<String, dynamic>>[];
  for (final trialJson in request['trials'] as List) {
    final trial = Map<String, dynamic>.from(trialJson);
    final packets = (trial['packets'] as List)
        .map((p) => replayPacket(Map<String, dynamic>.from(p)))
        .toList();
    final start = DateTime.fromMillisecondsSinceEpoch(
      trial['start_ms'],
      isUtc: true,
    );
    final finish = DateTime.fromMillisecondsSinceEpoch(
      trial['finish_ms'],
      isUtc: true,
    );
    if (finish.isBefore(start)) {
      throw const FormatException('Finish precedes start.');
    }
    final capture = trial['boundary_source'] == 'operator_supplied'
        ? packets
              .where(
                (p) =>
                    !p.receivedAt.isBefore(start) &&
                    !p.receivedAt.isAfter(finish),
              )
              .toList()
        : packets;
    for (final target in (request['targets'] as List).cast<String>()) {
      final expected =
          trial['kind'] == 'sign' && trial['performed_label'] == target;
      var completed = false;
      var invoked = false;
      var failed = false;
      String? failure;
      int? completionMs;
      String? prediction;
      double? confidence;
      if (mode == 'static') {
        final tracker = StablePredictionTracker()..selectTarget(target);
        failed = capture.isEmpty || capture.any((p) => !p.isValid);
        if (failed) {
          failure = 'Empty capture or invalid raw sensor packet present.';
        }
        for (final packet in capture) {
          final result = tracker.add(packet);
          prediction = result.predictedLabel;
          confidence = result.predictedConfidence;
          if (result.justCompleted) {
            completed = true;
            completionMs = packet.receivedAt
                .difference(capture.first.receivedAt)
                .inMilliseconds;
            break;
          }
        }
      } else if (mode == 'word') {
        var now = start;
        final classifier = ReplayWordClassifier(spec!, trial);
        final controller = WordPracticeController(
          target: target,
          classifier: classifier,
          clock: () => now,
        );
        await controller.initialize();
        // A fresh stream at Start is assumed; this was not measured by Record Signs.
        controller.start(connected: true, freshSensors: true);
        for (final packet in capture) {
          now = packet.receivedAt;
          controller.tick(connected: true);
          controller.add(packet);
        }
        now = finish;
        completed = await controller.finish(connected: true);
        invoked = classifier.invoked;
        failed = !invoked || classifier.error != null;
        failure = classifier.error ?? (failed ? controller.message : null);
        prediction = controller.prediction?.label;
        confidence = controller.prediction?.confidence;
        controller.dispose();
      } else {
        throw const FormatException('Unsupported replay mode.');
      }
      rows.add({
        'trial_key': trial['trial_key'],
        'model_split': trial['model_split'] ?? 'unknown',
        'target': target,
        'kind': trial['kind'],
        'performed_label': trial['performed_label'],
        'expected_completion': expected,
        'completed': completed,
        'prediction': prediction,
        'confidence_percent': confidence,
        'capture_or_preparation_failed': failed,
        'failure': failure,
        'inference_invoked': invoked,
        'completion_after_first_packet_ms': completionMs,
        'capture_packets': capture.length,
      });
    }
  }
  return {
    'schema_version': 'demo-evaluation-report-v1',
    'result_scope': 'offline_rules_replay',
    'data_origin': request['data_origin'],
    'timing': request['timing'],
    'sources': request['sources'],
    'model': request['model'],
    'plan_sha256': request['plan_sha256'],
    'trial_count': (request['trials'] as List).length,
    'target_exposure_count': rows.length,
    'hardware_validation': 'Not run',
    'final_accuracy_claim_ready': false,
    'phone_latency_ms': null,
    'boundary_assumptions':
        'Constructed collection bounds unless operator supplied; fresh sensors and uninterrupted connection assumed. Capture gaps are replayed; actual app navigation/background events are not recorded.',
    'duplicate_receive_timestamp_count': (request['trials'] as List).fold<int>(
      0,
      (n, trial) => n + (trial['duplicate_receive_timestamps'] as int? ?? 0),
    ),
    'per_target': [
      for (final target in (request['targets'] as List).cast<String>())
        summarizeTarget(
          target,
          rows.where((row) => row['target'] == target).toList(),
        ),
    ],
    'results': rows,
  };
}

void main() {
  const input = String.fromEnvironment('HH_DEMO_INPUT');
  const output = String.fromEnvironment('HH_DEMO_OUTPUT');
  test(
    'replay demo through production acceptance rules',
    () async {
      if (output.isEmpty) {
        throw const FormatException('HH_DEMO_OUTPUT is required.');
      }
      final request = Map<String, dynamic>.from(
        jsonDecode(await File(input).readAsString()),
      );
      final result = await evaluateReplay(request);
      await File(output).writeAsString(
        '${const JsonEncoder.withIndent('  ').convert(result)}\n',
      );
    },
    skip: input.isEmpty
        ? 'Run via backend/evaluate_demo.py with a recording plan.'
        : false,
  );
}
