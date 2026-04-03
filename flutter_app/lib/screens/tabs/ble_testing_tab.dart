import 'package:flutter/material.dart';

import '../../widgets/warm_components.dart';

class BleTestingTab extends StatelessWidget {
  const BleTestingTab({super.key});

  @override
  Widget build(BuildContext context) {
    return TabScaffold(
      title: 'BLE Testing',
      child: WarmCard(
        child: Text(
          'BLE testing area is intentionally blank for now.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
