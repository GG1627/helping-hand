import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../services/piezo_demo_protocol.dart';

class HapticHandVisualizerWidget extends StatelessWidget {
  const HapticHandVisualizerWidget({
    super.key,
    required this.fingerErrors, // -1.0 to +1.0
    required this.motorStates,
    this.imuRoll = 0.0,
    this.emphasizeOutputs = false,
  });

  final List<double> fingerErrors; 
  final List<double> motorStates; 
  final double imuRoll;
  final bool emphasizeOutputs;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 340,
      child: CustomPaint(
        painter: _HapticHandPainter(
          fingerErrors: fingerErrors,
          motorStates: motorStates,
          imuRoll: imuRoll,
          emphasizeOutputs: emphasizeOutputs,
        ),
      ),
    );
  }
}

// Update inside haptic_hand_visualizer_widget.dart

class _HapticHandPainter extends CustomPainter {
  const _HapticHandPainter({
    required this.fingerErrors,
    required this.motorStates,
    required this.imuRoll,
    required this.emphasizeOutputs,
  });

  final List<double> fingerErrors;
  final List<double> motorStates; // Expected length: 10 (0-4 fingers, 5-9 matrix)
  final double imuRoll;
  final bool emphasizeOutputs;

  static const Color _fillColor = Color(0xFFF5F5F5);
  static const Color _strokeColor = Color(0xFFBDBDBD);
  static const Color _bendMoreColor = Color(0xFFD35400);
  static const Color _relaxColor = Color(0xFF2980B9);
  static const Color _nodeActiveColor = Color(0xFFE74C3C);
  static const double _strokeWidth = 1.5;

  double _errorAt(int index) {
    if (index < 0 || index >= fingerErrors.length) return 0.0;
    return fingerErrors[index].clamp(-1.0, 1.0);
  }

