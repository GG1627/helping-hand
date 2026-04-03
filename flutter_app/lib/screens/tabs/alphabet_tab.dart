import 'package:flutter/material.dart';

import '../../theme/warm_clay_theme.dart';
import '../../widgets/warm_components.dart';

class AlphabetTab extends StatelessWidget {
  final Set<String> learnedLetters;
  final void Function(String letter) onLetterLearned;
  
  const AlphabetTab({
    super.key,
    required this.learnedLetters,
    required this.onLetterLearned,
  });

  @override
  Widget build(BuildContext context) {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

    return TabScaffold(
      title: 'Alphabet',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: letters.split('').map((letter) {
          final learned = learnedLetters.contains(letter);
          return GestureDetector(
            onTap: () => onLetterLearned(letter),
            child: Container(
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
            ),
          );
        }).toList(),
      ),
    );
  }
}
