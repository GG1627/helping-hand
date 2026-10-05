import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';

class Hand3DViewer extends StatefulWidget {
  final String? selected;

  const Hand3DViewer({super.key, required this.selected});

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
    if (widget.selected != null && widget.selected != oldWidget.selected) {
      _controller.playAnimation(animationName: 'Pose_${widget.selected}');
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
            if (widget.selected != null) {
              _controller.playAnimation(animationName: 'Pose_${widget.selected}');
            }
          },
        ),
      ),
    );
  }
}
