import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/tokens.dart';

enum StampKind {
  paid,
  pending,
  overdue,
}

class Stamp extends StatelessWidget {
  final String label;
  final StampKind kind;

  const Stamp({
    super.key,
    required this.label,
    required this.kind,
  });

  const Stamp.paid({
    super.key,
    this.label = 'Paid',
  }) : kind = StampKind.paid;

  const Stamp.pending({
    super.key,
    this.label = 'Pending',
  }) : kind = StampKind.pending;

  const Stamp.overdue({
    super.key,
    this.label = 'Overdue',
  }) : kind = StampKind.overdue;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (kind) {
      case StampKind.paid:
        color = AppColors.paidFg;
        break;
      case StampKind.pending:
        color = AppColors.pendingFg;
        break;
      case StampKind.overdue:
        color = AppColors.overdueFg;
        break;
    }

    // -6 degrees in radians
    const angle = -6 * math.pi / 180;

    return Transform.rotate(
      angle: angle,
      child: Opacity(
        opacity: 0.90,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: color,
              width: 2.0,
            ),
          ),
          child: Text(
            label,
            style: AppText.heading.copyWith(color: color),
          ),
        ),
      ),
    );
  }
}

