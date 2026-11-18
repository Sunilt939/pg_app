import 'package:flutter/widgets.dart';
import '../theme/tokens.dart';
import 'money.dart';
import 'status_chip.dart';

class LedgerRow extends StatefulWidget {
  final Widget? leading;
  final String title;
  final TextStyle? titleStyle;
  final Color? titleColor;
  final String? subtitle;
  final int? paise;
  final StatusChipKind? statusKind;
  final String? statusLabel;
  final Widget? trailing;
  final List<Widget>? inlineActions;
  final VoidCallback? onTap;
  final bool showDivider;
  final double? minHeight;
  final double? leadingGap;
  final double? dividerIndent;

  const LedgerRow({
    super.key,
    this.leading,
    required this.title,
    this.titleStyle,
    this.titleColor,
    this.subtitle,
    this.paise,
    this.statusKind,
    this.statusLabel,
    this.trailing,
    this.inlineActions,
    this.onTap,
    this.showDivider = true,
    this.minHeight,
    this.leadingGap,
    this.dividerIndent,
  });

  @override
  State<LedgerRow> createState() => _LedgerRowState();
}

class _LedgerRowState extends State<LedgerRow> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final hasLeading = widget.leading != null;
    final effectiveTitleStyle = (widget.titleStyle ?? AppText.bodyMedium).copyWith(
      color: widget.titleColor,
    );
    final gap = widget.leadingGap ?? AppSpace.x12;
    final defaultDividerIndent =
        hasLeading ? (AppSpace.x16 + AppSize.tile + gap) : AppSpace.x16;
    final dividerIndent = widget.dividerIndent ?? defaultDividerIndent;

    final rowContent = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.x16,
        vertical: AppSpace.x12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.leading != null) ...[
                widget.leading!,
                SizedBox(width: gap),
              ],
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: effectiveTitleStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle!,
                        style: AppText.secondary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.paise != null || widget.statusKind != null) ...[
                const SizedBox(width: AppSpace.x12),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (widget.paise != null)
                      Money(
                        paise: widget.paise!,
                        style: AppText.heading,
                      ),
                    if (widget.statusKind != null) ...[
                      const SizedBox(height: AppSpace.x4),
                      StatusChip(
                        kind: widget.statusKind!,
                        label: widget.statusLabel,
                      ),
                    ],
                  ],
                ),
              ] else if (widget.trailing != null) ...[
                const SizedBox(width: AppSpace.x12),
                widget.trailing!,
              ],
            ],
          ),
          if (widget.inlineActions != null && widget.inlineActions!.isNotEmpty) ...[
            const SizedBox(height: AppSpace.x4),
            Padding(
              padding: EdgeInsets.only(left: hasLeading ? (AppSize.tile + gap) : 0),
              child: Transform.translate(
                offset: const Offset(-AppSpace.x12, 0),
                child: Row(
                  children: [
                    for (int i = 0; i < widget.inlineActions!.length; i++) ...[
                      if (i > 0) const SizedBox(width: AppSpace.x16),
                      widget.inlineActions![i],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );

    Widget container = Container(
      constraints: BoxConstraints(minHeight: widget.minHeight ?? AppSize.rowMin),
      color: _isPressed ? AppColors.petrolTint : AppColors.surface,
      child: rowContent,
    );

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
          margin: EdgeInsets.only(left: dividerIndent),
          height: AppSize.hairline,
          color: AppColors.hairline,
        ),
      ],
    );
  }
}

