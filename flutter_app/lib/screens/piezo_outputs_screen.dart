import 'dart:async';

import 'package:flutter/material.dart';

import '../services/ble_connection_service.dart';
import '../services/piezo_demo_protocol.dart';
import '../widgets/haptic_hand_visualizer_widget.dart';
import '../widgets/warm_components.dart';

class PiezoOutputsScreen extends StatefulWidget {
  const PiezoOutputsScreen({super.key, required this.bleService});

  final BleConnectionService bleService;

  @override
  State<PiezoOutputsScreen> createState() => _PiezoOutputsScreenState();
}

class _PiezoOutputsScreenState extends State<PiezoOutputsScreen>
    with WidgetsBindingObserver {
  late final StreamSubscription<PiezoDemoEvent> _events;
  late bool _linkReady;
  Timer? _timeout;
  int? _requestId;
  PiezoDemoAction? _action;
  bool _enabled = false;
  PiezoOutput _selected = PiezoOutput.indexFinger;
  PiezoOutput? _active;
  PiezoOutput? _last;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _linkReady = widget.bleService.piezoDemoTransportReady;
    WidgetsBinding.instance.addObserver(this);
    widget.bleService.addListener(_connectionChanged);
    _events = widget.bleService.piezoDemoEvents.listen(_receive);
  }

  void _clearRequest() {
    _timeout?.cancel();
    _requestId = null;
    _action = null;
    _active = null;
  }

  void _connectionChanged() {
    final ready = widget.bleService.piezoDemoTransportReady;
    if (!mounted || ready == _linkReady) return;
    setState(() {
      _linkReady = ready;
      _clearRequest();
      _enabled = false;
      _notice = null;
    });
  }

  void _stopOnExit() {
    final shouldStop = _linkReady && (_enabled || _requestId != null);
    _clearRequest();
    _enabled = false;
    if (shouldStop) {
      final ble = widget.bleService;
      unawaited(
        Future<void>.sync(() {
          return ble.writePiezoDemo(
            PiezoDemoAction.stop,
            ble.nextPiezoDemoRequestId(),
          );
        }).catchError((Object _) {}),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      setState(_stopOnExit);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.bleService.removeListener(_connectionChanged);
    unawaited(_events.cancel());
    _stopOnExit();
    super.dispose();
  }

  void _fail(int id, String notice) {
    if (!mounted || _requestId != id) return;
    setState(() {
      _stopOnExit();
      _notice = notice;
    });
  }

  void _waitForResponse(int id) {
    _timeout?.cancel();
    _timeout = Timer(
      const Duration(seconds: 2),
      () => _fail(id, 'Glove response timed out. Check the demo firmware.'),
    );
  }

  Future<void> _send(PiezoDemoAction action, {PiezoOutput? output}) async {
    int? id;
    try {
      id = widget.bleService.nextPiezoDemoRequestId();
      setState(() {
        _requestId = id;
        _action = action;
        _notice = null;
      });
      _waitForResponse(id);
      await widget.bleService.writePiezoDemo(action, id, output: output);
    } catch (_) {
      if (id != null) {
        _fail(id, 'Could not send the output command.');
      } else if (mounted) {
        setState(
          () => _notice = 'Reconnect the glove to reset output commands.',
        );
      }
    }
  }

  void _receive(PiezoDemoEvent event) {
    if (!mounted || !_linkReady || event.requestId != _requestId) return;
    switch ((event.type, _action)) {
      case (PiezoDemoEventType.ready, PiezoDemoAction.enable):
        setState(() {
          _clearRequest();
          _enabled = true;
        });
      case (PiezoDemoEventType.unavailable, PiezoDemoAction.enable):
        setState(() {
          _clearRequest();
          _enabled = false;
          _notice = 'This glove build has demo outputs disabled.';
        });
      case (PiezoDemoEventType.started, PiezoDemoAction.pulse):
        if (event.output != _selected) return;
        setState(() {
          _active = event.output;
          _last = event.output;
        });
        _waitForResponse(event.requestId);
      case (PiezoDemoEventType.ended, PiezoDemoAction.pulse):
        setState(_clearRequest);
      case (PiezoDemoEventType.ended, PiezoDemoAction.stop):
        setState(() {
          _clearRequest();
          _enabled = false;
          _notice = 'Outputs stopped.';
        });
      case (PiezoDemoEventType.rejected, PiezoDemoAction.pulse):
        _fail(event.requestId, 'The glove declined the pulse.');
      default:
        break;
    }
  }

  String get _status {
    if (!_linkReady) return 'Connect the glove in BLE Testing.';
    if (_action == PiezoDemoAction.stop) return 'Stopping outputs…';
    final output = _active;
    if (output != null) return '${output.label} output active';
    if (_action != null) return 'Waiting for glove…';
    return _notice ?? (_enabled ? 'Ready to pulse' : 'Outputs disabled');
  }

  @override
  Widget build(BuildContext context) {
    final busy = _requestId != null;
    final last = _last;
    return Scaffold(
      appBar: AppBar(title: const Text('Piezo Outputs')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                WarmCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PiezoOutputHand(activeOutput: _active, height: 274),
                      const SizedBox(height: 8),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _status,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      if (last != null)
                        Text(
                          'Last output · ${last.label}',
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<PiezoOutput>(
                  initialValue: _selected,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Piezo output'),
                  items: [
                    for (final output in PiezoOutput.values)
                      DropdownMenuItem(
                        value: output,
                        child: Text(output.label),
                      ),
                  ],
                  onChanged: busy
                      ? null
                      : (output) {
                          if (output != null) {
                            setState(() => _selected = output);
                          }
                        },
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: !_linkReady || busy
                      ? null
                      : () => _enabled
                            ? _send(PiezoDemoAction.pulse, output: _selected)
                            : _send(PiezoDemoAction.enable),
                  child: Text(_enabled ? 'Pulse output' : 'Enable outputs'),
                ),
                if (_enabled || busy)
                  OutlinedButton(
                    onPressed: !_linkReady || _action == PiezoDemoAction.stop
                        ? null
                        : () => _send(PiezoDemoAction.stop),
                    child: const Text('Stop outputs'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
