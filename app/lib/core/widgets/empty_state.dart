import 'package:flutter/widgets.dart';
import '../theme/tokens.dart';
import 'app_button.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? customAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    this.customAction,
  });

  @override
  Widget build(BuildContext context) {
    Widget? actionWidget = customAction;
    if (actionWidget == null && actionLabel != null && onAction != null) {
      actionWidget = ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 160),
        child: AppButton.primary(
          label: actionLabel!,
          onPressed: onAction,
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpace.x32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: AppSize.iconEmpty,
              color: AppColors.muted,
            ),
            const SizedBox(height: AppSpace.x16),
            Text(
              title,
              style: AppText.heading,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpace.x8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(
                body,
                style: AppText.secondary,
                textAlign: TextAlign.center,
              ),
            ),
            if (actionWidget != null) ...[
              const SizedBox(height: AppSpace.x24),
              actionWidget,
            ],
          ],
        ),
      ),
    );
  }
}

