import 'package:flutter/material.dart';

import '../theme/helping_hand_theme.dart';

/// A text wordmark: bundled display type, not an image logo.
class HelpingHandWordmark extends StatelessWidget {
  const HelpingHandWordmark({
    super.key,
    this.compact = false,
    this.centered = true,
    this.singleLine = false,
  });
  final bool compact;
  final bool centered;
  final bool singleLine;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Helping Hand',
      header: true,
      child: ExcludeSemantics(
        child: Align(
          alignment: centered ? Alignment.center : Alignment.centerLeft,
          // Brand lettering fits its bounds; all form copy retains system scaling.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: centered ? Alignment.center : Alignment.centerLeft,
            child: Text(
              singleLine ? 'Helping Hand' : 'Helping\nHand',
              maxLines: singleLine ? 1 : 2,
              textAlign: centered ? TextAlign.center : TextAlign.left,
              style: TextStyle(
                fontFamily: 'HelpingHandWordmark',
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                fontSize: singleLine ? 36 : (compact ? 48 : 64),
                height: 1.02,
                letterSpacing: -2,
                color: HelpingHandColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared static brand accent, excluded from assistive-technology output.
class HelpingHandBrandTrail extends StatelessWidget {
  const HelpingHandBrandTrail({super.key});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: 96,
      height: 16,
      child: CustomPaint(painter: _BrandTrailPainter()),
    ),
  );
}

class _BrandTrailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = HelpingHandColors.primary
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()
        ..moveTo(2, 8)
        ..cubicTo(24, 1, 50, 15, 80, 6),
      stroke,
    );
    canvas.drawCircle(
      const Offset(90, 6),
      5,
      Paint()..color = HelpingHandColors.accent,
    );
  }

  @override
  bool shouldRepaint(covariant _BrandTrailPainter oldDelegate) => false;
}
