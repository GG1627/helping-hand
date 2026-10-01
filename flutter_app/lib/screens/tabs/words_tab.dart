import 'package:flutter/material.dart';

import '../../theme/warm_clay_theme.dart';
import '../../widgets/warm_components.dart';

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
  Widget build(BuildContext context) {
    return TabScaffold(
      title: 'Words',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WarmCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_outlined,
                      color: WarmClayColors.accentPrimary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Starter words',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'This draft list comes from the alpha test plan. Word '
                  'practice will unlock after ASL review and dynamic-model '
                  'validation.',
                ),
                const SizedBox(height: 10),
                Text(
                  '${candidateWords.length} candidate words · preview only',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: WarmClayTheme.cardGap),
          ...candidateWords.indexed.map((entry) {
            final (index, word) = entry;
            return Padding(
              padding: const EdgeInsets.only(bottom: WarmClayTheme.cardGap),
              child: WarmCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: WarmClayColors.accentLight,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: WarmClayColors.accentPrimary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _displayWord(word),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const Chip(
                      label: Text('Coming soon'),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
          const Text(
            'The final word list may change after review with an ASL expert.',
          ),
        ],
      ),
    );
  }

  static String _displayWord(String word) {
    return word
        .split('_')
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}
