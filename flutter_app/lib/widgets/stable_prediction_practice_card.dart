import 'dart:async';
import 'package:flutter/material.dart';
import 'hand_3d_viewer.dart';
import '../services/ble_packet.dart';
import 'haptic_hand_visualizer_widget.dart';
import '../theme/helping_hand_theme.dart';
import 'armature_hand_3d_viewer.dart';

class StablePredictionPracticeCard extends StatefulWidget {
  const StablePredictionPracticeCard({
    super.key,
    required this.target,
    required this.packet,
    required this.predictedLabel,
    required this.predictedConfidence,
    required this.progress,
    required this.message,
    required this.connected,
    required this.onRetry,
  });

  final String? target;
  final BlePacket? packet;
  final String? predictedLabel;
  final double? predictedConfidence;
  final double progress;
  final String message;
  final bool connected;
  final VoidCallback onRetry;

  @override
  State<StablePredictionPracticeCard> createState() =>
      _StablePredictionPracticeCardState();
}

class _StablePredictionPracticeCardState
    extends State<StablePredictionPracticeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  // Constants for calibration thresholds
  static const List<int> _straightRaw = [550, 550, 550, 550, 560];
  static const List<int> _bentRaw = [145, 135, 130, 125, 95];
  static const bool _forceMockPreview = false;

  @override
  void initState() {
    super.initState();
    // Controls the speed of the downward animation cycle (e.g., 900ms per full loop)
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // Internal helper to fetch target template vector
  List<double> _getTargetVector(String? targetStr) {
    if (targetStr == null) return List.filled(5, 0.0);
    switch (targetStr.toUpperCase()) {
      case 'L':
        return [0.9, 0.9, 0.1, 0.1, 0.1];
      case 'B':
        return [0.1, 0.0, 0.0, 0.0, 0.0];
      default:
        return [0.5, 0.5, 0.5, 0.5, 0.5];
    }
  }

  // Internal calculation for finger errors (+ means bend more, - means relax)
  List<double> _calculateFingerErrors() {
    if ((widget.packet == null || !widget.connected) && _forceMockPreview) {
      return [0.6, 0.8, 0.0, -0.5, -0.7];
    }

    if (widget.packet == null || widget.target == null) return List.filled(5, 0.0);
    final targetVec = _getTargetVector(widget.target);
    
    return List.generate(5, (index) {
      final raw = widget.packet!.flexRaw[index];
      if (raw == null) return 0.0;
      
      final straight = _straightRaw[index].toDouble();
      final bent = _bentRaw[index].toDouble();
      final liveNorm = ((straight - raw) / (straight - bent)).clamp(0.0, 1.0);
      
      return targetVec[index] - liveNorm;
    });
  }

  // Internal calculation for the 10 haptic motors with downward vertical node animation
  List<double> _calculateHapticMotors(List<double> errors) {
    List<double> motors = List.filled(10, 0.0);
    const double noiseThreshold = 0.15; // Noise margin cutoff

    // Filter out fingers within the acceptable noise threshold
    List<MapEntry<int, double>> activeErrors = [];
    for (int i = 0; i < 5; i++) {
      if (errors[i].abs() > noiseThreshold) {
        activeErrors.add(MapEntry(i, errors[i]));
      }
    }

    // If all fingers are within threshold, clear all haptics (success state)
    if (activeErrors.isEmpty) {
      return motors;
    }

    // Priority Queue: Sort active errors by highest absolute magnitude
    activeErrors.sort((a, b) => b.value.abs().compareTo(a.value.abs()));

    // 1. Light up ONLY the single highest error finger node (Indices 0-4)
    final worstFinger = activeErrors.first;
    motors[worstFinger.key] = worstFinger.value.abs().clamp(0.0, 1.0);

    // 2. Drive the animated vertical sequence on the back-of-hand matrix (Indices 5-7)
    final frame = (_animController.value * 3).floor() % 3;
    const List<List<double>> downwardFrames = [
      [1.0, 0.3, 0.6], // Frame 0: Top active
      [0.6, 1.0, 0.3], // Frame 1: Center active
      [0.3, 0.6, 1.0], // Frame 2: Bottom active
    ];
    final currentFrameValues = downwardFrames[frame];

    motors[6] = currentFrameValues[0]; // Top node (Index 6)
    motors[5] = currentFrameValues[1]; // Center node (Index 5)
    motors[7] = currentFrameValues[2]; // Bottom node (Index 7)

    // Secondary indicators: Left (8) and Right (9) nodes reflect secondary errors or queue length
    motors[8] = activeErrors.length > 1 ? 0.6 : 0.0; 
    motors[9] = 0.2; 

    return motors;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final complete = widget.target != null && widget.progress >= 1;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final errors = _calculateFingerErrors();
        final hapticMotorStates = _calculateHapticMotors(errors);

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: HelpingHandColors.secondary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Text(
                    'Live practice',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: HelpingHandColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    widget.connected ? 'Glove connected' : 'Glove disconnected',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: reducedMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                child: Align(
                  key: ValueKey(widget.target ?? 'no-target'),
                  alignment: Alignment.centerLeft,
                  child: widget.target == null
                      ? const Icon(
                          Icons.sign_language_outlined,
                          size: 48,
                          color: HelpingHandColors.primary,
                        )
                      : Semantics(
                          label: 'Your target: ${widget.target}',
                          child: ExcludeSemantics(
                            child: Text(
                              widget.target!,
                              style: theme.textTheme.headlineLarge?.copyWith(
                                fontSize: widget.target!.length > 1 ? 32 : 64,
                                height: 1.1,
                                color: HelpingHandColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.target == null ? 'Choose a target' : 'Your target',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                widget.target == null
                    ? 'Select a letter or number to begin.'
                    : 'Make the sign and hold it steady.',
                style: theme.textTheme.bodySmall,
              ),
              if (widget.target != null) ...[
                const SizedBox(height: 16),
                Hand3DViewer(selected: widget.target),
              ],
              if (widget.target != null) ...[
                const SizedBox(height: 24),
                const Divider(color: HelpingHandColors.outline),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          complete ? 'Matched' : 'Current reading',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.predictedLabel ?? 'Listening for a sign...',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                    if (widget.predictedConfidence != null)
                      Text(
                        '${widget.predictedConfidence!.toStringAsFixed(0)}%',
                        semanticsLabel:
                            'Confidence ${widget.predictedConfidence!.toStringAsFixed(0)} percent',
                        style: theme.textTheme.titleMedium,
                      ),
                    if (complete)
                      const Icon(
                        Icons.check_circle_outline,
                        size: 24,
                        color: HelpingHandColors.success,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  complete ? 'Hold complete' : 'Hold progress',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: widget.progress.clamp(0.0, 1.0),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(8),
                  color: complete
                      ? HelpingHandColors.success
                      : HelpingHandColors.primary,
                  backgroundColor: HelpingHandColors.surface,
                  semanticsLabel: 'Hold progress',
                ),
              ],
              const SizedBox(height: 16),
              Text(
                widget.message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: complete
                      ? HelpingHandColors.success
                      : HelpingHandColors.textSecondary,
                ),
              ),
              if (widget.target != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: widget.onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    label: const Text('Retry'),
                  ),
                ),
              ],
              if (widget.target != null) ...[
                const SizedBox(height: 16),
                ArmatureHand3DViewer(
                  packet: widget.packet,
                  imuRoll: 0.0, // Placeholder for IMU roll; replace with actual data if available
                ),
              ],
              if (widget.target != null) ...[
                const SizedBox(height: 16),
                Center(
                  child: HapticHandVisualizerWidget(
                    fingerErrors: errors,
                    motorStates: hapticMotorStates,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}