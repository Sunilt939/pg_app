import 'package:flutter/widgets.dart';
import '../theme/tokens.dart';

enum StatusChipKind {
  paid,
  pending,
  overdue,
  due,
}

class StatusChip extends StatelessWidget {
  final StatusChipKind kind;
  final String? label;

  const StatusChip({
    super.key,
    required this.kind,
    this.label,
  });

  const StatusChip.paid({super.key, this.label}) : kind = StatusChipKind.paid;
  const StatusChip.pending({super.key, this.label}) : kind = StatusChipKind.pending;
  const StatusChip.overdue({super.key, this.label}) : kind = StatusChipKind.overdue;
  const StatusChip.due({super.key, this.label}) : kind = StatusChipKind.due;

  String _defaultLabel() {
    switch (kind) {
      case StatusChipKind.paid:
        return 'Paid';
      case StatusChipKind.pending:
        return 'Pending';
      case StatusChipKind.overdue:
        return 'Overdue';
      case StatusChipKind.due:
        return 'Due';
    }
  }

  Color _fgColor() {
    switch (kind) {
      case StatusChipKind.paid:
        return AppColors.paidFg;
      case StatusChipKind.pending:
        return AppColors.pendingFg;
      case StatusChipKind.overdue:
        return AppColors.overdueFg;
      case StatusChipKind.due:
        return AppColors.muted;
    }
  }

  Color _bgColor() {
    switch (kind) {
      case StatusChipKind.paid:
        return AppColors.paidBg;
      case StatusChipKind.pending:
        return AppColors.pendingBg;
      case StatusChipKind.overdue:
        return AppColors.overdueBg;
      case StatusChipKind.due:
        return AppColors.surface;
    }
  }

  BoxBorder? _border() {
    if (kind == StatusChipKind.due) {
      return Border.all(
        color: AppColors.hairline,
        width: AppSize.hairline,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final fg = _fgColor();
    final bg = _bgColor();
    final border = _border();
    final text = label ?? _defaultLabel();

    return Container(
      constraints: const BoxConstraints(minHeight: AppSize.chipMin),
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.x8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.chip,
        border: border,
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: AppText.captionBold.copyWith(color: fg),
      ),
    );
  }
}

