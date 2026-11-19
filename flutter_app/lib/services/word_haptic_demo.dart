import 'dart:async';

import 'package:flutter/foundation.dart';

import 'ble_connection_service.dart';
import 'piezo_demo_output.dart';
import 'piezo_demo_protocol.dart';

/// Plays preset guidance on the back of the hand before a practice attempt.
class WordHapticDemo extends ChangeNotifier {
  WordHapticDemo(this._ble, this._pattern) : _outputs = PiezoDemoOutput(_ble) {
    _outputs.addListener(notifyListeners);
    _ble.addListener(_connectionChanged);
  }

  static const _pleaseLap = [
    PiezoOutput.handLeft,
    PiezoOutput.handUp,
    PiezoOutput.handRight,
    PiezoOutput.handDown,
  ];
  static const patterns = {
    'hello': [
      PiezoOutput.handLeft,
      PiezoOutput.handCenter,
      PiezoOutput.handRight,
    ],
    'please': [..._pleaseLap, ..._pleaseLap, ..._pleaseLap],
  };

  final BleConnectionService _ble;
  final List<PiezoOutput> _pattern;
  final PiezoDemoOutput _outputs;
  bool _playing = false;
  Future<bool>? _stopping;
  bool _needsStopConfirmation = false;
  bool _disposed = false;
  int _generation = 0;
  String? _notice;

  PiezoOutput? get activeOutput => _outputs.activeOutput;
  String? get status => _playing ? 'Playing guidance…' : _notice;

  Future<bool> play() async {
    if (_playing || _stopping != null || _needsStopConfirmation || _disposed) {
      return false;
    }
    if (!_ble.piezoDemoTransportReady) {
      _notice = 'Connect the glove to play the motion cue.';
      notifyListeners();
      return false;
    }
    final generation = ++_generation;
    _playing = true;
    _notice = null;
    notifyListeners();
    String? notice;
    var played = false;
    var stopped = false;
    try {
      final armed = await _outputs.enable();
      if (generation != _generation) return false;
      if (!armed) {
        notice = 'The motion cue needs the piezo_demo firmware.';
        return false;
      }
      played = await _outputs.play(
        _pattern,
        shouldContinue: () => generation == _generation,
      );
      notice = played
          ? 'Motion cue played.'
          : 'The glove declined the motion cue.';
    } catch (_) {
      notice = 'The motion cue was interrupted.';
    } finally {
      if (generation == _generation) stopped = await stop(notice);
    }
    return played && stopped;
  }

  void _connectionChanged() {
    if (_playing && !_ble.piezoDemoTransportReady) {
      unawaited(stop('The glove disconnected during the cue.'));
    }
  }

  Future<bool> stop([String? notice]) {
    final stopping = _stopping;
    if (stopping != null) return stopping;
    if (!_playing && !_needsStopConfirmation) return Future.value(true);
    ++_generation;
    _playing = false;
    _needsStopConfirmation = true;
    _notice = notice;
    final stopped = _confirmStop();
    _stopping = stopped;
    if (!_disposed) notifyListeners();
    return stopped;
  }

  Future<bool> _confirmStop() async {
    try {
      await _outputs.stop(confirm: true);
      _needsStopConfirmation = false;
      return true;
    } catch (_) {
      _notice = 'The glove did not confirm the stop. Try starting again.';
      return false;
    } finally {
      _stopping = null;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _ble.removeListener(_connectionChanged);
    _outputs.removeListener(notifyListeners);
    unawaited(stop());
    _outputs.dispose();
    super.dispose();
  }
}
