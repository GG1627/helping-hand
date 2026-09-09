import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/ble_connection_service.dart';
import '../../services/ble_packet.dart';
import '../../theme/warm_clay_theme.dart';
import '../../widgets/hand_visualizer_widget.dart';
import '../../widgets/warm_components.dart';

class BleTestingTab extends StatelessWidget {
  const BleTestingTab({super.key, required this.bleService});

  final BleConnectionService bleService;

  static const List<String> _flexLabels = [
    'Thumb',
    'Index',
    'Middle',
    'Ring',
    'Pinky',
  ];
  static const List<int> _straightRaw = [550, 550, 550, 550, 560];
  static const List<int> _bentRaw = [145, 135, 130, 125, 95];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: bleService,
      builder: (context, _) {
        final packet = bleService.lastPacket;
        return TabScaffold(
          title: 'BLE Testing',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: HandVisualizerWidget(
                  bendValues: _handBendValues(packet),
                  imuRoll: bleService.imuRoll,
                ),
              ),
              const SizedBox(height: WarmClayTheme.cardGap),
              _buildStatusCard(context),
              const SizedBox(height: WarmClayTheme.cardGap),
              _buildTelemetryCard(context, packet),
              const SizedBox(height: WarmClayTheme.cardGap),
              WarmCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Latest Packet',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      packet?.raw ?? '--',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    if (packet != null && !packet.isValid) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Parser issues: ${packet.issues.join('; ')}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    return WarmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BLE Status', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Adapter: ${bleService.adapterState.name} | '
            '${bleService.connectedDeviceName}',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Target: ${BleConnectionService.targetDeviceName}',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 8),
          Text(bleService.status, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Auto-connect'),
            subtitle: const Text('Connect immediately when target is found'),
            value: bleService.autoConnectEnabled,
            onChanged: (value) => bleService.autoConnectEnabled = value,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: bleService.isScanning
                    ? () => unawaited(bleService.stopScan())
                    : () => unawaited(bleService.startScan()),
                child: Text(bleService.isScanning ? 'Stop Scan' : 'Start Scan'),
              ),
              if (bleService.isConnected)
                OutlinedButton(
                  onPressed: () => unawaited(bleService.disconnect()),
                  child: const Text('Disconnect'),
                ),
              if (!bleService.isConnected && bleService.scanResults.isNotEmpty)
                OutlinedButton(
                  onPressed: () => unawaited(
                    bleService.connect(bleService.scanResults.first.device),
                  ),
                  child: const Text('Manual Connect'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Targets seen: ${bleService.targetFoundCount} | '
            'In list: ${bleService.scanResults.length}',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryCard(BuildContext context, BlePacket? packet) {
    return WarmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Live Telemetry',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Prediction: ${packet?.predictedLabel ?? '--'} '
            '(${_fmtPct(packet?.predictedConfidence)}) | '
            'Expected: ${packet?.expectedLabel ?? '--'}',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'WHO_AM_I: ${packet?.who ?? '--'} | Packets: ${bleService.packetCount} | '
            '${_lastUpdateText(packet)}',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Device seq: ${packet?.deviceSequence ?? '--'} | '
            'Device time: ${packet?.deviceTimestampMs ?? '--'} ms | '
            'Rate: ${bleService.observedSampleRateHz.toStringAsFixed(1)} Hz',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth >= 420 ? 3 : 2;
              final imuItems = [
                ('Accel X (g)', _fmt3(packet?.ax)),
                ('Accel Y (g)', _fmt3(packet?.ay)),
                ('Accel Z (g)', _fmt3(packet?.az)),
                ('Hand Roll (rad)', _fmt3(bleService.imuRoll)),
                ('Gyro X (dps)', _fmt3(packet?.gx)),
                ('Gyro Y (dps)', _fmt3(packet?.gy)),
                ('Gyro Z (dps)', _fmt3(packet?.gz)),
              ];
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: imuItems.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.7,
                ),
                itemBuilder: (context, index) {
                  final item = imuItems[index];
                  return _ImuMetricTile(label: item.$1, value: item.$2);
                },
              );
            },
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth >= 420 ? 3 : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 5,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.25,
                ),
                itemBuilder: (context, index) => _FlexMetricTile(
                  label: _flexLabels[index],
                  raw: packet?.flexRaw[index],
                  norm: packet?.flexNorm[index],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  static String _fmt3(double? value) =>
      value == null ? '--' : value.toStringAsFixed(3);

  static String _fmtPct(double? value) =>
      value == null ? '--' : '${value.toStringAsFixed(1)}%';

  static String _lastUpdateText(BlePacket? packet) {
    if (packet == null) return 'No packets parsed yet';
    final seconds = DateTime.now()
        .toUtc()
        .difference(packet.receivedAt)
        .inSeconds;
    return seconds <= 0 ? 'Updated just now' : 'Updated ${seconds}s ago';
  }

  static List<double> _handBendValues(BlePacket? packet) {
    return List<double>.generate(5, (index) {
      final raw = packet?.flexRaw[index];
      if (raw == null) return 0;
      final straight = _straightRaw[index].toDouble();
      final bent = _bentRaw[index].toDouble();
      final bend = (straight - raw) / (straight - bent);
      return bend.clamp(0, 1).toDouble();
    });
  }
}

class _ImuMetricTile extends StatelessWidget {
  const _ImuMetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WarmClayColors.surface,
        border: Border.all(color: WarmClayColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _FlexMetricTile extends StatelessWidget {
  const _FlexMetricTile({
    required this.label,
    required this.raw,
    required this.norm,
  });

  final String label;
  final int? raw;
  final double? norm;

  @override
  Widget build(BuildContext context) {
    final displayNorm = norm == null ? '--' : norm!.toStringAsFixed(3);
    final progress = (norm ?? 0).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WarmClayColors.surface,
        border: Border.all(color: WarmClayColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 6),
          Text(
            'raw: ${raw ?? '--'}',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'norm: $displayNorm',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: WarmClayColors.accentLight,
              valueColor: const AlwaysStoppedAnimation<Color>(
                WarmClayColors.accentPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
