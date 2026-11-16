import 'package:flutter/material.dart';
import '../theme/app_icons.dart';
import '../theme/tokens.dart';

class PgSwitcherTitle extends StatelessWidget {
  final String pgName;
  final VoidCallback? onTap;

  const PgSwitcherTitle({
    super.key,
    required this.pgName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: AppColors.transparent,
      highlightColor: AppColors.petrolTint,
      borderRadius: AppRadius.button,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.x4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                pgName,
                style: AppText.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpace.x4),
            const Icon(
              AppIcons.chevronDown,
              size: 20,
              color: AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}

