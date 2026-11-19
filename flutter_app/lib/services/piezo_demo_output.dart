import 'dart:async';

import 'package:flutter/foundation.dart';

import 'ble_connection_service.dart';
import 'piezo_demo_protocol.dart';

/// Sends one output at a time and exposes only glove-confirmed activity.
class PiezoDemoOutput extends ChangeNotifier {
  PiezoDemoOutput(this._ble) {
    _events = _ble.piezoDemoEvents.listen(_receive);
  }

  final BleConnectionService _ble;
  late final StreamSubscription<PiezoDemoEvent> _events;
  _OutputRequest? _request;
  PiezoOutput? _activeOutput;

  PiezoOutput? get activeOutput => _activeOutput;

  Future<bool> enable() => _send(PiezoDemoAction.enable);

  Future<bool> play(
    List<PiezoOutput> outputs, {
    required bool Function() shouldContinue,
  }) async {
    for (var index = 0; index < outputs.length; index++) {
      if (!shouldContinue()) break;
      if (!await _send(PiezoDemoAction.pulse, output: outputs[index])) {
        return false;
      }
      if (index + 1 < outputs.length) {
        await Future<void>.delayed(const Duration(milliseconds: 75));
      }
    }
    return true;
  }

  Future<void> stop({bool confirm = false}) async {
    final pending = _request?.result;
    _request = null;
    if (pending != null && !pending.isCompleted) pending.complete(false);
    if (_activeOutput != null) {
      _activeOutput = null;
      notifyListeners();
    }
    if (!_ble.piezoDemoTransportReady) return;
    if (confirm) {
      if (!await _send(PiezoDemoAction.stop)) {
        throw StateError('The glove stop was interrupted.');
      }
    } else {
      await _ble.writePiezoDemo(
        PiezoDemoAction.stop,
        _ble.nextPiezoDemoRequestId(),
      );
    }
  }

  Future<bool> _send(PiezoDemoAction action, {PiezoOutput? output}) async {
    final request = _OutputRequest(
      _ble.nextPiezoDemoRequestId(),
      action,
      output,
    );
    _request = request;
    try {
      await _ble.writePiezoDemo(action, request.id, output: output);
      return await request.result.future.timeout(const Duration(seconds: 2));
    } finally {
      if (identical(_request, request)) _request = null;
    }
  }

  void _receive(PiezoDemoEvent event) {
    final request = _request;
    if (request == null ||
        request.id != event.requestId ||
        request.result.isCompleted) {
      return;
    }
    switch ((request.action, event.type)) {
      case (PiezoDemoAction.enable, PiezoDemoEventType.ready):
      case (PiezoDemoAction.stop, PiezoDemoEventType.ended):
        request.result.complete(true);
      case (PiezoDemoAction.enable, PiezoDemoEventType.unavailable):
      case (PiezoDemoAction.pulse, PiezoDemoEventType.rejected):
        request.result.complete(false);
      case (PiezoDemoAction.pulse, PiezoDemoEventType.started):
        if (event.output != request.output) return;
        _activeOutput = event.output;
        notifyListeners();
      case (PiezoDemoAction.pulse, PiezoDemoEventType.ended):
        request.result.complete(_activeOutput == request.output);
        _activeOutput = null;
        notifyListeners();
      default:
        break;
    }
  }

  @override
  void dispose() {
    final pending = _request?.result;
    _request = null;
    if (pending != null && !pending.isCompleted) pending.complete(false);
    unawaited(_events.cancel());
    super.dispose();
  }
}

class _OutputRequest {
  _OutputRequest(this.id, this.action, this.output);

  final int id;
  final PiezoDemoAction action;
  final PiezoOutput? output;
  final result = Completer<bool>();
}
