import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class AppBottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int? badgeCount;

  const AppBottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount,
  });
}

class AppBottomNav extends StatelessWidget {
  final List<AppBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      height: 64 + bottomInset,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.hairline,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isActive = index == currentIndex;

          final badgeText = (item.badgeCount ?? 0) > 99
              ? '99+'
              : '${item.badgeCount}';

          return Expanded(
            child: InkWell(
              onTap: () => onTap(index),
              splashColor: AppColors.transparent,
              highlightColor: AppColors.petrolTint,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  // Active indicator bar
                  if (isActive)
                    Container(
                      width: 32,
                      height: 2,
                      decoration: const BoxDecoration(
                        color: AppColors.petrol,
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(1),
                        ),
                      ),
                    ),
                  // Icon + Label
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              isActive ? item.activeIcon : item.icon,
                              size: 24,
                              color: isActive ? AppColors.petrol : AppColors.muted,
                            ),
                            if (item.badgeCount != null && item.badgeCount! > 0)
                              Positioned(
                                top: -4,
                                right: -8,
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.petrol,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    badgeText,
                                    style: AppText.caption.copyWith(
                                      color: AppColors.surface,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: isActive
                              ? AppText.captionBold.copyWith(color: AppColors.petrol)
                              : AppText.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

