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
    final learnedCount = learnedLetters.length + learnedNumbers.length;
    final totalCount = totalLetters + totalNumbers;
    final progress = totalCount == 0 ? 0.0 : learnedCount / totalCount;

    return TabScaffold(
      title: 'Home',
      backgroundAsset: 'assets/images/bg-2.png',
      actions: [
        IconButton(
          tooltip: 'Account and settings',
          onPressed: () => _showAccountSettings(context),
          icon: const Icon(Icons.account_circle_outlined),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          Text(
            'Your learning, at your pace',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Build confidence one sign at a time.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: WarmClayColors.textSecondary,
            ),
          ),
          const SizedBox(height: 22),
          _SyncStatusRow(
            status: syncStatus,
            message: syncMessage,
            onRetrySync: onRetrySync,
          ),
          const SizedBox(height: 22),
          WarmCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        'Your progress',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: WarmClayColors.accentPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ProgressBar(value: progress),
                const SizedBox(height: 10),
                Text(
                  '$learnedCount of $totalCount signs learned',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: WarmClayColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Text('Learning paths', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          _LearningPathRow(
            icon: Icons.sort_by_alpha_rounded,
            title: 'Alphabet',
            detail: '${learnedLetters.length} of $totalLetters learned',
            onTap: () => onOpenTab(1),
          ),
          _LearningPathRow(
            icon: Icons.pin_rounded,
            title: 'Numbers',
            detail: '${learnedNumbers.length} of $totalNumbers learned',
            onTap: () => onOpenTab(2),
          ),
          const _LearningPathRow(
            icon: Icons.waving_hand_outlined,
            title: 'Words',
            detail: 'Coming soon',
            comingSoon: true,
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: () => onOpenTab(1),
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Continue with the alphabet'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              alignment: Alignment.centerLeft,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAccountSettings(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
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
                  color: WarmClayColors.textSecondary,
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
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    if (sheetContext.mounted) Navigator.of(sheetContext).pop();
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
      ProgressSyncStatus.synced => WarmClayColors.success,
      ProgressSyncStatus.syncing ||
      ProgressSyncStatus.savedLocally ||
      ProgressSyncStatus.loading => WarmClayColors.info,
      ProgressSyncStatus.offlineLocalOnly => WarmClayColors.textSecondary,
      ProgressSyncStatus.syncFailure ||
      ProgressSyncStatus.localSaveFailure => WarmClayColors.error,
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
              color: WarmClayColors.textSecondary,
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
    this.comingSoon = false,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback? onTap;
  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: WarmClayTheme.cardGap),
      child: WarmCard(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: WarmClayColors.accentLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: WarmClayColors.accentPrimary, size: 22),
          ),
          title: Text(title, style: Theme.of(context).textTheme.titleMedium),
          subtitle: Text(detail),
          trailing: comingSoon
              ? const Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: WarmClayColors.textSecondary,
                )
              : const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 15,
                  color: WarmClayColors.textSecondary,
                ),
          onTap: onTap,
        ),
      ),
    );
  }
}
