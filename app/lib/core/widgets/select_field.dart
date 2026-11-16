import 'package:flutter/material.dart';
import '../theme/app_icons.dart';
import '../theme/tokens.dart';
import 'app_text_field.dart';

class SelectField extends StatelessWidget {
  final String? label;
  final String? value;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final bool enabled;
  final VoidCallback? onTap;

  const SelectField({
    super.key,
    this.label,
    this.value,
    this.hint,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: value ?? '');

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
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
            AppIcons.chevronDown,
            size: 20,
            color: AppColors.muted,
          ),
        ),
      ),
    );
  }
}

