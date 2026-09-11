import 'package:flutter/material.dart';

import '../../services/progress_repository.dart';
import '../../theme/warm_clay_theme.dart';
import '../../widgets/warm_components.dart';

class DashboardTab extends StatelessWidget {
  final Set<String> learnedLetters;
  final int totalLetters;
  final Set<int> learnedNumbers;
  final int totalNumbers;
  final ProgressSyncStatus syncStatus;
  final String syncMessage;
  final Future<void> Function() onRetrySync;
  final Future<void> Function() onResetProgress;

  const DashboardTab({
    super.key,
    required this.learnedLetters,
    required this.totalLetters,
    required this.learnedNumbers,
    required this.totalNumbers,
    required this.syncStatus,
    required this.syncMessage,
    required this.onRetrySync,
    required this.onResetProgress,
  });

  @override
  Widget build(BuildContext context) {
    final lettersLearned = learnedLetters.length;
    final numbersLearned = learnedNumbers.length;

    final alphabetPercentage = totalLetters > 0
        ? (lettersLearned / totalLetters * 100).toStringAsFixed(0)
        : '0';
    final numbersPercentage = totalNumbers > 0
        ? (numbersLearned / totalNumbers * 100).toStringAsFixed(0)
        : '0';

    // Overall progress: combine letters + numbers
    final overallPercentage =
        ((lettersLearned + numbersLearned) /
                (totalLetters + totalNumbers) *
                100)
            .toStringAsFixed(0);

    return TabScaffold(
      title: 'Dashboard',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProgressStorageCard(
            status: syncStatus,
            message: syncMessage,
            onRetrySync: onRetrySync,
            onResetProgress: onResetProgress,
          ),
          const SizedBox(height: WarmClayTheme.cardGap),
          WarmCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Overall Progress'),
                const SizedBox(height: 8),
                ProgressBar(
                  value:
                      (lettersLearned + numbersLearned) /
                      (totalLetters + totalNumbers),
                ),
                const SizedBox(height: 8),
                Text(
                  '$lettersLearned/$totalLetters letters, '
                  '$numbersLearned/$totalNumbers numbers',
                ),
              ],
            ),
          ),
          const SizedBox(height: WarmClayTheme.cardGap),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  number: '$overallPercentage%',
                  label: 'Overall',
                ),
              ),
              const SizedBox(width: WarmClayTheme.cardGap),
              Expanded(
                child: StatCard(
                  number: '$alphabetPercentage%',
                  label: 'Alphabet',
                ),
              ),
              const SizedBox(width: WarmClayTheme.cardGap),
              Expanded(
                child: StatCard(
                  number: '$numbersPercentage%',
                  label: 'Numbers',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressStorageCard extends StatelessWidget {
  const _ProgressStorageCard({
    required this.status,
    required this.message,
    required this.onRetrySync,
    required this.onResetProgress,
  });

  final ProgressSyncStatus status;
  final String message;
  final Future<void> Function() onRetrySync;
  final Future<void> Function() onResetProgress;

  @override
  Widget build(BuildContext context) {
    final retryAvailable =
        status == ProgressSyncStatus.offlineLocalOnly ||
        status == ProgressSyncStatus.syncFailure;
    final isBusy =
        status == ProgressSyncStatus.loading ||
        status == ProgressSyncStatus.syncing;

    return WarmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_iconFor(status), color: _colorFor(status)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Progress storage',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (isBusy)
                const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(
            'Saved on this phone first; cloud sync uses an anonymous account.',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              if (retryAvailable)
                TextButton(
                  onPressed: onRetrySync,
                  child: const Text('Retry sync'),
                ),
              TextButton(
                onPressed: () => _confirmReset(context),
                child: const Text('Reset progress'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset progress?'),
        content: const Text(
          'This clears learned letters, numbers, and completed exercises on '
          'this phone and the synchronized progress document.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true) await onResetProgress();
  }

  IconData _iconFor(ProgressSyncStatus status) {
    return switch (status) {
      ProgressSyncStatus.synced => Icons.cloud_done_outlined,
      ProgressSyncStatus.syncing => Icons.cloud_sync_outlined,
      ProgressSyncStatus.savedLocally => Icons.save_outlined,
      ProgressSyncStatus.offlineLocalOnly => Icons.cloud_off_outlined,
      ProgressSyncStatus.syncFailure => Icons.sync_problem_outlined,
      ProgressSyncStatus.localSaveFailure => Icons.error_outline,
      ProgressSyncStatus.loading => Icons.hourglass_top_rounded,
    };
  }

  Color _colorFor(ProgressSyncStatus status) {
    return switch (status) {
      ProgressSyncStatus.synced => const Color(0xFF3C8C62),
      ProgressSyncStatus.syncing ||
      ProgressSyncStatus.savedLocally ||
      ProgressSyncStatus.loading => WarmClayColors.accentPrimary,
      ProgressSyncStatus.offlineLocalOnly => WarmClayColors.textSecondary,
      ProgressSyncStatus.syncFailure ||
      ProgressSyncStatus.localSaveFailure => const Color(0xFFA94B3F),
    };
  }
}
