import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';

class TestHandPage extends StatefulWidget {
  const TestHandPage({super.key});

  @override
  State<TestHandPage> createState() => _TestHandPageState();
}

class _TestHandPageState extends State<TestHandPage> {
  final Flutter3DController _controller = Flutter3DController();
  String selectedLetter = 'A';

  void _applyPose(String letter) {
    // If your GLB model contains baked skeletal animations named 'Pose_A', 'Pose_B', etc.:
    _controller.playAnimation(animationName: 'Pose_$letter');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modular 3D Hand Tester'),
        actions: [
          DropdownButton<String>(
            value: selectedLetter,
            dropdownColor: Colors.grey[800],
            style: const TextStyle(color: Colors.white, fontSize: 18),
            items: ASLPoseDictionary.poses.keys.map((String letter) {
              return DropdownMenuItem<String>(
                value: letter,
                child: Text('Letter $letter'),
              );
            }).toList(),
            onChanged: (String? newLetter) {
              if (newLetter != null) {
                setState(() => selectedLetter = newLetter);
                _applyPose(newLetter);
              }
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.7,
          child: Flutter3DViewer(
            controller: _controller,
            src: 'assets/models/test.glb',
            onLoad: (String modelName) {
              debugPrint('Model $modelName loaded!');
              _applyPose(selectedLetter);
            },
          ),
        ),
      ),
    );
  }
}