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
  final _poseHeading = GlobalKey();
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

  Future<void> _choosePose(Set<String> failedPoseIds) async {
    final poses = [
      ...widget.calibration.steps.where(
        (pose) => failedPoseIds.contains(pose.id),
      ),
      ...widget.calibration.steps.where(
        (pose) => !failedPoseIds.contains(pose.id),
      ),
    ];
    final selected = await showDialog<CalibrationStep>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Redo a pose'),
        children: [
          for (final pose in poses)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, pose),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pose.title),
                    if (failedPoseIds.contains(pose.id))
                      Text(
                        'Needs review',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
    if (!mounted || selected == null) return;
    widget.calibration.retakePose(selected);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final heading = _poseHeading.currentContext;
      if (heading != null) Scrollable.ensureVisible(heading, alignment: .1);
    });
  }

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
      final review = calibration.complete && !calibration.imuOnly
          ? calibration.review()
          : null;
      final imuChecks = calibration.complete && calibration.imuOnly
          ? calibration.accelerationChecks()
          : null;
      final blockers = (review?.measurements['blockers'] as List?) ?? [];
      final setupFields = [
        _field(_glove, 'Glove ID', hint: 'glove_01'),
        _field(_mount, 'Mounting version', hint: 'mount_v1'),
        _field(_firmware, 'Firmware revision', hint: 'Commit or build ID'),
        _field(
          _settings,
          'Sensor settings notes',
          hint: 'Record ranges, filters, sample rate, and board mounting.',
        ),
        const Text('Use equipment identifiers and avoid participant names.'),
      ];
      return Scaffold(
        appBar: AppBar(
          title: Text(
            calibration.imuOnly ? 'IMU diagnostics' : 'Glove calibration',
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (!calibration.imuOnly) ...[
                Text(
                  'Developer calibration',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
              ],
              Text(
                calibration.imuOnly
                    ? 'Capture six board orientations. You can export failed checks.'
                    : 'Measure this glove before collecting signs. Saved profiles label recordings; they do not change live recognition.',
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
              if (!calibration.imuOnly) ...[
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
                      ...setupFields,
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              WarmCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      value:
                          calibration.capturedPoseCount /
                          calibration.steps.length,
                      semanticsLabel: 'Calibration poses completed',
                    ),
                    const SizedBox(height: 12),
                    Text(
                      calibration.complete
                          ? 'Review measurements'
                          : calibration.retaking
                          ? 'Redo pose'
                          : 'Pose ${calibration.stepIndex + 1} of ${calibration.steps.length}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (!calibration.complete) ...[
                      const SizedBox(height: 8),
                      Text(
                        calibration.step.title,
                        key: _poseHeading,
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
                        )
                      else if (calibration.retaking)
                        TextButton(
                          onPressed: calibration.keepPreviousCapture,
                          child: const Text('Keep previous capture'),
                        ),
                    ],
                    if (imuChecks != null) ...[
                      const SizedBox(height: 8),
                      const Text('Median acceleration in g (X, Y, Z)'),
                      for (final (:pose, :medianG, :passed) in imuChecks)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            '${pose.title} · ${medianG.map((v) => v.toStringAsFixed(3)).join(', ')}${passed ? '' : ' · Check failed'}',
                          ),
                        ),
                      OutlinedButton.icon(
                        onPressed: () => _choosePose({
                          for (final check in imuChecks)
                            if (!check.passed) check.pose.id,
                        }),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Redo a pose'),
                      ),
                    ],
                    if (review case (
                      measurements: final measured,
                      failedPoseIds: final failedPoseIds,
                    )) ...[
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
                      OutlinedButton.icon(
                        onPressed: calibration.saving
                            ? null
                            : () => _choosePose(failedPoseIds),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Redo a pose'),
                      ),
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
                    if (calibration.capturedPoseCount > 0)
                      Builder(
                        builder: (context) => OutlinedButton.icon(
                          onPressed:
                              calibration.capturing ||
                                  calibration.saving ||
                                  calibration.exportingDiagnostics
                              ? null
                              : () {
                                  final box =
                                      context.findRenderObject() as RenderBox?;
                                  calibration.exportDiagnostics(
                                    gloveId: _glove.text,
                                    mountingId: _mount.text,
                                    firmwareRevision: _firmware.text,
                                    settingsNotes: _settings.text,
                                    sharePositionOrigin: box == null
                                        ? null
                                        : box.localToGlobal(Offset.zero) &
                                              box.size,
                                  );
                                },
                          icon: const Icon(Icons.ios_share),
                          label: Text(
                            calibration.exportingDiagnostics
                                ? 'Exporting…'
                                : 'Export measurements',
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (!calibration.complete && !calibration.retaking)
                          OutlinedButton(
                            onPressed:
                                calibration.capturing ||
                                    calibration.saving ||
                                    calibration.capturedPoseCount == 0
                                ? null
                                : calibration.retryPrevious,
                            child: const Text('Repeat previous pose'),
                          ),
                        TextButton(
                          onPressed: calibration.capturing || calibration.saving
                              ? null
                              : () async {
                                  if (calibration.capturedPoseCount > 0) {
                                    final discard = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text(
                                          'Discard these measurements?',
                                        ),
                                        content: const Text(
                                          'This clears the captures from this session.',
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
                                    if (!mounted || discard != true) return;
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
              if (calibration.imuOnly) ...[
                const SizedBox(height: 16),
                WarmCard(
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: const Text('Setup details (optional)'),
                    expandedAlignment: Alignment.centerLeft,
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: setupFields,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}
