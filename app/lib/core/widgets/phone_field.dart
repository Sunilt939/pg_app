import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/tokens.dart';
import 'app_text_field.dart';

class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Handle +91 or 91 or leading 0 if pasted
    if (digits.length > 10) {
      if (digits.startsWith('91') && digits.length >= 12) {
        digits = digits.substring(digits.length - 10);
      } else if (digits.startsWith('0') && digits.length == 11) {
        digits = digits.substring(1);
      } else {
        digits = digits.substring(digits.length - 10);
      }
    }

    if (digits.length > 10) {
      digits = digits.substring(0, 10);
    }

    final formatted = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 5) {
        formatted.write(' ');
      }
      formatted.write(digits[i]);
    }

    final formattedText = formatted.toString();
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

class PhoneField extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool enabled;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const PhoneField({
    super.key,
    this.label,
    this.hint = '98765 43210',
    this.helperText,
    this.errorText,
    this.controller,
    this.focusNode,
    this.enabled = true,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: label,
      hint: hint,
      helperText: helperText,
      errorText: errorText,
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      autofocus: autofocus,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d\s+\-]')),
        PhoneInputFormatter(),
      ],
      prefix: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            alignment: Alignment.centerLeft,
            child: const Text(
              '+91',
              style: AppText.bodyMedium,
            ),
          ),
          Container(
            width: 1,
            height: 24,
            color: AppColors.hairline,
            margin: const EdgeInsets.only(right: 12),
          ),
        ],
      ),
      onChanged: (text) {
        if (onChanged != null) {
          final digits = text.replaceAll(RegExp(r'\D'), '');
          final e164 = digits.isEmpty ? '' : '+91$digits';
          onChanged!(e164);
        }
      },
      onSubmitted: (text) {
        if (onSubmitted != null) {
          final digits = text.replaceAll(RegExp(r'\D'), '');
          final e164 = digits.isEmpty ? '' : '+91$digits';
          onSubmitted!(e164);
        }
      },
    );
  }
}

