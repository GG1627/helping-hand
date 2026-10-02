import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import '../../widgets/learning_components.dart';

class AlphabetTab extends StatelessWidget {
  const AlphabetTab({
    super.key,
    required this.learnedLetters,
    required this.selectedLetter,
    required this.onLetterSelected,
  });
  
  final Set<String> learnedLetters;
  final String? selectedLetter;
  final void Function(String) onLetterSelected;

  @override
  Widget build(BuildContext context) {
    return LearningScaffold(
      title: 'Alphabet',
      subtitle: 'A to Z. Choose a letter and practice its sign.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LearningProgress(learned: learnedLetters.length, total: 26),
          const SizedBox(height: 16),
          Hand3DViewer(selectedLetter: selectedLetter),
          const SizedBox(height: 24),
          LearningTargetGrid(
            title: 'Choose a letter',
            labels: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split(''),
            learned: learnedLetters,
            selected: selectedLetter,
            onSelected: onLetterSelected,
            maxColumns: 6,
            minimumTileWidth: 56,
          ),
        ],
      ),
    );
  }
}

class Hand3DViewer extends StatefulWidget {
  final String? selectedLetter;

  const Hand3DViewer({super.key, required this.selectedLetter});

  @override
  State<Hand3DViewer> createState() => _Hand3DViewerState();
}

class _Hand3DViewerState extends State<Hand3DViewer> {
  late Flutter3DController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Flutter3DController();
  }

  @override
  void didUpdateWidget(covariant Hand3DViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedLetter != null && widget.selectedLetter != oldWidget.selectedLetter) {
      _controller.playAnimation(animationName: 'Pose_${widget.selectedLetter}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 260,
        child: Flutter3DViewer(
          controller: _controller,
          src: 'assets/models/test.glb',
          onLoad: (String modelName) {
            if (widget.selectedLetter != null) {
              _controller.playAnimation(animationName: 'Pose_${widget.selectedLetter}');
            }
          },
        ),
      ),
    );
  }
}
