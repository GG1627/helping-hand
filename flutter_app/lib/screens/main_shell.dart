import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/ble_connection_service.dart';
import '../services/ble_packet.dart';
import '../services/recording_service.dart';
import '../theme/warm_clay_theme.dart';
import 'tabs/alphabet_tab.dart';
import 'tabs/ble_testing_tab.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/numbers_tab.dart';
import 'tabs/record_signs_tab.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int tabIndex = 0;
  late final BleConnectionService _bleService;
  late final RecordingService _recordingService;
  StreamSubscription<BlePacket>? _recordingPacketSubscription;

  Set<String> learnedLetters = {};
  Set<int> learnedNumbers = {};

  static const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  @override
  void initState() {
    super.initState();
    _bleService = BleConnectionService();
    _recordingService = RecordingService();
    _recordingPacketSubscription = _bleService.packets.listen(
      _recordingService.handlePacket,
    );
  }

  @override
  void dispose() {
    unawaited(_recordingPacketSubscription?.cancel());
    _recordingService.dispose();
    _bleService.dispose();
    super.dispose();
  }

  void markLetterLearned(String letter) {
    setState(() {
      if (learnedLetters.contains(letter)) {
        learnedLetters.remove(letter);
      } else {
        learnedLetters.add(letter);
      }
    });
  }

  void toggleNumber(int number) {
    setState(() {
      if (learnedNumbers.contains(number)) {
        learnedNumbers.remove(number);
      } else {
        learnedNumbers.add(number);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardTab(
        learnedLetters: learnedLetters,
        totalLetters: letters.length,
        learnedNumbers: learnedNumbers,
        totalNumbers: 10,
      ),
      AlphabetTab(
        learnedLetters: learnedLetters,
        onLetterLearned: markLetterLearned,
      ),
      NumbersTab(learnedNumbers: learnedNumbers, onNumberLearned: toggleNumber),
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
              setState(() {
                tabIndex = index;
              });
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
