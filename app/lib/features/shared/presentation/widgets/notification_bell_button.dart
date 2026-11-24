import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/tokens.dart';
import '../providers/notifications_provider.dart';

class NotificationBellButton extends ConsumerWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasUnreadAsync = ref.watch(hasUnreadNotificationsProvider);
    final hasUnread = hasUnreadAsync.valueOrNull ?? false;

    return Semantics(
      button: true,
      label: 'Notifications',
      child: InkWell(
        onTap: () => context.push(RoutePaths.notifications),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                AppIcons.bell,
                size: 24,
                color: AppColors.ink,
              ),
              if (hasUnread)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.petrol,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

