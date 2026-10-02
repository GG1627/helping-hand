import 'package:flutter/material.dart';
import '../../widgets/learning_components.dart';

class AlphabetTab extends StatelessWidget {
  const AlphabetTab({
    super.key,
    required this.learnedLetters,
    required this.selectedLetter,
    required this.onLetterSelected,
  });
  
  final Set<String> learnedLetters;
  final String? selectedLetter;
  final void Function(String) onLetterSelected;

  @override
  Widget build(BuildContext context) {
    return LearningScaffold(
      title: 'Alphabet',
      subtitle: 'A to Z. Choose a letter and practice its sign.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LearningProgress(learned: learnedLetters.length, total: 26),
          const SizedBox(height: 24),
          LearningTargetGrid(
            title: 'Choose a letter',
            labels: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split(''),
            learned: learnedLetters,
            selected: selectedLetter,
            onSelected: onLetterSelected,
            maxColumns: 6,
            minimumTileWidth: 56,
          ),
        ],
      ),
    );
  }
}
