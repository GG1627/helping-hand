import 'dart:async';

import 'package:flutter/material.dart';

import '../services/ble_connection_service.dart';
import '../services/ble_packet.dart';
import '../services/calibration_service.dart';
import '../services/recording_service.dart';
import '../widgets/warm_components.dart';

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({
    super.key,
    required this.bleService,
    required this.calibration,
    required this.recording,
  });
  final BleConnectionService bleService;
  final CalibrationService calibration;
  final RecordingService recording;
  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen>
    with WidgetsBindingObserver {
  final _glove = TextEditingController();
  final _mount = TextEditingController();
  final _firmware = TextEditingController();
  final _settings = TextEditingController();
  StreamSubscription<BlePacket>? _subscription;
  Timer? _watchdog;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscription = widget.bleService.packets.listen(
      widget.calibration.handlePacket,
    );
    _watchdog = Timer.periodic(const Duration(milliseconds: 250), (_) {
      widget.calibration.checkCaptureHealth(
        connected: widget.bleService.isConnected,
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      widget.calibration.cancel('App paused. Retry the pose when you return.');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _watchdog?.cancel();
    widget.calibration.cancel();
    for (final controller in [_glove, _mount, _firmware, _settings]) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hint,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      enabled: !widget.calibration.capturing && !widget.calibration.saving,
      decoration: InputDecoration(labelText: label, hintText: hint),
      maxLength: controller == _settings ? 400 : 64,
      maxLines: controller == _settings ? 3 : 1,
    ),
  );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([
      widget.calibration,
      widget.bleService,
      widget.recording,
    ]),
    builder: (context, _) {
      final calibration = widget.calibration;
      final connected = widget.bleService.isConnected;
      final fresh = widget.bleService.hasFreshValidPacket();
      final busy = widget.recording.state != TrialRecordingState.idle;
      final measured = calibration.complete ? calibration.measurements() : null;
      final blockers = (measured?['blockers'] as List?) ?? [];
      return Scaffold(
        appBar: AppBar(title: const Text('Glove calibration')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Developer calibration',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Measure this glove before collecting signs. Saved profiles label recordings; they do not change live recognition.',
              ),
              const SizedBox(height: 16),
              WarmCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      connected
                          ? (fresh
                                ? 'Glove connected · sensor stream ready'
                                : 'Connected · waiting for sensor packets')
                          : 'Glove disconnected',
                    ),
                    if (!connected)
                      const Text(
                        'Connect from Developer → BLE Testing, then return.',
                      ),
                    if (busy)
                      const Text(
                        'Finish or discard the current sign trial first.',
                      ),
                    if (calibration.activeProfile != null) ...[
                      const SizedBox(height: 8),
                      Text('Active profile: ${calibration.activeProfile!.id}'),
                      Builder(
                        builder: (context) => OutlinedButton.icon(
                          onPressed: calibration.saving
                              ? null
                              : () {
                                  final box =
                                      context.findRenderObject() as RenderBox?;
                                  calibration.export(
                                    sharePositionOrigin: box == null
                                        ? null
                                        : box.localToGlobal(Offset.zero) &
                                              box.size,
                                  );
                                },
                          icon: const Icon(Icons.ios_share),
                          label: const Text('Export saved profile'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              WarmCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Identify the setup',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _field(_glove, 'Glove ID', hint: 'glove_01'),
                    _field(_mount, 'Mounting version', hint: 'mount_v1'),
                    _field(
                      _firmware,
                      'Firmware revision',
                      hint: 'Commit or build ID',
                    ),
                    _field(
                      _settings,
                      'Sensor settings notes',
                      hint:
                          'Record ranges, filters, sample rate, and board mounting.',
                    ),
                    const Text(
                      'Use equipment identifiers, not names. Settings are entered by the operator, not read back from firmware.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              WarmCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      value: calibration.stepIndex / calibrationSteps.length,
                      semanticsLabel: 'Calibration poses completed',
                    ),
                    const SizedBox(height: 12),
                    Text(
                      calibration.complete
                          ? 'Review measurements'
                          : 'Pose ${calibration.stepIndex + 1} of ${calibrationSteps.length}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (!calibration.complete) ...[
                      const SizedBox(height: 8),
                      Text(
                        calibration.step.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(calibration.step.instruction),
                      const SizedBox(height: 12),
                      if (calibration.capturing)
                        Text(
                          '${calibration.captureSeconds.toStringAsFixed(1)} / 3 seconds · ${calibration.packetCount} packets',
                        ),
                      FilledButton.icon(
                        onPressed:
                            !connected ||
                                !fresh ||
                                busy ||
                                calibration.capturing ||
                                calibration.saving ||
                                !calibration.initialized
                            ? null
                            : () => calibration.start(
                                connected: connected,
                                fresh: fresh,
                                recordingBusy: busy,
                              ),
                        icon: const Icon(Icons.sensors),
                        label: const Text('Capture steady pose'),
                      ),
                      if (calibration.capturing)
                        TextButton(
                          onPressed: () => calibration.cancel(),
                          child: const Text('Cancel capture'),
                        ),
                    ],
                    if (measured != null) ...[
                      for (final finger in measured['flex'] as List)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            '${finger['finger']}: straight ${(finger['straight_raw'] as num).toStringAsFixed(0)} · bent ${(finger['bent_raw'] as num).toStringAsFixed(0)} · span ${(finger['span_raw'] as num).toStringAsFixed(0)}',
                          ),
                        ),
                      Text(
                        'Gyro bias (degrees/s): ${(measured['gyro_bias_dps'] as List).map((v) => (v as num).toStringAsFixed(2)).join(', ')}',
                      ),
                      const SizedBox(height: 12),
                      for (final issue in blockers)
                        Text(
                          'Check failed: $issue',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      for (final issue in measured['warnings'] as List)
                        Text('Review: $issue'),
                      const SizedBox(height: 12),
                      const Text(
                        'These are initial engineering checks, not validated accuracy limits. Full magnetic calibration has not been performed.',
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'I checked gyro directions against the board axes.',
                        ),
                        subtitle: const Text(
                          'Rotate each positive axis using the right-hand rule and verify the signed live readings in BLE Testing.',
                        ),
                        value: calibration.axisCheckConfirmed,
                        onChanged: calibration.saving
                            ? null
                            : (value) => setState(
                                () => calibration.axisCheckConfirmed =
                                    value ?? false,
                              ),
                      ),
                      FilledButton.icon(
                        onPressed:
                            calibration.saving ||
                                blockers.isNotEmpty ||
                                !calibration.axisCheckConfirmed
                            ? null
                            : () => calibration.save(
                                gloveId: _glove.text,
                                mountingId: _mount.text,
                                firmwareRevision: _firmware.text,
                                settingsNotes: _settings.text,
                              ),
                        icon: const Icon(Icons.save_outlined),
                        label: Text(
                          calibration.saving
                              ? 'Saving…'
                              : 'Save profile for recordings',
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed:
                              calibration.capturing ||
                                  calibration.saving ||
                                  calibration.stepIndex == 0
                              ? null
                              : calibration.retryPrevious,
                          child: const Text('Repeat previous pose'),
                        ),
                        TextButton(
                          onPressed: calibration.capturing || calibration.saving
                              ? null
                              : () async {
                                  if (calibration.stepIndex > 0) {
                                    final discard = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text(
                                          'Discard these measurements?',
                                        ),
                                        content: const Text(
                                          'The saved profile stays active. Unsaved measurements will be cleared.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text(
                                              'Keep measurements',
                                            ),
                                          ),
                                          FilledButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text('Start over'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (discard != true) return;
                                  }
                                  calibration.reset();
                                },
                          child: const Text('Start over'),
                        ),
                      ],
                    ),
                    Semantics(
                      liveRegion: true,
                      child: Text(calibration.message),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
