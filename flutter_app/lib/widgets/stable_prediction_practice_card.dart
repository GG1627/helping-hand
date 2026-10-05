import 'package:flutter/material.dart';
import 'hand_3d_viewer.dart';
import '../theme/helping_hand_theme.dart';

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
    final theme = Theme.of(context);
    final complete = target != null && progress >= 1;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
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
                connected ? 'Glove connected' : 'Glove disconnected',
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
              key: ValueKey(target ?? 'no-target'),
              alignment: Alignment.centerLeft,
              child: target == null
                  ? const Icon(
                      Icons.sign_language_outlined,
                      size: 48,
                      color: HelpingHandColors.primary,
                    )
                  : Semantics(
                      label: 'Your target: $target',
                      child: ExcludeSemantics(
                        child: Text(
                          target!,
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontSize: target!.length > 1 ? 32 : 64,
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
            target == null ? 'Choose a target' : 'Your target',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            target == null
                ? 'Select a letter or number to begin.'
                : 'Make the sign and hold it steady.',
            style: theme.textTheme.bodySmall,
          ),
          if (target != null) ...[
            const SizedBox(height: 16),
            Hand3DViewer(selected: target),
          ],
          if (target != null) ...[
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
                      predictedLabel ?? 'Listening for a sign...',
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
                if (predictedConfidence != null)
                  Text(
                    '${predictedConfidence!.toStringAsFixed(0)}%',
                    semanticsLabel:
                        'Confidence ${predictedConfidence!.toStringAsFixed(0)} percent',
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
              value: progress.clamp(0.0, 1.0),
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
            message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: complete
                  ? HelpingHandColors.success
                  : HelpingHandColors.textSecondary,
            ),
          ),
          if (target != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Retry'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
