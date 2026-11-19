import 'dart:async';

import 'package:flutter/foundation.dart';

import 'ble_connection_service.dart';
import 'ble_packet.dart';
import 'piezo_demo_output.dart';
import 'piezo_demo_protocol.dart';

typedef _Correction = ({PiezoOutput finger, bool bend});

/// Runs the automatic number 3 demo on the same bounded pulses as Piezo Outputs.
class StaticHapticDemo extends ChangeNotifier {
  StaticHapticDemo(this._ble, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now,
      _linkReady = _ble.piezoDemoTransportReady,
      _outputs = PiezoDemoOutput(_ble) {
    _packets = _ble.packets.listen(_observe);
    _outputs.addListener(notifyListeners);
    _ble.addListener(_connectionChanged);
  }

  // DATA-02: fit on three holds of 3 and checked on two reserved holds.
  // Spans come from the straight/bent measurements in CAL-02.
  static const _bands = {
    PiezoOutput.middle: (low: 513, high: 550, span: 348),
    PiezoOutput.pinky: (low: 310, high: 355, span: 324),
  };
  static const _maximumGap = Duration(milliseconds: 350);
  static const _startDelay = Duration(seconds: 5);
  static const _repeatDelay = Duration(seconds: 2);
  static const _settleMs = 175;
  static const _margin = 0.035;

  final BleConnectionService _ble;
  final DateTime Function() _clock;
  final PiezoDemoOutput _outputs;
  late final StreamSubscription<BlePacket> _packets;
  Timer? _startTimer;
  Timer? _repeatTimer;
  Timer? _watchdog;
  _Correction? _candidate;
  _Correction? _cue;
  DateTime? _lastPacketAt;
  int? _lastDeviceMs;
  int? _candidateSince;
  int _session = 0;
  int _cueRevision = 0;
  bool _linkReady;
  bool _active = false;
  bool _completed = false;
  bool _running = false;
  bool _armed = false;
  bool _playing = false;
  bool _stopping = false;
  bool _disposed = false;
  String? _notice;
  PiezoOutput? get activeOutput => _outputs.activeOutput;

  String get status {
    if (_completed) return '3 learned.';
    if (_notice != null) return _notice!;
    if (!_linkReady) return 'Connect the glove in BLE Testing.';
    if (!_running) return 'Try 3 on your own first.';
    if (!_armed) return 'Waiting for the glove…';
    final cue = _cue;
    return cue == null
        ? 'Hold 3 steady.'
        : '${cue.bend ? 'Bend' : 'Straighten'} '
              '${cue.finger.label.toLowerCase()} finger.';
  }

  void setPractice({required bool active, required bool completed}) {
    if (_disposed || (_active == active && _completed == completed)) return;
    _active = active;
    _completed = completed;
    _notice = null;
    if (_active && !_completed) {
      _scheduleStart();
    } else {
      unawaited(_stop());
    }
    notifyListeners();
  }

  void _scheduleStart() {
    if (!_active ||
        _completed ||
        !_linkReady ||
        _disposed ||
        _running ||
        _stopping ||
        _startTimer != null ||
        _notice != null) {
      return;
    }
    _startTimer = Timer(_startDelay, () {
      _startTimer = null;
      unawaited(_start());
    });
  }

  Future<void> _start() async {
    final session = ++_session;
    _running = true;
    _notice = null;
    notifyListeners();
    try {
      final enabled = await _outputs.enable();
      if (session != _session) return;
      if (!enabled) {
        await _stop('Flash the piezo_demo firmware to enable live cues.');
        return;
      }
      _armed = true;
      _lastPacketAt = _clock();
      _watchdog = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (_clock().difference(_lastPacketAt!) > _maximumGap) {
          unawaited(
            _stop('Sensor readings stopped. Reopen the lesson to retry.'),
          );
        }
      });
      notifyListeners();
    } catch (_) {
      if (session == _session) {
        await _stop(
          'The glove did not respond. Check the connection and firmware.',
        );
      }
    }
  }

  void _observe(BlePacket packet) {
    if (!_armed) return;
    final now = _clock();
    final deviceMs = packet.deviceTimestampMs;
    final lastDeviceMs = _lastDeviceMs;
    if (now.difference(packet.receivedAt).abs() > _maximumGap ||
        (lastDeviceMs != null &&
            (deviceMs == null ||
                deviceMs <= lastDeviceMs ||
                deviceMs - lastDeviceMs > _maximumGap.inMilliseconds))) {
      unawaited(_stop('Sensor readings stopped. Reopen the lesson to retry.'));
      return;
    }
    if (deviceMs == null ||
        _bands.keys.any((finger) {
          final raw = packet.flexRaw[finger.index];
          return raw == null || raw <= 0 || raw >= 4095;
        })) {
      unawaited(
        _stop('A finger reading is unavailable. Reopen the lesson to retry.'),
      );
      return;
    }
    _lastPacketAt = now;
    _lastDeviceMs = deviceMs;

    final current = _cue;
    if (current != null) {
      final error = _error(packet, current.finger);
      if (error != 0 && (error > 0) == current.bend) return;
      _cue = null;
      _cueRevision++;
      _repeatTimer?.cancel();
      _repeatTimer = null;
      _candidate = null;
      notifyListeners();
    }

    _Correction? next;
    var largest = _margin;
    for (final finger in _bands.keys) {
      final error = _error(packet, finger);
      if (error.abs() <= largest) continue;
      largest = error.abs();
      next = (finger: finger, bend: error > 0);
    }
    if (next != _candidate) {
      _candidate = next;
      _candidateSince = deviceMs;
    } else if (next != null && deviceMs - _candidateSince! >= _settleMs) {
      _cue = next;
      notifyListeners();
      _playIfReady();
    }
  }

  double _error(BlePacket packet, PiezoOutput finger) {
    final band = _bands[finger]!;
    final raw = packet.flexRaw[finger.index]!;
    final closest = raw.clamp(band.low, band.high);
    // Raw readings fall as these two fingers bend.
    return (raw - closest) / band.span;
  }

  void _playIfReady() {
    final cue = _cue;
    if (!_armed ||
        _playing ||
        cue == null ||
        _repeatTimer != null ||
        _clock().difference(_lastPacketAt!) > _maximumGap) {
      return;
    }
    _playing = true;
    unawaited(_play(cue, _session, _cueRevision));
  }

  Future<void> _play(_Correction cue, int session, int revision) async {
    final outputs = [
      cue.finger,
      cue.bend ? PiezoOutput.handUp : PiezoOutput.handDown,
      PiezoOutput.handCenter,
      cue.bend ? PiezoOutput.handDown : PiezoOutput.handUp,
    ];
    try {
      final accepted = await _outputs.play(
        outputs,
        shouldContinue: () => session == _session && revision == _cueRevision,
      );
      if (!accepted && session == _session) {
        await _stop('The glove declined the cue. Reopen the lesson to retry.');
      }
    } catch (_) {
      if (session == _session) {
        await _stop('The cue was interrupted. Reopen the lesson to retry.');
      }
    } finally {
      if (session == _session) {
        _playing = false;
        if (revision == _cueRevision) {
          _repeatTimer = Timer(_repeatDelay, () {
            _repeatTimer = null;
            _playIfReady();
          });
        } else {
          _playIfReady();
        }
      }
    }
  }

  void _connectionChanged() {
    final ready = _ble.piezoDemoTransportReady;
    if (ready == _linkReady) return;
    _linkReady = ready;
    if (!ready) {
      unawaited(_stop());
    } else {
      _notice = null;
      _scheduleStart();
    }
    notifyListeners();
  }

  Future<void> _stop([String? notice]) async {
    _startTimer?.cancel();
    _startTimer = null;
    _repeatTimer?.cancel();
    _repeatTimer = null;
    if (!_running) return;
    ++_session;
    _running = false;
    _armed = false;
    _playing = false;
    _watchdog?.cancel();
    _cue = null;
    _candidate = null;
    _lastDeviceMs = null;
    _notice = notice;
    _stopping = _linkReady;
    try {
      final stopping = _outputs.stop();
      if (!_disposed) notifyListeners();
      await stopping;
    } catch (_) {
      _notice ??= 'Reconnect the glove before restarting the demo.';
    } finally {
      _stopping = false;
      if (!_disposed) {
        _scheduleStart();
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _ble.removeListener(_connectionChanged);
    unawaited(_packets.cancel());
    _outputs.removeListener(notifyListeners);
    unawaited(_stop());
    _outputs.dispose();
    super.dispose();
  }
}
