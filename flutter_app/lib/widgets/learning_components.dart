import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/helping_hand_theme.dart';
import 'brand_components.dart';

/// Shared open canvas for learning destinations, with one safe scroll region.
class LearningScaffold extends StatelessWidget {
  const LearningScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String title;
  final String subtitle;
  final Widget child;
  @override
  Widget build(BuildContext context) => Theme(
    data: HelpingHandTheme.build(),
    child: Builder(
      builder: (context) => Scaffold(
        backgroundColor: HelpingHandColors.background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final gutter = constraints.maxWidth < 360
                  ? 16.0
                  : constraints.maxWidth >= 600
                  ? 32.0
                  : 24.0;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(gutter, 24, gutter, 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: HelpingHandBrandTrail(),
                        ),
                        const SizedBox(height: 24),
                        child,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
}

class LearningProgress extends StatelessWidget {
  const LearningProgress({
    super.key,
    required this.learned,
    required this.total,
  });
  final int learned;
  final int total;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '$learned of $total signs learned',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 12),
      LinearProgressIndicator(
        value: total == 0 ? 0 : (learned / total).clamp(0, 1),
        minHeight: 6,
        borderRadius: BorderRadius.circular(8),
        color: HelpingHandColors.primary,
        backgroundColor: HelpingHandColors.divider,
        semanticsLabel: 'Learning progress: $learned of $total signs learned',
      ),
    ],
  );
}

class LearningTargetGrid extends StatelessWidget {
  const LearningTargetGrid({
    super.key,
    required this.title,
    required this.labels,
    required this.learned,
    required this.selected,
    required this.onSelected,
    this.maxColumns = 6,
    this.minimumTileWidth = 56,
  });
  final String title;
  final List<String> labels;
  final Set<String> learned;
  final String? selected;
  final ValueChanged<String> onSelected;
  final int maxColumns;
  final double minimumTileWidth;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Semantics(
        header: true,
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
      const SizedBox(height: 16),
      LayoutBuilder(
        builder: (context, constraints) {
          final scaledLabel = MediaQuery.textScalerOf(context).scale(28);
          final minimum = math.max(minimumTileWidth, scaledLabel + 32);
          final columns = math.max(
            1,
            math.min(
              maxColumns,
              ((constraints.maxWidth + 12) / (minimum + 12)).floor(),
            ),
          );
          final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: labels
                .map(
                  (label) => SizedBox(
                    width: width,
                    height: math.max(width, scaledLabel + 32),
                    child: LearningTargetTile(
                      label: label,
                      learned: learned.contains(label),
                      selected: selected == label,
                      onTap: () => onSelected(label),
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    ],
  );
}

class LearningTargetTile extends StatelessWidget {
  const LearningTargetTile({
    super.key,
    required this.label,
    required this.learned,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool learned;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : HelpingHandColors.textPrimary;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label${learned ? ', learned' : ', not yet learned'}',
      child: Material(
        color: selected
            ? HelpingHandColors.primary
            : learned
            ? HelpingHandColors.secondary
            : HelpingHandColors.surface,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          focusColor: HelpingHandColors.accent.withValues(alpha: 0.45),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected
                    ? HelpingHandColors.primary
                    : HelpingHandColors.outline,
                width: selected ? 2 : 1,
              ),
            ),
            child: ExcludeSemantics(
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  if (learned)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: selected
                            ? Colors.white
                            : HelpingHandColors.success,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
