import 'package:flutter/material.dart';

import '../../theme/warm_clay_theme.dart';
import '../../widgets/warm_components.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const TabScaffold(
      title: 'Dashboard',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreakPill(text: '12 day streak'),
          SizedBox(height: WarmClayTheme.cardGap),
          WarmCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Overall Progress'),
                SizedBox(height: 8),
                ProgressBar(value: 0.54),
                SizedBox(height: 8),
                Text('19 of 35 targets complete'),
              ],
            ),
          ),
          SizedBox(height: WarmClayTheme.cardGap),
          Row(
            children: [
              Expanded(
                child: StatCard(number: '54%', label: 'Overall'),
              ),
              SizedBox(width: WarmClayTheme.cardGap),
              Expanded(
                child: StatCard(number: '62%', label: 'Alphabet'),
              ),
              SizedBox(width: WarmClayTheme.cardGap),
              Expanded(
                child: StatCard(number: '30%', label: 'Numbers'),
              ),
            ],
          ),
          SizedBox(height: WarmClayTheme.cardGap),
          ProgressCalendarCard(),
        ],
      ),
    );
  }
}
