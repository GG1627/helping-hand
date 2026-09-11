import 'dart:math' as math;

import 'ble_packet.dart';

enum StablePredictionFeedback {
  idle,
  waitingForPacket,
  holding,
  lowConfidence,
  tryAgain,
  completed,
}

class StablePredictionResult {
  const StablePredictionResult({
    required this.feedback,
    required this.progress,
    required this.matchingPackets,
    this.predictedLabel,
    this.predictedConfidence,
    this.justCompleted = false,
  });

  const StablePredictionResult.idle()
    : this(
        feedback: StablePredictionFeedback.idle,
        progress: 0,
        matchingPackets: 0,
      );

  final StablePredictionFeedback feedback;
  final double progress;
  final int matchingPackets;
  final String? predictedLabel;
  final double? predictedConfidence;
  final bool justCompleted;
}

class StablePredictionTracker {
  StablePredictionTracker({
    this.minimumConfidence = 80,
    this.minimumStableDuration = const Duration(milliseconds: 750),
    this.minimumMatchingPackets = 5,
    this.maximumPacketGap = const Duration(milliseconds: 250),
  });

  final double minimumConfidence;
  final Duration minimumStableDuration;
  final int minimumMatchingPackets;
  final Duration maximumPacketGap;

  String? _target;
  DateTime? _firstMatchingPacketAt;
  DateTime? _lastMatchingPacketAt;
  int _matchingPackets = 0;
  bool _completed = false;

  String? get target => _target;

  StablePredictionResult selectTarget(String target) {
    final normalized = target.trim().toUpperCase();
    if (!RegExp(r'^[A-Z0-9]$').hasMatch(normalized)) {
      throw ArgumentError.value(target, 'target', 'Must be A-Z or 0-9.');
    }
    _target = normalized;
    _clearMatch();
    _completed = false;
    return const StablePredictionResult(
      feedback: StablePredictionFeedback.waitingForPacket,
      progress: 0,
      matchingPackets: 0,
    );
  }

  StablePredictionResult reset() {
    final target = _target;
    if (target == null) return const StablePredictionResult.idle();
    return selectTarget(target);
  }

  StablePredictionResult add(BlePacket packet) {
    final target = _target;
    if (target == null) return const StablePredictionResult.idle();

    final predictedLabel = packet.predictedLabel?.trim().toUpperCase();
    final confidence = packet.predictedConfidence;
    if (!packet.isValid || predictedLabel == null || confidence == null) {
      _clearMatch();
      return StablePredictionResult(
        feedback: StablePredictionFeedback.waitingForPacket,
        progress: 0,
        matchingPackets: 0,
        predictedLabel: predictedLabel,
        predictedConfidence: confidence,
      );
    }

    if (_completed) {
      return StablePredictionResult(
        feedback: StablePredictionFeedback.completed,
        progress: 1,
        matchingPackets: _matchingPackets,
        predictedLabel: predictedLabel,
        predictedConfidence: confidence,
      );
    }

    if (predictedLabel != target) {
      _clearMatch();
      return StablePredictionResult(
        feedback: StablePredictionFeedback.tryAgain,
        progress: 0,
        matchingPackets: 0,
        predictedLabel: predictedLabel,
        predictedConfidence: confidence,
      );
    }

    if (confidence < minimumConfidence) {
      _clearMatch();
      return StablePredictionResult(
        feedback: StablePredictionFeedback.lowConfidence,
        progress: 0,
        matchingPackets: 0,
        predictedLabel: predictedLabel,
        predictedConfidence: confidence,
      );
    }

    final receivedAt = packet.receivedAt.toUtc();
    final lastMatchingPacketAt = _lastMatchingPacketAt;
    if (lastMatchingPacketAt != null &&
        (receivedAt.isBefore(lastMatchingPacketAt) ||
            receivedAt.difference(lastMatchingPacketAt) > maximumPacketGap)) {
      _clearMatch();
    }

    _firstMatchingPacketAt ??= receivedAt;
    _lastMatchingPacketAt = receivedAt;
    _matchingPackets += 1;

    final elapsed = receivedAt.difference(_firstMatchingPacketAt!);
    final timeProgress = minimumStableDuration.inMicroseconds == 0
        ? 1.0
        : elapsed.inMicroseconds / minimumStableDuration.inMicroseconds;
    final packetProgress = minimumMatchingPackets == 0
        ? 1.0
        : _matchingPackets / minimumMatchingPackets;
    final progress = math.min(timeProgress, packetProgress).clamp(0.0, 1.0);
    final completed =
        elapsed >= minimumStableDuration &&
        _matchingPackets >= minimumMatchingPackets;
    if (completed) _completed = true;

    return StablePredictionResult(
      feedback: completed
          ? StablePredictionFeedback.completed
          : StablePredictionFeedback.holding,
      progress: progress,
      matchingPackets: _matchingPackets,
      predictedLabel: predictedLabel,
      predictedConfidence: confidence,
      justCompleted: completed,
    );
  }

  void _clearMatch() {
    _firstMatchingPacketAt = null;
    _lastMatchingPacketAt = null;
    _matchingPackets = 0;
  }
}
