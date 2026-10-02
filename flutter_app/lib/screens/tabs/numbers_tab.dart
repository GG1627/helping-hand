import 'package:flutter/material.dart';
import '../../widgets/learning_components.dart';

class NumbersTab extends StatelessWidget {
  const NumbersTab({
    super.key,
    required this.learnedNumbers,
    required this.selectedNumber,
    required this.practiceCard,
    required this.onNumberSelected,
  });
  final Set<int> learnedNumbers;
  final int? selectedNumber;
  final Widget practiceCard;
  final void Function(int) onNumberSelected;
  @override
  Widget build(BuildContext context) => LearningScaffold(
    title: 'Numbers',
    subtitle: '0 to 9. Build confidence, one number at a time.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LearningProgress(learned: learnedNumbers.length, total: 10),
        const SizedBox(height: 24),
        LearningWorkspace(
          practice: practiceCard,
          selectorFirst: true,
          selector: LearningTargetGrid(
            title: 'Choose a number',
            labels: List.generate(10, (index) => '$index'),
            learned: learnedNumbers.map((number) => '$number').toSet(),
            selected: selectedNumber?.toString(),
            onSelected: (label) => onNumberSelected(int.parse(label)),
            maxColumns: 5,
            minimumTileWidth: 64,
          ),
        ),
      ],
    ),
  );
}
