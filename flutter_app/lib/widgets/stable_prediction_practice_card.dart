import 'package:flutter/material.dart';

import '../theme/warm_clay_theme.dart';
import 'warm_components.dart';

class StablePredictionPracticeCard extends StatelessWidget {
  const StablePredictionPracticeCard({
    super.key,
    required this.target,
    required this.predictedLabel,
    required this.predictedConfidence,
    required this.progress,
    required this.message,
    required this.connected,
    required this.onRetry,
  });

  final String? target;
  final String? predictedLabel;
  final double? predictedConfidence;
  final double progress;
  final String message;
  final bool connected;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return WarmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Glove practice',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              _ConnectionPill(connected: connected),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            target == null
                ? 'Choose a tile, then hold the matching sign.'
                : 'Target: $target',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 6),
          Text(
            predictedLabel == null
                ? 'Current prediction: --'
                : 'Current prediction: $predictedLabel'
                      '${predictedConfidence == null ? '' : ' (${predictedConfidence!.toStringAsFixed(1)}%)'}',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 10),
          ProgressBar(value: progress),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              if (target != null)
                TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConnectionPill extends StatelessWidget {
  const _ConnectionPill({required this.connected});

  final bool connected;

  @override
  Widget build(BuildContext context) {
    final color = connected
        ? const Color(0xFF3C8C62)
        : WarmClayColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(WarmClayTheme.pillRadius),
      ),
      child: Text(
        connected ? 'Connected' : 'Disconnected',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
