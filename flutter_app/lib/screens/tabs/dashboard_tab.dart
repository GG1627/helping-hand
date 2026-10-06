import 'package:flutter/material.dart';

import '../../services/progress_repository.dart';
import '../../theme/helping_hand_theme.dart';
import '../../widgets/brand_components.dart';

class DashboardTab extends StatelessWidget {
  final Set<String> learnedLetters;
  final int totalLetters;
  final Set<int> learnedNumbers;
  final int totalNumbers;
  final Set<String> learnedWords;
  final int totalWords;
  final ProgressSyncStatus syncStatus;
  final String syncMessage;
  final String accountEmail;
  final bool developerMode;
  final ValueChanged<bool> onDeveloperModeChanged;
  final Future<void> Function() onRetrySync;
  final Future<void> Function() onResetProgress;
  final Future<void> Function() onSignOut;
  final ValueChanged<int> onOpenTab;

  const DashboardTab({
    super.key,
    required this.learnedLetters,
    required this.totalLetters,
    required this.learnedNumbers,
    required this.totalNumbers,
    this.learnedWords = const {},
    this.totalWords = 0,
    required this.syncStatus,
    required this.syncMessage,
    required this.accountEmail,
    required this.developerMode,
    required this.onDeveloperModeChanged,
    required this.onRetrySync,
    required this.onResetProgress,
    required this.onSignOut,
    required this.onOpenTab,
  });

