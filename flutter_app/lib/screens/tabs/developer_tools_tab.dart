import 'package:flutter/material.dart';

import '../../theme/warm_clay_theme.dart';
import '../../widgets/warm_components.dart';

class DeveloperToolsTab extends StatelessWidget {
  const DeveloperToolsTab({
    super.key,
    required this.onOpenRecordSigns,
    required this.onOpenBleTesting,
  });

  final VoidCallback onOpenRecordSigns;
  final VoidCallback onOpenBleTesting;

  @override
  Widget build(BuildContext context) {
    return TabScaffold(
      title: 'Developer tools',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WarmCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Research mode',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                const Text(
                  'These tools support glove diagnostics and data collection. '
                  'They are hidden from the learner navigation when Developer '
                  'Mode is off.',
                ),
              ],
            ),
          ),
          const SizedBox(height: WarmClayTheme.cardGap),
          _ToolCard(
            icon: Icons.fiber_manual_record_outlined,
            title: 'Record Signs',
            description: 'Capture and export labeled sensor trials.',
            onTap: onOpenRecordSigns,
          ),
          const SizedBox(height: WarmClayTheme.cardGap),
          _ToolCard(
            icon: Icons.memory_outlined,
            title: 'BLE Testing',
            description: 'Connect the glove and inspect live sensor packets.',
            onTap: onOpenBleTesting,
          ),
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WarmCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, color: WarmClayColors.accentPrimary),
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
