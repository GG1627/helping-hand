import 'package:flutter/material.dart';
import '../../theme/helping_hand_theme.dart';
import '../../widgets/learning_components.dart';
import '../../services/word_sequence.dart';

class WordsTab extends StatelessWidget {
  const WordsTab({
    super.key,
    required this.onWordSelected,
    this.learnedWords = const {},
  });
  final ValueChanged<String> onWordSelected;
  final Set<String> learnedWords;
  static const candidateWords = <String>[
    'hello',
    'thank_you',
    'please',
    'sorry',
    'yes',
    'no',
    'eat',
    'drink',
  ];

  @override
  Widget build(BuildContext context) => LearningScaffold(
    title: 'Words',
    subtitle: 'Everyday vocabulary. Choose a word to learn.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Builder(
          builder: (context) => Semantics(
            header: true,
            child: Text(
              'Starter words',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Builder(
          builder: (context) => Text(
            '${candidateWords.where(learnedWords.contains).length} of ${candidateWords.length} learned',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 16),
        for (final word in candidateWords)
          Builder(
            builder: (context) {
              final learned = learnedWords.contains(word);
              final theme = Theme.of(context);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  key: ValueKey('word-row-$word'),
                  color: learned
                      ? HelpingHandColors.secondary
                      : HelpingHandColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => onWordSelected(word),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayWord(word),
                                  style: theme.textTheme.titleMedium,
                                ),
                                if (learned)
                                  Text(
                                    'Learned',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: HelpingHandColors.success,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            learned
                                ? Icons.check_circle_outline
                                : Icons.arrow_forward_rounded,
                            size: 20,
                            color: learned
                                ? HelpingHandColors.success
                                : HelpingHandColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    ),
  );
}
