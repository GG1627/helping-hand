import 'package:flutter/material.dart';

import '../services/ble_connection_service.dart';
import '../services/static_haptic_demo.dart';
import '../theme/helping_hand_theme.dart';
import 'haptic_hand_visualizer_widget.dart';

class StaticHapticDemoCard extends StatefulWidget {
  const StaticHapticDemoCard({
    super.key,
    required this.bleService,
    required this.completed,
  });

  final BleConnectionService bleService;
  final bool completed;

  @override
  State<StaticHapticDemoCard> createState() => _StaticHapticDemoCardState();
}

class _StaticHapticDemoCardState extends State<StaticHapticDemoCard>
    with WidgetsBindingObserver {
  late final StaticHapticDemo _demo;
  late bool _foreground;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _demo = StaticHapticDemo(widget.bleService);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    _updatePractice();
  }

  @override
  void didUpdateWidget(StaticHapticDemoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.completed != widget.completed) _updatePractice();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _updatePractice();
  }

  void _updatePractice() => _demo.setPractice(
    active: _foreground && !_leaving,
    completed: widget.completed,
  );

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _demo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope<void>(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _leaving = true;
          _updatePractice();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: HelpingHandColors.surface,
          border: Border.all(color: HelpingHandColors.outline),
          borderRadius: BorderRadius.circular(20),
        ),
        child: ListenableBuilder(
          listenable: _demo,
          builder: (context, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Demo', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Semantics(
                  liveRegion: true,
                  child: Text(_demo.status, style: theme.textTheme.bodyMedium),
                ),
                PiezoOutputHand(
                  activeOutput: _demo.activeOutput,
                  height: 212,
                  animatePulse: true,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
