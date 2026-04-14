import 'dart:math' as math;

import 'package:flutter/material.dart';

class HandVisualizerWidget extends StatelessWidget {
  const HandVisualizerWidget({
    super.key,
    required this.bendValues,
    this.imuRoll = 0.0,
  });

  final List<double> bendValues; // [thumb, index, middle, ring, pinky]
  final double imuRoll; // radians

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 340,
      child: CustomPaint(
        painter: _HandPainter(
          bendValues: bendValues,
          imuRoll: imuRoll,
        ),
      ),
    );
  }
}

class _HandPainter extends CustomPainter {
  const _HandPainter({
    required this.bendValues,
    required this.imuRoll,
  });

  final List<double> bendValues;
  final double imuRoll;

  static const Color _fillColor = Color(0xFFF5F5F5);
  static const Color _activeColor = Color(0xFF1565C0);
  static const Color _strokeColor = Color(0xFFBDBDBD);
  static const double _strokeWidth = 1.5;

  double _bendAt(int index) {
    if (index < 0 || index >= bendValues.length) return 0.0;
    return bendValues[index].clamp(0.0, 1.0);
  }

  Color _fingerColor(int index) {
    return Color.lerp(_fillColor, _activeColor, _bendAt(index)) ?? _fillColor;
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

    final palm = [
      const Offset(48, 172),
      const Offset(172, 172),
      const Offset(188, 230),
      const Offset(158, 298),
      const Offset(62, 298),
      const Offset(34, 230),
    ];
    drawPoly(palm);

    const fingerBaseY = 172.0;
    drawFinger(
      centerX: 65,
      baseY: fingerBaseY,
      totalHeight: 110,
      baseWidth: 32,
      tipWidth: 22,
      fillColor: _fingerColor(1),
    );
    drawFinger(
      centerX: 96,
      baseY: fingerBaseY,
      totalHeight: 132,
      baseWidth: 30,
      tipWidth: 20,
      fillColor: _fingerColor(2),
    );
    drawFinger(
      centerX: 128,
      baseY: fingerBaseY,
      totalHeight: 129,
      baseWidth: 30,
      tipWidth: 23,
      fillColor: _fingerColor(3),
    );
    drawFinger(
      centerX: 157,
      baseY: fingerBaseY,
      totalHeight: 96,
      baseWidth: 28,
      tipWidth: 20,
      fillColor: _fingerColor(4),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HandPainter oldDelegate) {
    if (oldDelegate.imuRoll != imuRoll || oldDelegate.bendValues.length != bendValues.length) {
      return true;
    }
    for (var i = 0; i < bendValues.length; i++) {
      if (oldDelegate.bendValues[i] != bendValues[i]) return true;
    }
    return false;
  }
}
