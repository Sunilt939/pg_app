import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/natural_sort.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/ledger_row.dart';
import '../../../../core/widgets/ledger_sheet.dart';
import '../../../../core/widgets/room_tile.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/bed_occupancy.dart';
import '../providers/owner_provider.dart';

class OwnerRoomDetailScreen extends ConsumerWidget {
  final String roomId;

  const OwnerRoomDetailScreen({
    super.key,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final activePg = ref.watch(activePgProvider);
    final role = activePg?.role;
    final isOwnerOrManager = role == 'owner' || role == 'manager';

    final bedsAsync = ref.watch(bedOccupancyProvider);

    return bedsAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.ground,
        appBar: AppTopBar.back(
          title: l10n.roomDefaultTitle,
          onLeadingPressed: () => context.pop(),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.petrol),
        ),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: AppColors.ground,
        appBar: AppTopBar.back(
          title: l10n.roomDefaultTitle,
          onLeadingPressed: () => context.pop(),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.x16),
            child: Text(
              error.toString().replaceFirst('Exception: ', ''),
              style: AppText.secondary.copyWith(color: AppColors.overdueFg),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      data: (allBeds) {
        final roomBeds = allBeds.where((b) => b.roomId == roomId).toList()
          ..sort((a, b) => naturalCompare(a.bedLabel, b.bedLabel));

        final roomNumber = roomBeds.isNotEmpty ? roomBeds.first.roomNumber : '';
        final title = roomNumber.isNotEmpty
            ? l10n.roomPageTitle(roomNumber)
            : l10n.roomDefaultTitle;

        return Scaffold(
          backgroundColor: AppColors.ground,
          appBar: AppTopBar.back(
            title: title,
            onLeadingPressed: () => context.pop(),
          ),
          body: ListView(
            padding: const EdgeInsets.only(
              top: AppSpace.x16,
              bottom: AppSpace.x32,
            ),
            children: [
              LedgerSheet(
                children: [
                  for (int i = 0; i < roomBeds.length; i++)
                    _buildBedRow(
                      context,
                      l10n,
                      roomBeds[i],
                      i < roomBeds.length - 1,
                      isOwnerOrManager,
                      ref,
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBedRow(
    BuildContext context,
    AppLocalizations l10n,
    BedOccupancy bed,
    bool showDivider,
    bool isOwnerOrManager,
    WidgetRef ref,
  ) {
    final isOccupied = bed.isOccupied;

    String title;
    TextStyle titleStyle;
    String? subtitle;

    if (isOccupied) {
      if (bed.occupantName != null && bed.occupantName!.trim().isNotEmpty) {
        title = bed.occupantName!.trim();
        subtitle = bed.occupantPhone;
      } else {
        title = bed.occupantPhone ?? l10n.bedFree;
        subtitle = null;
      }
      titleStyle = AppText.body;
    } else {
      title = l10n.bedFree;
      titleStyle = AppText.body.copyWith(color: AppColors.muted);
      subtitle = null;
    }

    Widget? trailing;
    VoidCallback? onTap;

    if (isOccupied) {
      trailing = const Icon(
        AppIcons.chevronRight,
        size: 20,
        color: AppColors.muted,
      );
      if (bed.stayId != null) {
        onTap = () async {
          await context.push('/owner/guests/${bed.stayId}');
          ref.invalidate(bedOccupancyProvider);
        };
      }
    } else if (isOwnerOrManager) {
      trailing = AppButton.text(
        label: l10n.actionAddGuest,
        onPressed: () async {
          await context.push('${RoutePaths.ownerGuestsNew}?bedId=${bed.bedId}');
          ref.invalidate(bedOccupancyProvider);
        },
      );
    }

    return LedgerRow(
      leading: RoomTile(label: bed.bedLabel),
      leadingGap: AppSpace.x16,
      title: title,
      titleStyle: titleStyle,
      subtitle: subtitle,
      trailing: trailing,
      minHeight: 56,
      showDivider: showDivider,
      onTap: onTap,
    );
  }
}
