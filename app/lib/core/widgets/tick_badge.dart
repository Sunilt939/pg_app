import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class TickBadge extends StatefulWidget {
  final double size;

  const TickBadge({
    super.key,
    this.size = 64.0,
  });

  @override
  State<TickBadge> createState() => _TickBadgeState();
}

class _TickBadgeState extends State<TickBadge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.tick,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final disableMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (disableMotion) {
        _controller.value = 1.0;
      } else {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: const BoxDecoration(
        color: AppColors.paidBg,
        shape: BoxShape.circle,
      ),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _TickPainter(progress: _animation.value),
          );
        },
      ),
    );
  }
}

class _TickPainter extends CustomPainter {
  final double progress;

  _TickPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = AppColors.paidFg
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final scale = size.width / 64.0;
    final path = Path()
      ..moveTo(20.0 * scale, 32.0 * scale)
      ..lineTo(28.0 * scale, 41.0 * scale)
      ..lineTo(44.0 * scale, 23.0 * scale);

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final metric = metrics.first;
    final extract = metric.extractPath(0.0, metric.length * progress);
    canvas.drawPath(extract, paint);
  }

  @override
  bool shouldRepaint(covariant _TickPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

