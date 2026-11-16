import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../format/money.dart';
import '../theme/tokens.dart';
import 'app_text_field.dart';

class MoneyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final truncated = digits.length > 9 ? digits.substring(0, 9) : digits;
    final rupees = int.tryParse(truncated) ?? 0;
    final formatted = formatRupeesWithGrouping(rupees);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class MoneyField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool enabled;
  final bool autofocus;
  final bool isLarge;
  final ValueChanged<int>? onChanged;
  final ValueChanged<int>? onSubmitted;
  final int? initialPaise;

  const MoneyField({
    super.key,
    this.label,
    this.hint = '0',
    this.helperText,
    this.errorText,
    this.controller,
    this.focusNode,
    this.enabled = true,
    this.autofocus = false,
    this.isLarge = false,
    this.onChanged,
    this.onSubmitted,
    this.initialPaise,
  });

  @override
  State<MoneyField> createState() => _MoneyFieldState();
}

class _MoneyFieldState extends State<MoneyField> {
  late TextEditingController _controller;
  bool _isSelfController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController();
      _isSelfController = true;
    }

    if (widget.initialPaise != null && widget.initialPaise! > 0) {
      final rupees = widget.initialPaise! ~/ 100;
      _controller.text = formatRupeesWithGrouping(rupees);
    }
  }

  @override
  void dispose() {
    if (_isSelfController) {
      _controller.dispose();
    }
    super.dispose();
  }

  int _parsePaise(String text) {
    final digits = text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 0;
    final rupees = int.tryParse(digits) ?? 0;
    return rupees * 100;
  }

  @override
  Widget build(BuildContext context) {
    final prefixStyle = widget.isLarge
        ? AppText.scaleRupeeSymbol(AppText.display).copyWith(color: AppColors.muted)
        : AppText.bodyMedium.copyWith(color: AppColors.muted);

    return AppTextField(
      label: widget.label,
      hint: widget.hint,
      helperText: widget.helperText,
      errorText: widget.errorText,
      controller: _controller,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        MoneyInputFormatter(),
      ],
      prefix: Container(
        width: 40,
        alignment: Alignment.centerLeft,
        child: Text(
          '₹',
          style: prefixStyle,
        ),
      ),
      onChanged: (text) {
        if (widget.onChanged != null) {
          widget.onChanged!(_parsePaise(text));
        }
      },
      onSubmitted: (text) {
        if (widget.onSubmitted != null) {
          widget.onSubmitted!(_parsePaise(text));
        }
      },
    );
  }
}

