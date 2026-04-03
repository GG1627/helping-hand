import 'package:flutter/material.dart';

import '../../theme/warm_clay_theme.dart';
import '../../widgets/warm_components.dart';

class AlphabetTab extends StatelessWidget {
  const AlphabetTab({super.key});

  @override
  Widget build(BuildContext context) {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

    return TabScaffold(
      title: 'Alphabet',
      child: WarmCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Letter Progress',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap into each letter lesson as you learn.',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: letters.split('').map((letter) {
                final learned = 'ABCDEFG'.contains(letter);
                return Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: learned
                        ? WarmClayColors.accentLight
                        : WarmClayColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: WarmClayColors.border),
                  ),
                  child: Text(
                    letter,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: learned
                          ? WarmClayColors.accentPrimary
                          : WarmClayColors.textPrimary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
