import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class UnderlineTabItem {
  final String label;
  final int? count;

  const UnderlineTabItem({
    required this.label,
    this.count,
  });
}

class UnderlineTabs extends StatelessWidget {
  final List<UnderlineTabItem> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const UnderlineTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final animDuration = disableAnimations ? Duration.zero : AppMotion.base;

    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.hairline,
            width: 1.0,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: List.generate(tabs.length, (index) {
            final tab = tabs[index];
            final isSelected = index == selectedIndex;

            return InkWell(
              onTap: () => onTabSelected(index),
              splashColor: AppColors.transparent,
              highlightColor: AppColors.petrolTint,
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tab.label,
                            style: isSelected
                                ? AppText.buttonSmall.copyWith(color: AppColors.ink)
                                : AppText.buttonSmall.copyWith(color: AppColors.muted),
                          ),
                          if (tab.count != null) ...[
                            const SizedBox(width: AppSpace.x4),
                            Text(
                              '${tab.count}',
                              style: AppText.caption.copyWith(
                                color: isSelected ? AppColors.ink : AppColors.muted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: AnimatedContainer(
                        duration: animDuration,
                        height: 2.0,
                        color: isSelected ? AppColors.petrol : AppColors.transparent,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

