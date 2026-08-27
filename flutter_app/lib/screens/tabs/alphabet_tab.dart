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
    final letterList = letters.split('');
    final learnedCount = learnedLetters.length;
    final progress = learnedCount / letterList.length;

    return TabScaffold(
      title: 'Alphabet',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WarmCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('A to Z', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  '$learnedCount/${letterList.length} learned',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 10),
                ProgressBar(value: progress),
              ],
            ),
          ),
          const SizedBox(height: WarmClayTheme.cardGap),
          WarmCard(
            child: LayoutBuilder(
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
                      onTap: () => onLetterLearned(letter),
                    );
                  },
                );
              },
            ),
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
    required this.onTap,
  });

  final String label;
  final bool learned;
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
            color: learned ? WarmClayColors.accentPrimary : WarmClayColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: learned ? WarmClayColors.accentPrimary : WarmClayColors.border,
            ),
            boxShadow: learned
                ? const [
                    BoxShadow(
                      color: Color(0x2EC96A3C),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: learned ? Colors.white : WarmClayColors.textPrimary,
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
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
