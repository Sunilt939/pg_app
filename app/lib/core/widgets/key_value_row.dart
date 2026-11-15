import 'package:flutter/widgets.dart';
import '../theme/app_icons.dart';
import '../theme/tokens.dart';

class KeyValueRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isReadOnly;
  final bool showDivider;
  final Widget? customValueWidget;

  const KeyValueRow({
    super.key,
    required this.label,
    required this.value,
    this.isReadOnly = false,
    this.showDivider = true,
    this.customValueWidget,
  });

  @override
  Widget build(BuildContext context) {
    final rowContent = Container(
      constraints: const BoxConstraints(minHeight: AppSize.button),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.x16,
        vertical: AppSpace.x12,
      ),
      color: AppColors.surface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
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
                  child: customValueWidget ??
                      Text(
                        value,
                        style: AppText.body,
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                ),
                if (isReadOnly) ...[
                  const SizedBox(width: AppSpace.x4),
                  const Icon(
                    AppIcons.lock,
                    size: 16,
                    color: AppColors.muted,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (!showDivider) {
      return rowContent;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        rowContent,
        Container(
          margin: const EdgeInsets.only(left: AppSpace.x16),
          height: AppSize.hairline,
          color: AppColors.hairline,
        ),
      ],
    );
  }
}

