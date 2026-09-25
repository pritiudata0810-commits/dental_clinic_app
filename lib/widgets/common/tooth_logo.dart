import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// A modern, professional vector Tooth Logo for SmileCare.
/// Designed to replace the heart emblem from Reference Image 1 with
/// a clean dental healthcare symbol featuring dual contoured geometry.
class ToothLogo extends StatelessWidget {
  final double size;
  final Color? primaryColor;
  final Color? secondaryColor;

  const ToothLogo({
    super.key,
    this.size = 80,
    this.primaryColor,
    this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final pColor = primaryColor ?? AppColors.primary;
    final sColor = secondaryColor ?? const Color(0xFF818CF8);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ToothPainter(
          primaryColor: pColor,
          secondaryColor: sColor,
        ),
      ),
    );
  }
}

class _ToothPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;

  _ToothPainter({
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background shadow layer (soft contour)
    final shadowPaint = Paint()
      ..color = secondaryColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.06
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final shadowPath = Path();
    _drawToothPath(shadowPath, w * 0.95, h * 0.95, offsetX: w * 0.04, offsetY: h * 0.03);
    canvas.drawPath(shadowPath, shadowPaint);

    // Primary gradient tooth
    final rect = Rect.fromLTWH(0, 0, w, h);
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primaryColor,
          secondaryColor,
        ],
      ).createShader(rect)
      ..style = PaintingStyle.fill;

    final mainPath = Path();
    _drawToothPath(mainPath, w * 0.88, h * 0.88, offsetX: w * 0.04, offsetY: w * 0.04);
    canvas.drawPath(mainPath, fillPaint);

    // Highlight / Shine curve on crown
    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045
      ..strokeCap = StrokeCap.round;

    final shinePath = Path();
    shinePath.moveTo(w * 0.28, h * 0.26);
    shinePath.quadraticBezierTo(w * 0.45, h * 0.18, w * 0.65, h * 0.24);
    canvas.drawPath(shinePath, shinePaint);
  }

  void _drawToothPath(Path path, double w, double h, {double offsetX = 0, double offsetY = 0}) {
    // Elegant anatomical molar crown with smooth dual roots
    path.moveTo(offsetX + w * 0.22, offsetY + h * 0.22);

    // Top crown left bump
    path.cubicTo(
      offsetX + w * 0.25, offsetY + h * 0.06,
      offsetX + w * 0.42, offsetY + h * 0.06,
      offsetX + w * 0.50, offsetY + h * 0.16,
    );

    // Top crown right bump
    path.cubicTo(
      offsetX + w * 0.58, offsetY + h * 0.06,
      offsetX + w * 0.75, offsetY + h * 0.06,
      offsetX + w * 0.78, offsetY + h * 0.22,
    );

    // Right outer contour down to right root
    path.cubicTo(
      offsetX + w * 0.86, offsetY + h * 0.42,
      offsetX + w * 0.84, offsetY + h * 0.70,
      offsetX + w * 0.72, offsetY + h * 0.94,
    );

    // Right root tip rounded curve
    path.quadraticBezierTo(
      offsetX + w * 0.66, offsetY + h * 0.98,
      offsetX + w * 0.60, offsetY + h * 0.86,
    );

    // Inner root bifurcation curve
    path.cubicTo(
      offsetX + w * 0.56, offsetY + h * 0.64,
      offsetX + w * 0.44, offsetY + h * 0.64,
      offsetX + w * 0.40, offsetY + h * 0.86,
    );

    // Left root tip rounded curve
    path.quadraticBezierTo(
      offsetX + w * 0.34, offsetY + h * 0.98,
      offsetX + w * 0.28, offsetY + h * 0.94,
    );

    // Left outer contour back to top
    path.cubicTo(
      offsetX + w * 0.16, offsetY + h * 0.70,
      offsetX + w * 0.14, offsetY + h * 0.42,
      offsetX + w * 0.22, offsetY + h * 0.22,
    );

    path.close();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
