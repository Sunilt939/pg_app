import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class ReceiptPaper extends StatelessWidget {
  final Widget header;
  final Widget body;
  final Widget? footer;
  final EdgeInsets padding;

  const ReceiptPaper({
    super.key,
    required this.header,
    required this.body,
    this.footer,
    this.padding = const EdgeInsets.all(AppSpace.x16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(
          color: AppColors.hairline,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.12),
            offset: const Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: padding,
            child: header,
          ),
          const _ReceiptDividerWithNotches(),
          Padding(
            padding: padding,
            child: body,
          ),
          if (footer != null) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(
                padding.left,
                0,
                padding.right,
                padding.bottom,
              ),
              child: footer!,
            ),
          ],
        ],
      ),
    );
  }
}

class _ReceiptDividerWithNotches extends StatelessWidget {
  const _ReceiptDividerWithNotches();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 16,
      child: CustomPaint(
        size: Size(double.infinity, 16),
        painter: _ReceiptDividerPainter(),
      ),
    );
  }
}

class _ReceiptDividerPainter extends CustomPainter {
  const _ReceiptDividerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const notchRadius = 8.0;
    const centerY = 8.0;

    final groundPaint = Paint()
      ..color = AppColors.ground
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = AppColors.hairline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Left notch: semicircle into the paper (center at x=0, y=8, radius=8, angles -pi/2 to pi/2)
    final leftRect = Rect.fromCircle(center: const Offset(0, centerY), radius: notchRadius);
    canvas.drawArc(leftRect, -math.pi / 2, math.pi, true, groundPaint);
    canvas.drawArc(leftRect, -math.pi / 2, math.pi, false, borderPaint);

    // Right notch: semicircle into the paper (center at x=size.width, y=8, radius=8, angles pi/2 to 3pi/2)
    final rightRect = Rect.fromCircle(center: Offset(size.width, centerY), radius: notchRadius);
    canvas.drawArc(rightRect, math.pi / 2, math.pi, true, groundPaint);
    canvas.drawArc(rightRect, math.pi / 2, math.pi, false, borderPaint);

    // Dashed line between notches: 6 on, 4 off
    const startX = notchRadius;
    final endX = size.width - notchRadius;
    const dashWidth = 6.0;
    const dashSpace = 4.0;

    var currentX = startX + 2.0;
    while (currentX < endX - 2.0) {
      final drawWidth = math.min(dashWidth, (endX - 2.0) - currentX);
      canvas.drawLine(
        Offset(currentX, centerY),
        Offset(currentX + drawWidth, centerY),
        borderPaint,
      );
      currentX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

