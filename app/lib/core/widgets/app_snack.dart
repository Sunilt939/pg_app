import 'package:flutter/material.dart';
import '../theme/tokens.dart';

abstract final class AppSnack {
  static void show(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    final hasAction = actionLabel != null && actionLabel.isNotEmpty;

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.button,
        ),
        margin: const EdgeInsets.all(AppSpace.x16),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        duration: Duration(seconds: hasAction ? 4 : 3),
        content: Row(
          children: [
            Expanded(
              child: Text(
                message,
                style: AppText.secondary.copyWith(color: AppColors.surface),
              ),
            ),
            if (hasAction) ...[
              const SizedBox(width: AppSpace.x12),
              GestureDetector(
                onTap: () {
                  messenger.hideCurrentSnackBar();
                  onAction?.call();
                },
                child: Text(
                  actionLabel,
                  style: AppText.buttonSmall.copyWith(color: AppColors.snackAction),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

