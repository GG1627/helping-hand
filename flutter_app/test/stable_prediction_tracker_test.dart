import 'package:flutter_app/services/ble_packet.dart';
import 'package:flutter_app/services/stable_prediction_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('requires a confident matching prediction for the stable interval', () {
    final tracker = StablePredictionTracker(
      minimumStableDuration: const Duration(milliseconds: 300),
      minimumMatchingPackets: 3,
      maximumPacketGap: const Duration(milliseconds: 200),
    );
    tracker.selectTarget('A');

    expect(tracker.add(_packet('A', 90, 0)).justCompleted, isFalse);
    expect(tracker.add(_packet('A', 91, 150)).justCompleted, isFalse);
    final completed = tracker.add(_packet('A', 92, 300));

    expect(completed.feedback, StablePredictionFeedback.completed);
    expect(completed.progress, 1);
    expect(completed.justCompleted, isTrue);
    expect(tracker.add(_packet('A', 93, 450)).justCompleted, isFalse);
  });

  test('a mismatched prediction resets the stable hold', () {
    final tracker = StablePredictionTracker(
      minimumStableDuration: const Duration(milliseconds: 300),
      minimumMatchingPackets: 3,
      maximumPacketGap: const Duration(milliseconds: 200),
    );
    tracker.selectTarget('B');
    tracker.add(_packet('B', 90, 0));
    tracker.add(_packet('B', 90, 150));

    final mismatch = tracker.add(_packet('C', 95, 300));
    expect(mismatch.feedback, StablePredictionFeedback.tryAgain);
    expect(mismatch.progress, 0);

    tracker.add(_packet('B', 90, 450));
    tracker.add(_packet('B', 90, 600));
    final completed = tracker.add(_packet('B', 90, 750));
    expect(completed.justCompleted, isTrue);
  });

  test('low confidence never advances completion progress', () {
    final tracker = StablePredictionTracker(
      minimumStableDuration: Duration.zero,
      minimumMatchingPackets: 1,
    );
    tracker.selectTarget('3');

    final result = tracker.add(_packet('3', 79.9, 0));

    expect(result.feedback, StablePredictionFeedback.lowConfidence);
    expect(result.progress, 0);
    expect(result.justCompleted, isFalse);
  });
}

BlePacket _packet(String prediction, double confidence, int offsetMs) {
  final raw =
      'seq=$offsetMs,t_ms=$offsetMs,who=0x70,'
      'ax=0.1,ay=0.2,az=1.0,gx=1.1,gy=2.2,gz=3.3,'
      'expected=-,pred=$prediction,pred_conf=$confidence,'
      'flex0_raw=500,flex1_raw=450,flex2_raw=400,'
      'flex3_raw=350,flex4_raw=300';
  return BlePacket.parse(
    raw,
    receivedAt: DateTime.utc(2026, 9, 10).add(Duration(milliseconds: offsetMs)),
  );
}