  @override
  Widget build(BuildContext context) {
    final learnedCount =
        learnedLetters.length + learnedNumbers.length + learnedWords.length;
    final totalCount = totalLetters + totalNumbers + totalWords;
    final progress = totalCount == 0 ? 0.0 : learnedCount / totalCount;
    final needsAttention =
        syncStatus == ProgressSyncStatus.syncFailure ||
        syncStatus == ProgressSyncStatus.localSaveFailure ||
        syncStatus == ProgressSyncStatus.offlineLocalOnly;

    return Theme(
      data: HelpingHandTheme.build(),
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final sync = _SyncStatusRow(
            status: syncStatus,
            message: syncMessage,
            onRetrySync: onRetrySync,
          );
          return Scaffold(
            backgroundColor: HelpingHandColors.background,
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final gutter = constraints.maxWidth < 360
                      ? 16.0
                      : constraints.maxWidth >= 600
                      ? 32.0
                      : 24.0;
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 32),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 960),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      HelpingHandWordmark(
                                        compact: true,
                                        centered: false,
                                        singleLine: true,
                                      ),
                                      SizedBox(height: 8),
                                      HelpingHandBrandTrail(),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                IconButton(
                                  tooltip: 'Account and settings',
                                  constraints: const BoxConstraints(
                                    minWidth: 48,
                                    minHeight: 48,
                                  ),
                                  onPressed: () =>
                                      _showAccountSettings(context),
                                  icon: const Icon(
                                    Icons.account_circle_outlined,
                                    color: HelpingHandColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            LayoutBuilder(
                              builder: (context, layout) {
                                final invitation = _PracticeInvitation(
                                  onPractice: () => onOpenTab(1),
                                );
                                final savedProgress = _LearningProgress(
                                  learned: learnedCount,
                                  total: totalCount,
                                  value: progress,
                                );
                                if (layout.maxWidth >= 840) {
                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(flex: 3, child: invitation),
                                      const SizedBox(width: 32),
                                      Expanded(flex: 2, child: savedProgress),
                                    ],
                                  );
                                }
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    invitation,
                                    const SizedBox(height: 32),
                                    savedProgress,
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            if (needsAttention) ...[
                              sync,
                              const SizedBox(height: 32),
                            ],
                            Semantics(
                              header: true,
                              child: Text(
                                'Learning paths',
                                style: theme.textTheme.titleLarge,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _LearningPathRow(
                              icon: Icons.sort_by_alpha_outlined,
                              title: 'Alphabet',
                              detail:
                                  '${learnedLetters.length} of $totalLetters learned',
                              onTap: () => onOpenTab(1),
                            ),
                            const Divider(),
                            _LearningPathRow(
                              icon: Icons.pin_outlined,
                              title: 'Numbers',
                              detail:
                                  '${learnedNumbers.length} of $totalNumbers learned',
                              onTap: () => onOpenTab(2),
                            ),
                            const Divider(),
                            _LearningPathRow(
                              icon: Icons.waving_hand_outlined,
                              title: 'Words',
                              detail:
                                  '$totalWords words with recognition · ${learnedWords.length} completed',
                              onTap: () => onOpenTab(3),
                            ),
                            if (!needsAttention) ...[
                              const SizedBox(height: 24),
                              sync,
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAccountSettings(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      builder: (sheetContext) => SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account and settings',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  accountEmail.isEmpty ? 'Signed in' : accountEmail,
                  style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                    color: HelpingHandColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Developer mode'),
                  subtitle: const Text(
                    'Show Record Signs and BLE Testing tools in this session.',
                  ),
                  value: developerMode,
                  onChanged: (enabled) {
                    onDeveloperModeChanged(enabled);
                    Navigator.of(sheetContext).pop();
                  },
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: sheetContext,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Reset progress?'),
                        content: const Text(
                          'This clears learned letters, numbers, and completed '
                          'exercises on this phone and the synchronized progress '
                          'document.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(true),
                            style: FilledButton.styleFrom(
                              backgroundColor: HelpingHandColors.error,
                            ),
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      if (sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                      }
                      await onResetProgress();
                    }
                  },
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('Reset progress'),
                ),
                TextButton.icon(
                  onPressed: onSignOut,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SyncStatusRow extends StatelessWidget {
  const _SyncStatusRow({
    required this.status,
    required this.message,
    required this.onRetrySync,
  });

  final ProgressSyncStatus status;
  final String message;
  final Future<void> Function() onRetrySync;

  @override
  Widget build(BuildContext context) {
    final retryAvailable =
        status == ProgressSyncStatus.offlineLocalOnly ||
        status == ProgressSyncStatus.syncFailure;
    final busy =
        status == ProgressSyncStatus.loading ||
        status == ProgressSyncStatus.syncing;
    final color = switch (status) {
      ProgressSyncStatus.synced => HelpingHandColors.success,
      ProgressSyncStatus.syncing ||
      ProgressSyncStatus.savedLocally ||
      ProgressSyncStatus.loading => HelpingHandColors.primary,
      ProgressSyncStatus.offlineLocalOnly => HelpingHandColors.textSecondary,
      ProgressSyncStatus.syncFailure ||
      ProgressSyncStatus.localSaveFailure => HelpingHandColors.error,
    };

    return Row(
      children: [
        if (busy)
          SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: color),
          )
        else
          Icon(_iconFor(status), size: 19, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color:
                  status == ProgressSyncStatus.syncFailure ||
                      status == ProgressSyncStatus.localSaveFailure
                  ? HelpingHandColors.error
                  : HelpingHandColors.textSecondary,
            ),
          ),
        ),
        if (retryAvailable)
          TextButton(onPressed: onRetrySync, child: const Text('Retry')),
      ],
    );
  }

  IconData _iconFor(ProgressSyncStatus status) => switch (status) {
    ProgressSyncStatus.synced => Icons.cloud_done_outlined,
    ProgressSyncStatus.syncing => Icons.cloud_sync_outlined,
    ProgressSyncStatus.savedLocally => Icons.save_outlined,
    ProgressSyncStatus.offlineLocalOnly => Icons.cloud_off_outlined,
    ProgressSyncStatus.syncFailure => Icons.sync_problem_outlined,
    ProgressSyncStatus.localSaveFailure => Icons.error_outline,
    ProgressSyncStatus.loading => Icons.hourglass_top_rounded,
  };
}

class _LearningPathRow extends StatelessWidget {
  const _LearningPathRow({
    required this.icon,
    required this.title,
    required this.detail,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      minLeadingWidth: 40,
      leading: ExcludeSemantics(
        child: Icon(icon, size: 28, color: HelpingHandColors.primary),
      ),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(detail, style: Theme.of(context).textTheme.bodySmall),
      ),
      trailing: Icon(
        Icons.arrow_forward_rounded,
        size: 20,
        color: HelpingHandColors.textSecondary,
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

class _PracticeInvitation extends StatelessWidget {
  const _PracticeInvitation({required this.onPractice});
  final VoidCallback onPractice;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ColoredBox(
      color: HelpingHandColors.secondary,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Alphabet practice',
              style: text.bodySmall?.copyWith(
                color: HelpingHandColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Semantics(
              header: true,
              child: Text('Ready, set, sign.', style: text.headlineMedium),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a letter and practice with your glove.',
              style: text.bodySmall,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onPractice,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(child: Text('Practice alphabet')),
                  SizedBox(width: 12),
                  Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LearningProgress extends StatelessWidget {
  const _LearningProgress({
    required this.learned,
    required this.total,
    required this.value,
  });
  final int learned;
  final int total;
  final double value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text('Your progress', style: text.titleLarge)),
            const SizedBox(width: 16),
            Text(
              '${(value * 100).round()}%',
              style: text.titleLarge?.copyWith(
                color: HelpingHandColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value.clamp(0, 1),
            minHeight: 8,
            color: HelpingHandColors.primary,
            backgroundColor: HelpingHandColors.divider,
            semanticsLabel: '$learned of $total signs learned',
            semanticsValue: '${(value.clamp(0, 1) * 100).round()}',
          ),
        ),
        const SizedBox(height: 8),
        Text('$learned of $total signs learned', style: text.bodySmall),
      ],
    );
  }
}
