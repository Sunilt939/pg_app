import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/format/dates.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/ledger_sheet.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../domain/notification_item.dart';
import '../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(notificationsProvider.notifier).loadMore();
    }
  }

  void _handleNotificationTap(BuildContext context, NotificationItem item) {
    switch (item.kind) {
      case 'rent_reminder':
        context.go(RoutePaths.guestHome);
        break;
      case 'payment_reported':
        if (item.stayId != null && item.stayId!.isNotEmpty) {
          context.push('/owner/guests/${item.stayId}');
        }
        break;
      case 'payment_confirmed':
      case 'payment_rejected':
        context.push(RoutePaths.guestHistory);
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.ground,
      appBar: AppTopBar.back(
        title: l10n.notificationsTitle,
      ),
      body: RefreshIndicator(
        color: AppColors.petrol,
        onRefresh: () => ref.read(notificationsProvider.notifier).loadInitial(),
        child: _buildBody(context, l10n, state),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    NotificationsState state,
  ) {
    if (state.isLoading && state.items.isEmpty) {
      return _buildLoading();
    }

    if (state.error != null && state.items.isEmpty) {
      return _buildError(l10n);
    }

    if (state.items.isEmpty) {
      return _buildEmpty(l10n);
    }

    return ListView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: AppSpace.x12, bottom: AppSpace.x24),
      children: [
        LedgerSheet(
          children: [
            for (int i = 0; i < state.items.length; i++) ...[
              if (i > 0)
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.hairline,
                ),
              _buildNotificationRow(context, state.items[i]),
            ],
          ],
        ),
        if (state.isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpace.x16),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.petrol,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNotificationRow(BuildContext context, NotificationItem item) {
    return InkWell(
      onTap: () async {
        await ref.read(notificationsProvider.notifier).markAsRead(item.id);
        if (!context.mounted) return;
        _handleNotificationTap(context, item);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.x16,
          vertical: AppSpace.x12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: item.isUnread
                  ? Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.petrol,
                        shape: BoxShape.circle,
                      ),
                    )
                  : const SizedBox(width: 8, height: 8),
            ),
            const SizedBox(width: AppSpace.x8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: item.isUnread ? AppText.heading : AppText.body,
                        ),
                      ),
                      const SizedBox(width: AppSpace.x8),
                      Text(
                        DateFormat.formatRelativeTime(
                          item.createdAt,
                          convertToIst: true,
                        ),
                        style: AppText.caption,
                      ),
                    ],
                  ),
                  if (item.body.isNotEmpty) ...[
                    const SizedBox(height: AppSpace.x4),
                    Text(
                      item.body,
                      style: AppText.secondary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: AppSpace.x12),
      children: const [
        LedgerSheet(
          children: [
            Padding(
              padding: EdgeInsets.all(AppSpace.x16),
              child: SkeletonBlock(height: 56),
            ),
            Divider(height: 1, thickness: 1, color: AppColors.hairline),
            Padding(
              padding: EdgeInsets.all(AppSpace.x16),
              child: SkeletonBlock(height: 56),
            ),
            Divider(height: 1, thickness: 1, color: AppColors.hairline),
            Padding(
              padding: EdgeInsets.all(AppSpace.x16),
              child: SkeletonBlock(height: 56),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmpty(AppLocalizations l10n) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.7,
          child: EmptyState(
            icon: AppIcons.bell,
            title: l10n.notificationsEmptyTitle,
            body: l10n.notificationsEmptyBody,
          ),
        ),
      ],
    );
  }

  Widget _buildError(AppLocalizations l10n) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.7,
          child: ErrorState(
            title: l10n.errorGeneric,
            message: l10n.errorNetwork,
            onRetry: () => ref.read(notificationsProvider.notifier).loadInitial(),
          ),
        ),
      ],
    );
  }
}
