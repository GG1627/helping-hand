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
            '${candidateWords.length} words',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 16),
        ...candidateWords.indexed.map((entry) {
          final (index, word) = entry;
          final label = _displayWord(word);
          return Column(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onWordSelected(word),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 40,
                          child: ExcludeSemantics(
                            child: Text(
                              '${index + 1}'.padLeft(2, '0'),
                              style: const TextStyle(
                                fontSize: 14,
                                color: HelpingHandColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                learnedWords.contains(word)
                                    ? 'Completed'
                                    : trainedWords.contains(word)
                                    ? 'Recognition available'
                                    : 'Recognition coming later',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 20,
                          color: HelpingHandColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Divider(),
            ],
          );
        }),
      ],
    ),
  );

  static String _displayWord(String word) {
    return word
        .split('_')
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}
