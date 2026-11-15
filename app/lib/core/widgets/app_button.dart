import 'package:flutter/material.dart' show CircularProgressIndicator, AlwaysStoppedAnimation;
import 'package:flutter/widgets.dart';
import '../theme/tokens.dart';

enum _AppButtonVariant {
  primary,
  secondary,
  text,
  destructive,
}

class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final bool expand;
  final _AppButtonVariant _variant;

  const AppButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.expand = false,
  }) : _variant = _AppButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.expand = false,
  }) : _variant = _AppButtonVariant.secondary;

  const AppButton.text({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.expand = false,
  }) : _variant = _AppButtonVariant.text;

  const AppButton.destructive({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.expand = false,
  }) : _variant = _AppButtonVariant.destructive;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;

  bool get _isEnabled => widget.onPressed != null && !widget.loading;

  double get _height =>
      widget._variant == _AppButtonVariant.text ? AppSize.tile : AppSize.button;

  TextStyle get _textStyle =>
      widget._variant == _AppButtonVariant.text ? AppText.buttonSmall : AppText.button;

  Color _bgColor() {
    if (!_isEnabled) {
      if (widget._variant == _AppButtonVariant.text) {
        return AppColors.transparent;
      }
      return AppColors.disabledBg;
    }
    if (_isPressed) {
      switch (widget._variant) {
        case _AppButtonVariant.primary:
          return AppColors.petrolPressed;
        case _AppButtonVariant.secondary:
        case _AppButtonVariant.text:
          return AppColors.petrolTint;
        case _AppButtonVariant.destructive:
          return AppColors.overduePressed;
      }
    }
    switch (widget._variant) {
      case _AppButtonVariant.primary:
        return AppColors.petrol;
      case _AppButtonVariant.secondary:
        return AppColors.surface;
      case _AppButtonVariant.text:
        return AppColors.transparent;
      case _AppButtonVariant.destructive:
        return AppColors.overdueFg;
    }
  }

  Color _fgColor() {
    if (!_isEnabled) {
      return AppColors.muted;
    }
    switch (widget._variant) {
      case _AppButtonVariant.primary:
      case _AppButtonVariant.destructive:
        return AppColors.surface;
      case _AppButtonVariant.secondary:
      case _AppButtonVariant.text:
        return AppColors.petrol;
    }
  }

  BoxBorder? _border() {
    if (widget._variant == _AppButtonVariant.secondary && _isEnabled) {
      return Border.all(
        color: AppColors.petrol,
        width: AppSize.hairline,
      );
    }
    return null;
  }

  EdgeInsetsGeometry _padding() {
    if (widget._variant == _AppButtonVariant.text) {
      return const EdgeInsets.symmetric(horizontal: AppSpace.x12);
    }
    return const EdgeInsets.symmetric(horizontal: AppSpace.x16);
  }

  @override
  Widget build(BuildContext context) {
    final fg = _fgColor();
    final bg = _bgColor();
    final border = _border();
    final padding = _padding();

    Widget content;
    if (widget.loading) {
      content = SizedBox(
        width: AppSize.iconSmall,
        height: AppSize.iconSmall,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(fg),
        ),
      );
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            Icon(
              widget.icon,
              size: AppSize.iconSmall,
              color: fg,
            ),
            const SizedBox(width: AppSpace.x8),
          ],
          Text(
            widget.label,
            style: _textStyle.copyWith(color: fg),
          ),
        ],
      );
    }

    Widget button = Container(
      height: _height,
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.control,
        border: border,
      ),
      alignment: Alignment.center,
      child: content,
    );

    if (widget.expand) {
      button = SizedBox(width: double.infinity, child: button);
    }

    return GestureDetector(
      onTapDown: _isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: _isEnabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: _isEnabled ? () => setState(() => _isPressed = false) : null,
      onTap: _isEnabled ? widget.onPressed : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: AppMotion.fast,
        curve: AppMotion.curve,
        child: button,
      ),
    );
  }
}
