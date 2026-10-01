import 'package:flutter/material.dart';

import '../../theme/warm_clay_theme.dart';
import '../../widgets/warm_components.dart';

class AlphabetTab extends StatelessWidget {
  final Set<String> learnedLetters;
  final String? selectedLetter;
  final Widget practiceCard;
  final void Function(String letter) onLetterSelected;

  const AlphabetTab({
    super.key,
    required this.learnedLetters,
    required this.selectedLetter,
    required this.practiceCard,
    required this.onLetterSelected,
  });

  @override
  Widget build(BuildContext context) {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final letterList = letters.split('');
    final learnedCount = learnedLetters.length;
    final progress = learnedCount / letterList.length;

    return TabScaffold(
      title: 'Alphabet',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'A to Z',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                '$learnedCount of ${letterList.length} learned',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: WarmClayColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ProgressBar(value: progress),
          const SizedBox(height: 6),
          Text(
            'Choose a letter to practice its sign.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: WarmClayColors.textSecondary,
            ),
          ),
          const SizedBox(height: WarmClayTheme.cardGap),
          practiceCard,
          const SizedBox(height: WarmClayTheme.cardGap),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth >= 460 ? 6 : 5;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: letterList.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final letter = letterList[index];
                  final learned = learnedLetters.contains(letter);
                  return _LearningTile(
                    label: letter,
                    learned: learned,
                    selected: selectedLetter == letter,
                    onTap: () => onLetterSelected(letter),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LearningTile extends StatelessWidget {
  const _LearningTile({
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: selected
                ? WarmClayColors.accentPrimary
                : learned
                ? WarmClayColors.accentLight
                : WarmClayColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? WarmClayColors.accentPrimary
                  : WarmClayColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : WarmClayColors.textPrimary,
                  ),
                ),
              ),
              if (learned)
                const Positioned(
                  right: 6,
                  top: 6,
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: WarmClayColors.success,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
