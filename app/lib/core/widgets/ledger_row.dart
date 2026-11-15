import 'package:flutter/widgets.dart';
import '../theme/tokens.dart';
import 'money.dart';
import 'status_chip.dart';

class LedgerRow extends StatefulWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final int? paise;
  final StatusChipKind? statusKind;
  final String? statusLabel;
  final List<Widget>? inlineActions;
  final VoidCallback? onTap;
  final bool showDivider;

  const LedgerRow({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.paise,
    this.statusKind,
    this.statusLabel,
    this.inlineActions,
    this.onTap,
    this.showDivider = true,
  });

  @override
  State<LedgerRow> createState() => _LedgerRowState();
}

class _LedgerRowState extends State<LedgerRow> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final hasLeading = widget.leading != null;
    final dividerIndent = hasLeading ? (AppSpace.x16 + AppSize.tile + AppSpace.x12) : AppSpace.x16;

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
                const SizedBox(width: AppSpace.x12),
              ],
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: AppText.bodyMedium,
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
              ],
            ],
          ),
          if (widget.inlineActions != null && widget.inlineActions!.isNotEmpty) ...[
            const SizedBox(height: AppSpace.x4),
            Padding(
              padding: EdgeInsets.only(left: hasLeading ? (AppSize.tile + AppSpace.x12) : 0),
              child: Row(
                children: [
                  for (int i = 0; i < widget.inlineActions!.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpace.x16),
                    widget.inlineActions![i],
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );

    Widget container = Container(
      constraints: const BoxConstraints(minHeight: AppSize.rowMin),
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

