import 'package:flutter/material.dart';
import '../format/dates.dart';
import '../theme/app_icons.dart';
import '../theme/tokens.dart';
import 'app_text_field.dart';

class DateField extends StatelessWidget {
  final String? label;
  final DateTime? value;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final bool enabled;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final ValueChanged<DateTime>? onChanged;

  const DateField({
    super.key,
    this.label,
    this.value,
    this.hint = 'Select date',
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.firstDate,
    this.lastDate,
    this.onChanged,
  });

  Future<void> _handleTap(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: firstDate ?? DateTime(2000),
      lastDate: lastDate ?? DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.petrol,
              onPrimary: AppColors.surface,
              surface: AppColors.surface,
              onSurface: AppColors.ink,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null && onChanged != null) {
      onChanged!(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatted = value != null ? formatDate(value!) : '';
    final controller = TextEditingController(text: formatted);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? () => _handleTap(context) : null,
      child: IgnorePointer(
        child: AppTextField(
          label: label,
          hint: hint,
          helperText: helperText,
          errorText: errorText,
          controller: controller,
          enabled: enabled,
          readOnly: true,
          suffix: const Icon(
            AppIcons.calendar,
            size: 20,
            color: AppColors.muted,
          ),
        ),
      ),
    );
  }
}

