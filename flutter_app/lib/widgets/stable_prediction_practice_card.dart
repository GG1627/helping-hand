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
    final complete = target != null && progress >= 1;
    final progressValue = progress.clamp(0.0, 1.0);

    return WarmCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'LIVE PRACTICE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: WarmClayColors.textSecondary,
                ),
              ),
              const Spacer(),
              _ConnectionStatus(connected: connected),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: Container(
              key: ValueKey(target ?? 'no-target'),
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: WarmClayColors.accentLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 62,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: WarmClayColors.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      target ?? '—',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            fontSize: 36,
                            color: WarmClayColors.accentPrimary,
                          ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          target == null ? 'Choose a target' : 'Your target',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          target == null
                              ? 'Select a letter or number below to begin.'
                              : 'Make the sign and hold it steady.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: WarmClayColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (target != null) ...[
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        complete ? 'Matched' : 'Current reading',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        predictedLabel ?? 'Listening for a sign…',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: complete
                                  ? WarmClayColors.success
                                  : WarmClayColors.textPrimary,
                            ),
                      ),
                    ],
                  ),
                ),
                if (predictedConfidence != null)
                  Text(
                    '${predictedConfidence!.toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: WarmClayColors.textSecondary,
                    ),
                  ),
                if (complete)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: WarmClayColors.success,
                      size: 20,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            _PracticeProgress(value: progressValue, complete: complete),
            const SizedBox(height: 12),
          ] else ...[
            const SizedBox(height: 14),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: complete
                        ? WarmClayColors.success
                        : WarmClayColors.textSecondary,
                  ),
                ),
              ),
              if (target != null)
                TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Retry'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PracticeProgress extends StatelessWidget {
  const _PracticeProgress({required this.value, required this.complete});

  final double value;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          Container(
            height: 5,
            decoration: BoxDecoration(
              color: WarmClayColors.border,
              borderRadius: BorderRadius.circular(WarmClayTheme.pillRadius),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: constraints.maxWidth * value,
            height: 5,
            decoration: BoxDecoration(
              color: complete
                  ? WarmClayColors.success
                  : WarmClayColors.accentPrimary,
              borderRadius: BorderRadius.circular(WarmClayTheme.pillRadius),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionStatus extends StatelessWidget {
  const _ConnectionStatus({required this.connected});

  final bool connected;

  @override
  Widget build(BuildContext context) {
    final color = connected
        ? WarmClayColors.success
        : WarmClayColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Text(
          connected ? 'Glove connected' : 'Glove disconnected',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}
