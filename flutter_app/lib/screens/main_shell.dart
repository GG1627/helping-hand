import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/ble_connection_service.dart';
import '../services/ble_packet.dart';
import '../services/firebase_progress_remote_store.dart';
import '../services/json_progress_local_store.dart';
import '../services/progress_repository.dart';
import '../services/recording_service.dart';
import '../services/stable_prediction_tracker.dart';
import '../theme/warm_clay_theme.dart';
import '../widgets/stable_prediction_practice_card.dart';
import 'tabs/alphabet_tab.dart';
import 'tabs/ble_testing_tab.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/numbers_tab.dart';
import 'tabs/record_signs_tab.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.progressRepository});

  final ProgressRepository? progressRepository;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int tabIndex = 0;
  late final BleConnectionService _bleService;
  late final RecordingService _recordingService;
  late final ProgressRepository _progressRepository;
  late final bool _ownsProgressRepository;
  late ProgressRepositoryState _progressState;
  final StablePredictionTracker _predictionTracker = StablePredictionTracker();

  StreamSubscription<BlePacket>? _recordingPacketSubscription;
  StreamSubscription<ProgressRepositoryState>? _progressSubscription;
  String? _selectedPracticeTarget;
  StablePredictionResult _predictionResult =
      const StablePredictionResult.idle();

  static const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  @override
  void initState() {
    super.initState();
    _bleService = BleConnectionService();
    _recordingService = RecordingService();
    _ownsProgressRepository = widget.progressRepository == null;
    _progressRepository =
        widget.progressRepository ??
        ProgressRepository(
          localStore: JsonProgressLocalStore(),
          remoteStore: FirebaseProgressRemoteStore(),
        );
    _progressState = _progressRepository.state;
    _progressSubscription = _progressRepository.states.listen((state) {
      if (!mounted) return;
      setState(() => _progressState = state);
    });
    _recordingPacketSubscription = _bleService.packets.listen((packet) {
      _recordingService.handlePacket(packet);
      _handleLearnerPacket(packet);
    });
    unawaited(_progressRepository.initialize());
  }

  @override
  void dispose() {
    unawaited(_recordingPacketSubscription?.cancel());
    unawaited(_progressSubscription?.cancel());
    if (_ownsProgressRepository) _progressRepository.dispose();
    _recordingService.dispose();
    _bleService.dispose();
    super.dispose();
  }

  void _selectPracticeTarget(String target) {
    setState(() {
      _selectedPracticeTarget = target.toUpperCase();
      _predictionResult = _predictionTracker.selectTarget(target);
    });
  }

  void _retryPracticeTarget() {
    if (_selectedPracticeTarget == null) return;
    setState(() => _predictionResult = _predictionTracker.reset());
  }

  void _handleLearnerPacket(BlePacket packet) {
    if (_selectedPracticeTarget == null) return;
    final result = _predictionTracker.add(packet);
    if (!mounted) return;
    setState(() => _predictionResult = result);
    if (result.justCompleted) {
      unawaited(
        _progressRepository.completeStaticTarget(_selectedPracticeTarget!),
      );
    }
  }

  String get _practiceMessage {
    if (_selectedPracticeTarget == null) {
      return 'Select a letter or number to begin.';
    }
    if (!_bleService.isConnected) {
      return 'Connect the glove from BLE Testing, then hold the target sign.';
    }
    return switch (_predictionResult.feedback) {
      StablePredictionFeedback.idle ||
      StablePredictionFeedback.waitingForPacket =>
        'Waiting for a complete prediction packet...',
      StablePredictionFeedback.holding =>
        'Matching prediction. Keep holding steady...',
      StablePredictionFeedback.lowConfidence =>
        'Matching label, but confidence is too low. Adjust and retry.',
      StablePredictionFeedback.tryAgain =>
        'That prediction does not match yet. Try again.',
      StablePredictionFeedback.completed =>
        'Correct. The completion is being saved.',
    };
  }

  Widget _practiceCard() {
    return AnimatedBuilder(
      animation: _bleService,
      builder: (context, _) => StablePredictionPracticeCard(
        target: _selectedPracticeTarget,
        predictedLabel: _predictionResult.predictedLabel,
        predictedConfidence: _predictionResult.predictedConfidence,
        progress: _predictionResult.progress,
        message: _practiceMessage,
        connected: _bleService.isConnected,
        onRetry: _retryPracticeTarget,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progressState.progress;
    final selectedTarget = _selectedPracticeTarget;
    final pages = [
      DashboardTab(
        learnedLetters: progress.learnedLetters,
        totalLetters: letters.length,
        learnedNumbers: progress.learnedNumbers,
        totalNumbers: 10,
        syncStatus: _progressState.status,
        syncMessage: _progressState.message,
        onRetrySync: _progressRepository.retrySync,
        onResetProgress: _progressRepository.reset,
      ),
      AlphabetTab(
        learnedLetters: progress.learnedLetters,
        selectedLetter:
            selectedTarget != null &&
                RegExp(r'^[A-Z]$').hasMatch(selectedTarget)
            ? selectedTarget
            : null,
        practiceCard: _practiceCard(),
        onLetterSelected: _selectPracticeTarget,
      ),
      NumbersTab(
        learnedNumbers: progress.learnedNumbers,
        selectedNumber: selectedTarget == null
            ? null
            : int.tryParse(selectedTarget),
        practiceCard: _practiceCard(),
        onNumberSelected: (number) => _selectPracticeTarget('$number'),
      ),
      RecordSignsTab(
        bleService: _bleService,
        recordingService: _recordingService,
      ),
      BleTestingTab(bleService: _bleService),
    ];

    return Scaffold(
      body: IndexedStack(index: tabIndex, children: pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: WarmClayColors.surface,
          border: Border(top: BorderSide(color: WarmClayColors.border)),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: WarmClayColors.surface,
            indicatorColor: WarmClayColors.accentLight,
            labelTextStyle: WidgetStateProperty.all(
              GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return IconThemeData(
                color: selected
                    ? WarmClayColors.accentPrimary
                    : WarmClayColors.textSecondary,
              );
            }),
          ),
          child: NavigationBar(
            elevation: 0,
            selectedIndex: tabIndex,
            onDestinationSelected: (index) {
              setState(() => tabIndex = index);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.sort_by_alpha_outlined),
                selectedIcon: Icon(Icons.sort_by_alpha_rounded),
                label: 'Alphabet',
              ),
              NavigationDestination(
                icon: Icon(Icons.pin_outlined),
                selectedIcon: Icon(Icons.pin_rounded),
                label: 'Numbers',
              ),
              NavigationDestination(
                icon: Icon(Icons.fiber_manual_record_outlined),
                selectedIcon: Icon(Icons.fiber_manual_record),
                label: 'Record Signs',
              ),
              NavigationDestination(
                icon: Icon(Icons.memory_outlined),
                selectedIcon: Icon(Icons.memory_rounded),
                label: 'BLE Testing',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
