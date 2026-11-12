import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_app/services/ble_packet.dart';
import 'package:flutter_app/services/tflite_word_classifier.dart';
import 'package:flutter_app/services/word_practice_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'fixtures/word_replay.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  for (final trial in jsonDecode(wordReplayJson) as List) {
    testWidgets('native TCN replay and completion: ${trial['label']}', (
      tester,
    ) async {
      final classifier = TfliteWordClassifier();
      var now = DateTime.utc(2026);
      final controller = WordPracticeController(
        target: trial['label'] as String,
        classifier: classifier,
        clock: () => now,
      );
      await controller.initialize();
      expect(
        controller.phase,
        WordPracticePhase.ready,
        reason: controller.message,
      );
      controller.start(connected: true, freshSensors: true);
      final rawPackets = (trial['raw_packets'] as List).cast<String>();
      final firstTimestamp = BlePacket.parse(
        rawPackets.first,
      ).deviceTimestampMs!;
      for (final raw in rawPackets) {
        final packet = BlePacket.parse(raw);
        now = DateTime.utc(2026).add(
          Duration(milliseconds: packet.deviceTimestampMs! - firstTimestamp),
        );
        controller.add(BlePacket.parse(raw, receivedAt: now));
      }
      expect(
        controller.phase,
        WordPracticePhase.recording,
        reason: controller.message,
      );
      expect(await controller.finish(connected: true), isTrue);
      final result = controller.prediction!;
      expect(result.label, trial['label']);
      expect(
        result.confidence,
        closeTo((trial['expected_confidence'] as num).toDouble(), 0.02),
      );
      expect(await controller.finish(connected: true), isFalse);
      debugPrint(
        'Native emulator replay ${result.label}: ${result.confidence.toStringAsFixed(4)}%; worker model load/invoke/copy ${result.inferenceMs!.toStringAsFixed(3)} ms. Replay is not live glove validation.',
      );
      controller.dispose();
    });
  }
}
