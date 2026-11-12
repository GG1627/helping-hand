import 'package:flutter/foundation.dart';

import 'ble_packet.dart';
import 'word_sequence.dart';

enum WordPracticePhase {
  loading,
  ready,
  recording,
  evaluating,
  matched,
  retry,
  unavailable,
}

class WordPracticeController extends ChangeNotifier {
  WordPracticeController({
    required this.target,
    required this.classifier,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;
  static const minimumConfidence = 80.0;
  static const maximumGap = Duration(milliseconds: 250);
  static const maximumAttempt = Duration(seconds: 8);
  final String target;
  final WordClassifier classifier;
  final DateTime Function() _clock;
  final List<WordFrame> _frames = [];
  WordPracticePhase phase = WordPracticePhase.loading;
  String message = 'Preparing word recognition...';
  WordPrediction? prediction;
  DateTime? _startedAt;
  DateTime? _lastReceivedAt;
  bool _disposed = false;
  int _generation = 0;
  int get packetCount => _frames.length;
  double get elapsedSeconds => _startedAt == null
      ? 0
      : _clock().difference(_startedAt!).inMilliseconds / 1000;

  Future<void> initialize() async {
    if (!trainedWords.contains(target)) {
      phase = WordPracticePhase.unavailable;
      message = 'Recognition is not available for this word yet.';
      _notify();
      return;
    }
    try {
      await classifier.initialize();
      if (_disposed) return;
      phase = WordPracticePhase.ready;
      message = 'Start an attempt, perform the sign, then tap Finish sign.';
    } catch (error) {
      if (_disposed) return;
      debugPrint('Word model load failed: $error');
      phase = WordPracticePhase.unavailable;
      message = 'Word recognition could not load. Reopen this page to retry.';
    }
    _notify();
  }

  void start({required bool connected, required bool freshSensors}) {
    if (phase == WordPracticePhase.loading ||
        phase == WordPracticePhase.unavailable ||
        phase == WordPracticePhase.recording ||
        phase == WordPracticePhase.evaluating) {
      return;
    }
    if (!connected || !freshSensors) {
      message = !connected
          ? 'Connect the glove to start.'
          : 'Waiting for finger and motion readings. Check the glove connection.';
      _notify();
      return;
    }
    _generation++;
    _frames.clear();
    prediction = null;
    _startedAt = _clock();
    _lastReceivedAt = null;
    phase = WordPracticePhase.recording;
    message = 'Perform the whole sign, then tap Finish sign.';
    _notify();
  }

  void add(BlePacket packet) {
    if (phase != WordPracticePhase.recording) return;
    final now = _clock();
    if (now.difference(packet.receivedAt).abs() > maximumGap ||
        (_lastReceivedAt != null &&
            (packet.receivedAt.isBefore(_lastReceivedAt!) ||
                packet.receivedAt.difference(_lastReceivedAt!) > maximumGap))) {
      cancel('The sensor stream paused. Start a new attempt.');
      return;
    }
    try {
      final frame = WordFrame.fromPacket(packet);
      if (_frames.isNotEmpty &&
          (frame.timestampMs <= _frames.last.timestampMs ||
              frame.timestampMs - _frames.last.timestampMs >
                  maximumGap.inMilliseconds ||
              frame.sequence <= _frames.last.sequence)) {
        throw const FormatException(
          'Glove clock reset or sensor stream interrupted.',
        );
      }
      _frames.add(frame);
      _lastReceivedAt = packet.receivedAt;
    } on FormatException {
      cancel(
        'Finger or motion readings were interrupted. Start a new attempt.',
      );
      return;
    }
    tick(connected: true);
  }

  void tick({required bool connected}) {
    if (!connected) {
      if (phase == WordPracticePhase.recording ||
          phase == WordPracticePhase.evaluating) {
        cancel('The glove disconnected. Reconnect and start a new attempt.');
      }
      return;
    }
    if (phase != WordPracticePhase.recording) return;
    if (_clock().difference(_startedAt!) > maximumAttempt) {
      cancel('Attempt timed out. Start again and finish after the sign.');
    } else if (_clock().difference(_lastReceivedAt ?? _startedAt!) >
        maximumGap) {
      cancel('The sensor stream paused. Start a new attempt.');
    } else {
      _notify();
    }
  }

  Future<bool> finish({required bool connected}) async {
    if (phase != WordPracticePhase.recording) return false;
    tick(connected: connected);
    if (phase != WordPracticePhase.recording) return false;
    if (_frames.length < 20 ||
        _frames.last.timestampMs - _frames.first.timestampMs < 750) {
      cancel(
        'The attempt was too short. Perform the whole sign and try again.',
      );
      return false;
    }
    final generation = _generation;
    phase = WordPracticePhase.evaluating;
    message = 'Checking your sign...';
    _notify();
    try {
      final result = await classifier.predict(List.unmodifiable(_frames));
      if (_disposed || generation != _generation) return false;
      prediction = result;
      final matches =
          result.label == target && result.confidence >= minimumConfidence;
      phase = matches ? WordPracticePhase.matched : WordPracticePhase.retry;
      message = matches
          ? 'Matched ${displayWord(target)}.'
          : result.confidence < minimumConfidence
          ? 'The reading was uncertain. Try another attempt.'
          : 'Recognized ${displayWord(result.label)}. Try ${displayWord(target)} again.';
      _notify();
      return matches;
    } catch (error) {
      if (_disposed || generation != _generation) return false;
      debugPrint('Word inference failed: $error');
      cancel('Could not check this attempt. Try again.');
      return false;
    }
  }

  void cancel(String reason) {
    if (_disposed ||
        phase == WordPracticePhase.loading ||
        phase == WordPracticePhase.unavailable) {
      return;
    }
    _generation++;
    _frames.clear();
    prediction = null;
    _startedAt = null;
    _lastReceivedAt = null;
    phase = WordPracticePhase.retry;
    message = reason;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    classifier.dispose();
    super.dispose();
  }
}
