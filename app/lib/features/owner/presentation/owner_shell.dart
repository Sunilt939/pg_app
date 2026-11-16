import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_bottom_nav.dart';

class OwnerShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const OwnerShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.ground,
      body: navigationShell,
      bottomNavigationBar: AppBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        items: [
          AppBottomNavItem(
            icon: AppIcons.home,
            activeIcon: AppIcons.homeFill,
            label: l10n.navHome,
          ),
          AppBottomNavItem(
            icon: AppIcons.guests,
            activeIcon: AppIcons.guestsFill,
            label: l10n.navGuests,
          ),
          AppBottomNavItem(
            icon: AppIcons.payments,
            activeIcon: AppIcons.paymentsFill,
            label: l10n.navPayments,
          ),
          AppBottomNavItem(
            icon: AppIcons.more,
            activeIcon: AppIcons.moreFill,
            label: l10n.navMore,
          ),
        ],
      ),
    );
  }
}

