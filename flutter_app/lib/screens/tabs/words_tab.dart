import 'package:flutter/material.dart';
import '../../theme/helping_hand_theme.dart';
import '../../widgets/learning_components.dart';

class WordsTab extends StatelessWidget {
  const WordsTab({super.key});
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
    subtitle: 'Everyday vocabulary. Preview the upcoming words.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ColoredBox(
          color: HelpingHandColors.secondary,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 24,
                  color: HelpingHandColors.primary,
                ),
                const SizedBox(height: 12),
                Builder(
                  builder: (context) => Text(
                    'Word practice is coming soon',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This draft list comes from the alpha test plan. Word practice will unlock after ASL review and dynamic-model validation.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
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
            '${candidateWords.length} candidate words, preview only',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 16),
        ...candidateWords.indexed.map((entry) {
          final (index, word) = entry;
          return Column(
            children: [
              Padding(
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
                      child: Builder(
                        builder: (context) => Text(
                          _displayWord(word),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
            ],
          );
        }),
        const SizedBox(height: 24),
        Builder(
          builder: (context) => Text(
            'The final word list may change after review with an ASL expert.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
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
