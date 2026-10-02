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
import '../theme/helping_hand_theme.dart';
import '../widgets/stable_prediction_practice_card.dart';
import 'tabs/alphabet_tab.dart';
import 'tabs/ble_testing_tab.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/numbers_tab.dart';
import 'tabs/record_signs_tab.dart';
import 'tabs/developer_tools_tab.dart';
import 'tabs/words_tab.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.userId,
    required this.email,
    required this.onSignOut,
    this.progressRepository,
  });

  final String userId;
  final String email;
  final Future<void> Function() onSignOut;
  final ProgressRepository? progressRepository;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int tabIndex = 0;
  bool _developerMode = false;
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
          localStore: JsonProgressLocalStore.forUser(widget.userId),
          remoteStore: FirebaseProgressRemoteStore(uid: widget.userId),
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
    final List<Widget> pages = [
      DashboardTab(
        learnedLetters: progress.learnedLetters,
        totalLetters: letters.length,
        learnedNumbers: progress.learnedNumbers,
        totalNumbers: 10,
        syncStatus: _progressState.status,
        syncMessage: _progressState.message,
        accountEmail: widget.email,
        developerMode: _developerMode,
        onDeveloperModeChanged: _setDeveloperMode,
        onRetrySync: _progressRepository.retrySync,
        onResetProgress: _progressRepository.reset,
        onSignOut: widget.onSignOut,
        onOpenTab: (index) => setState(() => tabIndex = index),
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
      const WordsTab(),
    ];
    if (_developerMode) {
      pages.addAll([
        RecordSignsTab(
          bleService: _bleService,
          recordingService: _recordingService,
        ),
        BleTestingTab(bleService: _bleService),
        DeveloperToolsTab(
          onOpenRecordSigns: () => setState(() => tabIndex = 4),
          onOpenBleTesting: () => setState(() => tabIndex = 5),
        ),
      ]);
    }

    return Scaffold(
      body: IndexedStack(index: tabIndex, children: pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: HelpingHandColors.surface,
          border: Border(top: BorderSide(color: HelpingHandColors.divider)),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: HelpingHandColors.surface,
            indicatorColor: HelpingHandColors.secondary,
            labelTextStyle: WidgetStateProperty.resolveWith(
              (states) => GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: states.contains(WidgetState.selected)
                    ? HelpingHandColors.primary
                    : HelpingHandColors.textSecondary,
              ),
            ),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return IconThemeData(
                color: selected
                    ? HelpingHandColors.primary
                    : HelpingHandColors.textSecondary,
              );
            }),
          ),
          child: NavigationBar(
            elevation: 0,
            selectedIndex: tabIndex >= 4 ? 4 : tabIndex,
            onDestinationSelected: (index) {
              setState(() => tabIndex = index == 4 ? 6 : index);
            },
            destinations: [
              const NavigationDestination(
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
              const NavigationDestination(
                icon: Icon(Icons.waving_hand_outlined),
                selectedIcon: Icon(Icons.waving_hand_rounded),
                label: 'Words',
              ),
              if (_developerMode)
                const NavigationDestination(
                  icon: Icon(Icons.build_outlined),
                  selectedIcon: Icon(Icons.build_rounded),
                  label: 'Developer',
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _setDeveloperMode(bool enabled) {
    setState(() {
      _developerMode = enabled;
      if (!enabled && tabIndex >= 4) tabIndex = 0;
    });
  }
}
