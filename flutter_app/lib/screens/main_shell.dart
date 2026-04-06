import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/warm_clay_theme.dart';
import 'tabs/alphabet_tab.dart';
import 'tabs/ble_testing_tab.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/numbers_tab.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int tabIndex = 0;

  Set<String> learnedLetters = {};
  Set<int> learnedNumbers = {};

  static const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

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
      NumbersTab(
        learnedNumbers: learnedNumbers,
        onNumberLearned: toggleNumber,
      ),
      BleTestingTab(),
    ];

    return Scaffold(
      body: pages[tabIndex],
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
