import 'package:flutter/material.dart';
import '../../theme/warm_clay_theme.dart';
import '../../widgets/warm_components.dart';

class DashboardTab extends StatelessWidget {
  final Set<String> learnedLetters;
  final int totalLetters;
  final Set<int> learnedNumbers;
  final int totalNumbers;

  const DashboardTab({
    super.key,
    required this.learnedLetters,
    required this.totalLetters,
    required this.learnedNumbers,
    required this.totalNumbers,
  });

  @override
  Widget build(BuildContext context) {
    final lettersLearned = learnedLetters.length;
    final numbersLearned = learnedNumbers.length;

    final alphabetPercentage =
        totalLetters > 0 ? (lettersLearned / totalLetters * 100).toStringAsFixed(0) : '0';
    final numbersPercentage =
        totalNumbers > 0 ? (numbersLearned / totalNumbers * 100).toStringAsFixed(0) : '0';

    // Overall progress: combine letters + numbers
    final overallPercentage = ((lettersLearned + numbersLearned) /
            (totalLetters + totalNumbers) *
            100)
        .toStringAsFixed(0);

    return TabScaffold(
      title: 'Dashboard',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StreakPill(text: '12 day streak'),
          const SizedBox(height: WarmClayTheme.cardGap),
          WarmCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Overall Progress'),
                const SizedBox(height: 8),
                ProgressBar(
                  value: (lettersLearned + numbersLearned) /
                      (totalLetters + totalNumbers),
                ),
                const SizedBox(height: 8),
                Text('$lettersLearned/$totalLetters letters, '
                    '$numbersLearned/$totalNumbers numbers'),
              ],
            ),
          ),
          const SizedBox(height: WarmClayTheme.cardGap),
          Row(
            children: [
              Expanded(
                  child: StatCard(number: '$overallPercentage%', label: 'Overall')),
              const SizedBox(width: WarmClayTheme.cardGap),
              Expanded(
                  child: StatCard(number: '$alphabetPercentage%', label: 'Alphabet')),
              const SizedBox(width: WarmClayTheme.cardGap),
              Expanded(
                  child: StatCard(number: '$numbersPercentage%', label: 'Numbers')),
            ],
          ),
          const SizedBox(height: WarmClayTheme.cardGap),
          const ProgressCalendarCard(),
        ],
      ),
    );
  }
}