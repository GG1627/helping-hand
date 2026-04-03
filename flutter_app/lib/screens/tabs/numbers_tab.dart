import 'package:flutter/material.dart';

import '../../theme/warm_clay_theme.dart';
import '../../widgets/warm_components.dart';

class NumbersTab extends StatelessWidget {
  final Set<int> learnedNumbers;
  final void Function(int) onNumberLearned;

  const NumbersTab({
    super.key,
    required this.learnedNumbers,
    required this.onNumberLearned,
  });

  @override
  Widget build(BuildContext context) {
    return TabScaffold(
      title: 'Numbers',
      child: WarmCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('0 to 9', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Practice number signs one step at a time.',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(10, (index) {
                final learned = learnedNumbers.contains(index);
                return GestureDetector(
                  onTap: () => onNumberLearned(index),
                  child: Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: learned
                          ? WarmClayColors.accentLight
                          : WarmClayColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: WarmClayColors.border),
                    ),
                    child: Text(
                      '$index',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: learned
                            ? WarmClayColors.accentPrimary
                            : WarmClayColors.textPrimary,
                      ),
                    )  
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
