import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_icons.dart';
import '../theme/tokens.dart';

class BedsStepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int>? onChanged;
  final String? fewerLabel;
  final String? moreLabel;

  const BedsStepper({
    super.key,
    required this.value,
    this.min = 1,
    this.max = 12,
    this.onChanged,
    this.fewerLabel,
    this.moreLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canDecrement = value > min && onChanged != null;
    final canIncrement = value < max && onChanged != null;

    final minusTooltip = fewerLabel ?? l10n?.bedsFewer ?? 'Fewer beds';
    final plusTooltip = moreLabel ?? l10n?.bedsMore ?? 'More beds';
    final valueDescription = l10n?.layoutBedsCount(value) ?? '$value beds';

    return SizedBox(
      width: 136,
      height: 44,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _StepperButton(
            icon: AppIcons.minus,
            enabled: canDecrement,
            tooltip: minusTooltip,
            onTap: canDecrement ? () => onChanged?.call(value - 1) : null,
          ),
          Semantics(
            label: valueDescription,
            excludeSemantics: true,
            child: SizedBox(
              width: 48,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: AppText.heading.copyWith(color: AppColors.ink),
              ),
            ),
          ),
          _StepperButton(
            icon: AppIcons.add,
            enabled: canIncrement,
            tooltip: plusTooltip,
            onTap: canIncrement ? () => onChanged?.call(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatefulWidget {
  final IconData icon;
  final bool enabled;
  final String tooltip;
  final VoidCallback? onTap;

  const _StepperButton({
    required this.icon,
    required this.enabled,
    required this.tooltip,
    this.onTap,
  });

  @override
  State<_StepperButton> createState() => _StepperButtonState();
}

class _StepperButtonState extends State<_StepperButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.enabled ? AppColors.outline : AppColors.hairline;
    final iconColor = widget.enabled ? AppColors.petrol : AppColors.muted;
    final backgroundColor = _isPressed && widget.enabled
        ? AppColors.petrolTint
        : AppColors.surface;

    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.enabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: widget.enabled ? () => setState(() => _isPressed = false) : null,
        onTap: widget.onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: AppRadius.button,
                border: Border.all(
                  color: borderColor,
                  width: 1.0,
                ),
              ),
              child: Center(
                child: Icon(
                  widget.icon,
                  size: 20,
                  color: iconColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