  Color _fingerColor(int index) {
    final error = _errorAt(index);
    if (error > 0.1) {
      return Color.lerp(_fillColor, _bendMoreColor, error)!;
    } else if (error < -0.1) {
      return Color.lerp(_fillColor, _relaxColor, -error)!;
    }
    return _fillColor;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paintFill = Paint()
      ..style = PaintingStyle.fill
      ..color = _fillColor;
    final paintStroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = _strokeColor
      ..strokeWidth = _strokeWidth;

    void drawPoly(List<Offset> points, {Color fillColor = _fillColor}) {
      paintFill.color = fillColor;
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      path.close();
      canvas.drawPath(path, paintFill);
      canvas.drawPath(path, paintStroke);
    }

    List<Offset> trapezoid({
      required double cx,
      required double yBottom,
      required double yTop,
      required double wBottom,
      required double wTop,
    }) {
      return [
        Offset(cx - wBottom / 2, yBottom),
        Offset(cx + wBottom / 2, yBottom),
        Offset(cx + wTop / 2, yTop),
        Offset(cx - wTop / 2, yTop),
      ];
    }

    void drawFinger({
      required double centerX,
      required double baseY,
      required double totalHeight,
      required double baseWidth,
      required double tipWidth,
      Color fillColor = _fillColor,
    }) {
      final y0 = baseY;
      final y1 = baseY - totalHeight * 0.37;
      final y2 = baseY - totalHeight * 0.71;
      final y3 = baseY - totalHeight;

      final w0 = baseWidth;
      final w1 = baseWidth + (tipWidth - baseWidth) * 0.38;
      final w2 = baseWidth + (tipWidth - baseWidth) * 0.72;
      final w3 = tipWidth;

      drawPoly(
        trapezoid(cx: centerX, yBottom: y0, yTop: y1, wBottom: w0, wTop: w1),
        fillColor: fillColor,
      );
      drawPoly(
        trapezoid(cx: centerX, yBottom: y1, yTop: y2, wBottom: w1, wTop: w2),
        fillColor: fillColor,
      );
      drawPoly(
        trapezoid(cx: centerX, yBottom: y2, yTop: y3, wBottom: w2, wTop: w3),
        fillColor: fillColor,
      );
    }

    List<Offset> rotateAndTranslate(
      List<Offset> points,
      Offset origin,
      double angleDeg,
    ) {
      final rad = angleDeg * math.pi / 180.0;
      final c = math.cos(rad);
      final s = math.sin(rad);
      return points
          .map(
            (p) => Offset(
              origin.dx + p.dx * c - p.dy * s,
              origin.dy + p.dx * s + p.dy * c,
            ),
          )
          .toList();
    }

    void drawThumbSegment({
      required Offset base,
      required double angleDeg,
      required double length,
      required double wBottom,
      required double wTop,
      Color fillColor = _fillColor,
    }) {
      final local = [
        Offset(-wBottom / 2, 0),
        Offset(wBottom / 2, 0),
        Offset(wTop / 2, -length),
        Offset(-wTop / 2, -length),
      ];
      drawPoly(rotateAndTranslate(local, base, angleDeg), fillColor: fillColor);
    }

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(imuRoll);
    canvas.translate(-size.width / 2, -size.height / 2);

    // 1. Draw Thumb Segments
    const thumbBase = Offset(48, 220);
    const thumbAngleDeg = -35.0;
    final thumbColor = _fingerColor(0);
    drawThumbSegment(
      base: thumbBase,
      angleDeg: thumbAngleDeg,
      length: 54,
      wBottom: 36,
      wTop: 28,
      fillColor: thumbColor,
    );

    final thumbJoint = rotateAndTranslate(
      [const Offset(0, -54)],
      thumbBase,
      thumbAngleDeg,
    ).first;
    drawThumbSegment(
      base: thumbJoint,
      angleDeg: thumbAngleDeg,
      length: 40,
      wBottom: 28,
      wTop: 22,
      fillColor: thumbColor,
    );

    // 2. Draw Palm
    final palm = [
      const Offset(48, 172),
      const Offset(172, 172),
      const Offset(188, 230),
      const Offset(158, 298),
      const Offset(62, 298),
      const Offset(34, 230),
    ];
    drawPoly(palm);

    // 3. Draw Fingers (Index = 1, Middle = 2, Ring = 3, Pinky = 4)
    const fingerBaseY = 172.0;
    drawFinger(
      centerX: 65, baseY: fingerBaseY, totalHeight: 110, baseWidth: 32, tipWidth: 22,
      fillColor: _fingerColor(1),
    );
    drawFinger(
      centerX: 96, baseY: fingerBaseY, totalHeight: 132, baseWidth: 30, tipWidth: 20,
      fillColor: _fingerColor(2),
    );
    drawFinger(
      centerX: 128, baseY: fingerBaseY, totalHeight: 129, baseWidth: 30, tipWidth: 23,
      fillColor: _fingerColor(3),
    );
    drawFinger(
      centerX: 157, baseY: fingerBaseY, totalHeight: 96, baseWidth: 28, tipWidth: 20,
      fillColor: _fingerColor(4),
    );

    // 4. Draw Individual Finger Haptic Nodes (Indices 0 to 4 mapped on physical finger locations)
    final nodePaint = Paint()..style = PaintingStyle.fill;
    void drawOutput(Offset center, double radius, double intensity) {
      nodePaint.color = intensity > 0
          ? Color.lerp(
              Colors.grey.shade400,
              _nodeActiveColor,
              intensity.clamp(0.0, 1.0),
            )!
          : emphasizeOutputs
          ? Colors.grey.shade600
          : Colors.grey.shade300;
      canvas.drawCircle(center, radius, nodePaint);
      if (emphasizeOutputs && intensity > 0) {
        canvas.drawCircle(
          center,
          radius + 5,
          Paint()
            ..color = _nodeActiveColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
      }
    }
    const double fingerNodeRadius = 4.5;

    final List<Offset> fingerNodeCenters = [
      rotateAndTranslate([const Offset(0, -20)], thumbJoint, thumbAngleDeg).first, // Thumb Node (0)
      const Offset(65, 115),  // Index Node (1)
      const Offset(96, 100),  // Middle Node (2)
      const Offset(128, 105), // Ring Node (3)
      const Offset(157, 120), // Pinky Node (4)
    ];

    for (int i = 0; i < 5; i++) {
      final intensity = motorStates.length > i ? motorStates[i] : 0.0;
      drawOutput(fingerNodeCenters[i], fingerNodeRadius, intensity);
    }

    // 5. Draw Back-of-Hand Plus-Formation Matrix Nodes (Indices 5 to 9)
    const palmCenter = Offset(110, 235);
    const double matrixNodeRadius = 6.0;
    
    final matrixOffsets = [
      palmCenter,                        // 5: Center
      palmCenter + const Offset(0, -22), // 6: Top
      palmCenter + const Offset(0, 22),  // 7: Bottom
      palmCenter + const Offset(-22, 0), // 8: Left
      palmCenter + const Offset(22, 0),  // 9: Right
    ];

    for (int i = 0; i < 5; i++) {
      final motorIdx = i + 5;
      final intensity = motorStates.length > motorIdx ? motorStates[motorIdx] : 0.0;
      drawOutput(matrixOffsets[i], matrixNodeRadius, intensity);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HapticHandPainter oldDelegate) => true;
}

class PiezoOutputHand extends StatelessWidget {
  const PiezoOutputHand({
    super.key,
    this.activeOutput,
    this.height = 300,
    this.animatePulse = false,
  });

  final PiezoOutput? activeOutput;
  final double height;
  final bool animatePulse;

  @override
  Widget build(BuildContext context) {
    if (!animatePulse ||
        activeOutput == null ||
        MediaQuery.disableAnimationsOf(context)) {
      return _hand(1);
    }
    return TweenAnimationBuilder<double>(
      key: ValueKey(activeOutput),
      tween: Tween(begin: 0.28, end: 1),
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      builder: (context, intensity, _) => _hand(intensity),
    );
  }

  Widget _hand(double intensity) {
    final states = List<double>.filled(PiezoOutput.values.length, 0);
    final output = activeOutput;
    if (output != null) states[output.marker] = intensity;
    return SizedBox(
      height: height,
      child: FittedBox(
        child: HapticHandVisualizerWidget(
          fingerErrors: const [0, 0, 0, 0, 0],
          motorStates: states,
          emphasizeOutputs: true,
        ),
      ),
    );
  }
}
