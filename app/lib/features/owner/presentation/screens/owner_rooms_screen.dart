import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/natural_sort.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/ledger_row.dart';
import '../../../../core/widgets/ledger_sheet.dart';
import '../../../../core/widgets/room_tile.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/bed_occupancy.dart';
import '../providers/owner_provider.dart';

class OwnerRoomsScreen extends ConsumerWidget {
  const OwnerRoomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final activePg = ref.watch(activePgProvider);
    final role = activePg?.role;
    final isOwnerOrManager = role == 'owner' || role == 'manager';

    final bedsAsync = ref.watch(bedOccupancyProvider);

    return Scaffold(
      backgroundColor: AppColors.ground,
      appBar: AppTopBar.back(
        title: l10n.roomsTitle,
        onLeadingPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(RoutePaths.ownerMore);
          }
        },
        actions: [
          if (isOwnerOrManager)
            IconButton(
              icon: const Icon(
                AppIcons.add,
                size: AppSize.icon,
                color: AppColors.ink,
              ),
              tooltip: l10n.addRoomsTitle,
              onPressed: () async {
                await context.push(RoutePaths.ownerRoomsNew);
                ref.invalidate(bedOccupancyProvider);
              },
            ),
        ],
      ),
      body: bedsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.petrol),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.x16),
            child: Text(
              error.toString().replaceFirst('Exception: ', ''),
              style: AppText.secondary.copyWith(color: AppColors.overdueFg),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (beds) {
          final rooms = RoomSummary.fromBedList(beds);

          if (rooms.isEmpty) {
            return EmptyState(
              icon: AppIcons.room,
              title: l10n.roomsEmptyTitle,
              body: l10n.roomsEmptyBody,
              actionLabel: isOwnerOrManager ? l10n.roomsEmptyAction : null,
              onAction: isOwnerOrManager
                  ? () async {
                      await context.push(RoutePaths.ownerRoomsSetup);
                      ref.invalidate(bedOccupancyProvider);
                    }
                  : null,
            );
          }

          final totalRooms = rooms.length;
          final totalBeds = rooms.fold<int>(0, (sum, r) => sum + r.totalBeds);
          final totalFree = rooms.fold<int>(0, (sum, r) => sum + r.freeBeds);

          final hasAnyFloor = rooms.any((r) => r.floor != null);

          if (!hasAnyFloor) {
            // One plain list
            return ListView(
              padding: const EdgeInsets.only(bottom: AppSpace.x32),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.x16,
                    AppSpace.x16,
                    AppSpace.x16,
                    AppSpace.x8,
                  ),
                  child: Text(
                    l10n.roomsSummary(totalRooms, totalBeds, totalFree),
                    style: AppText.secondary,
                  ),
                ),
                LedgerSheet(
                  children: [
                    for (int i = 0; i < rooms.length; i++)
                      _buildRoomRow(context, l10n, rooms[i], i < rooms.length - 1, ref),
                  ],
                ),
              ],
            );
          }

          // Group by floor
          final distinctFloors = rooms.map((r) => r.floor).toSet().toList();
          // Sort floors: null at the end, numbers ascending
          distinctFloors.sort((a, b) {
            if (a == null && b == null) return 0;
            if (a == null) return 1;
            if (b == null) return -1;
            return a.compareTo(b);
          });

          return ListView(
            padding: const EdgeInsets.only(bottom: AppSpace.x32),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.x16,
                  AppSpace.x16,
                  AppSpace.x16,
                  AppSpace.x8,
                ),
                child: Text(
                  l10n.roomsSummary(totalRooms, totalBeds, totalFree),
                  style: AppText.secondary,
                ),
              ),
              for (final floor in distinctFloors) ...[
                SectionHeader(
                  title: floor == null
                      ? l10n.roomsNoFloor
                      : (floor == 0 ? l10n.layoutGroundFloor : l10n.roomsFloor(floor)),
                ),
                LedgerSheet(
                  children: () {
                    final floorRooms = rooms.where((r) => r.floor == floor).toList()
                      ..sort((a, b) => naturalCompare(a.roomNumber, b.roomNumber));
                    return [
                      for (int i = 0; i < floorRooms.length; i++)
                        _buildRoomRow(context, l10n, floorRooms[i], i < floorRooms.length - 1, ref),
                    ];
                  }(),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildRoomRow(
    BuildContext context,
    AppLocalizations l10n,
    RoomSummary room,
    bool showDivider,
    WidgetRef ref,
  ) {
    final title = (room.roomTypeLabel != null && room.roomTypeLabel!.isNotEmpty)
        ? room.roomTypeLabel!
        : l10n.roomDefaultTitle;
    final subtitle = l10n.roomsBedsFree(room.totalBeds, room.freeBeds);

    final trailingWidget = room.isFull
        ? Text(
            l10n.roomsFull,
            style: AppText.secondary.copyWith(color: AppColors.muted),
          )
        : Text(
            l10n.roomsFreeCount(room.freeBeds),
            style: AppText.secondary.copyWith(color: AppColors.petrol),
          );

    return LedgerRow(
      leading: RoomTile(label: room.roomNumber),
      leadingGap: AppSpace.x16,
      title: title,
      titleStyle: AppText.body,
      subtitle: subtitle,
      trailing: trailingWidget,
      minHeight: 56,
      showDivider: showDivider,
      onTap: () async {
        await context.push('/owner/rooms/${room.roomId}');
        ref.invalidate(bedOccupancyProvider);
      },
    );
  }
}

