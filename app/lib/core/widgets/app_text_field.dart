import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/tokens.dart';

class AppTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool enabled;
  final bool readOnly;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final Widget? prefix;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final List<TextInputFormatter>? inputFormatters;
  final bool autofocus;

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.focusNode,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.prefix,
    this.suffix,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.inputFormatters,
    this.autofocus = false,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late FocusNode _focusNode;
  bool _isSelfFocusNode = false;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _isSelfFocusNode = true;
    }
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      if (_isSelfFocusNode) {
        _focusNode.removeListener(_onFocusChange);
        _focusNode.dispose();
        _isSelfFocusNode = false;
      }
      if (widget.focusNode != null) {
        _focusNode = widget.focusNode!;
      } else {
        _focusNode = FocusNode();
        _isSelfFocusNode = true;
      }
      _focusNode.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (_isSelfFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final isFocused = _focusNode.hasFocus;
    final isMultiLine = widget.maxLines == null || widget.maxLines! > 1;

    Color borderColor;
    double borderWidth;
    Color backgroundColor;
    Color textColor;

    if (!widget.enabled) {
      borderColor = AppColors.hairline;
      borderWidth = 1.0;
      backgroundColor = AppColors.ground;
      textColor = AppColors.muted;
    } else if (hasError) {
      borderColor = AppColors.overdueFg;
      borderWidth = 2.0;
      backgroundColor = AppColors.surface;
      textColor = AppColors.ink;
    } else if (isFocused) {
      borderColor = AppColors.petrol;
      borderWidth = 2.0;
      backgroundColor = AppColors.surface;
      textColor = AppColors.ink;
    } else {
      borderColor = AppColors.outline;
      borderWidth = 1.0;
      backgroundColor = AppColors.surface;
      textColor = AppColors.ink;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null && widget.label!.isNotEmpty) ...[
          Text(
            widget.label!,
            style: AppText.label,
          ),
          const SizedBox(height: 6),
        ],
        Container(
          constraints: BoxConstraints(
            minHeight: isMultiLine ? 96 : 52,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: AppRadius.button,
            border: Border.all(
              color: borderColor,
              width: borderWidth,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: isMultiLine ? Alignment.topLeft : Alignment.centerLeft,
          child: Row(
            crossAxisAlignment: isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              if (widget.prefix != null) ...[
                Padding(
                  padding: EdgeInsets.only(top: isMultiLine ? 14 : 0),
                  child: widget.prefix!,
                ),
              ],
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  readOnly: widget.readOnly,
                  obscureText: widget.obscureText,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  maxLines: widget.maxLines,
                  minLines: widget.minLines,
                  maxLength: widget.maxLength,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  onTap: widget.onTap,
                  inputFormatters: widget.inputFormatters,
                  autofocus: widget.autofocus,
                  cursorColor: AppColors.petrol,
                  style: AppText.body.copyWith(color: textColor),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: isMultiLine ? 14 : 15,
                    ),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    counterText: '',
                    hintText: widget.hint,
                    hintStyle: AppText.body.copyWith(color: AppColors.muted),
                  ),
                ),
              ),
              if (widget.suffix != null) ...[
                Padding(
                  padding: EdgeInsets.only(top: isMultiLine ? 14 : 0),
                  child: widget.suffix!,
                ),
              ],
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpace.x4),
          Semantics(
            liveRegion: true,
            child: Text(
              widget.errorText!,
              style: AppText.secondary.copyWith(color: AppColors.overdueFg),
            ),
          ),
        ] else if (widget.helperText != null && widget.helperText!.isNotEmpty) ...[
          const SizedBox(height: AppSpace.x4),
          Text(
            widget.helperText!,
            style: AppText.secondary,
          ),
        ],
      ],
    );
  }
}

