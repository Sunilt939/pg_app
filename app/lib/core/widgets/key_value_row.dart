import 'package:flutter/widgets.dart';
import '../theme/app_icons.dart';
import '../theme/tokens.dart';

class KeyValueRow extends StatefulWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isReadOnly;
  final bool showDivider;
  final Widget? customValueWidget;
  final Widget? trailing;
  final VoidCallback? onTap;

  const KeyValueRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.isReadOnly = false,
    this.showDivider = true,
    this.customValueWidget,
    this.trailing,
    this.onTap,
  });

  @override
  State<KeyValueRow> createState() => _KeyValueRowState();
}

class _KeyValueRowState extends State<KeyValueRow> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final valueStyle = (AppText.body).copyWith(color: widget.valueColor);

    final rowContent = Container(
      constraints: const BoxConstraints(minHeight: AppSize.button),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.x16,
        vertical: AppSpace.x12,
      ),
      color: _isPressed ? AppColors.petrolTint : AppColors.surface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              widget.label,
              style: AppText.secondary,
            ),
          ),
          const SizedBox(width: AppSpace.x12),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: widget.customValueWidget ??
                      Text(
                        widget.value,
                        style: valueStyle,
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                ),
                if (widget.isReadOnly) ...[
                  const SizedBox(width: AppSpace.x4),
                  const Icon(
                    AppIcons.lock,
                    size: 16,
                    color: AppColors.muted,
                  ),
                ],
                if (widget.trailing != null) ...[
                  const SizedBox(width: AppSpace.x4),
                  widget.trailing!,
                ],
              ],
            ),
          ),
        ],
      ),
    );

    Widget container = rowContent;
    if (widget.onTap != null) {
      container = GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: container,
      );
    }

    if (!widget.showDivider) {
      return container;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        container,
        Container(
          margin: const EdgeInsets.only(left: AppSpace.x16),
          height: AppSize.hairline,
          color: AppColors.hairline,
        ),
      ],
    );
  }
}

