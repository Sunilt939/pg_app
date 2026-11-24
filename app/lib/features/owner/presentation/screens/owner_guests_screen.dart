import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/format/dates.dart';
import '../../../../core/format/money.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/ledger_row.dart';
import '../../../../core/widgets/ledger_sheet.dart';
import '../../../../core/widgets/money.dart';
import '../../../../core/widgets/pg_switcher_title.dart';
import '../../../../core/widgets/room_tile.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/widgets/underline_tabs.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/owner_repository.dart';
import '../../../shared/presentation/widgets/notification_bell_button.dart';
import '../providers/owner_provider.dart';
import '../widgets/pg_switcher_sheet.dart';

class OwnerGuestsScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const OwnerGuestsScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<OwnerGuestsScreen> createState() => _OwnerGuestsScreenState();
}

class _OwnerGuestsScreenState extends ConsumerState<OwnerGuestsScreen> {
  late int _selectedTab;
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTabIndex;
    _searchController = TextEditingController();
    _scrollController = ScrollController();

    _searchController.addListener(() {
      final query = _searchController.text;
      if (query != _searchQuery) {
        setState(() {
          _searchQuery = query;
        });
      }
    });

    _scrollController.addListener(() {
      if (_scrollController.hasClients &&
          _scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200) {
        ref.read(guestListProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatDateShort(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '';
    final parsed = DateTime.tryParse(rawDate);
    if (parsed == null) return rawDate;
    final now = DateTime.now();
    if (parsed.year == now.year) {
      return DateFormat.formatShortDate(parsed);
    }
    return DateFormat.formatDate(parsed);
  }

  String _buildSubtitle(
    GuestListItem item,
    AppLocalizations l10n,
  ) {
    if (item.stayStatus == 'vacated') {
      final leaveStr = _formatDateShort(item.leaveDate);
      return l10n.guestLeft(leaveStr);
    }

    final bedPart = item.bedLabel != null && item.bedLabel!.trim().isNotEmpty
        ? l10n.guestBedPart(item.bedLabel!.trim())
        : l10n.guestNoBed;

    String statePart;
    switch (item.attentionState) {
      case 'overdue':
        final dateStr = _formatDateShort(item.oldestUnpaidDueDate);
        statePart = l10n.guestStateOverdue(dateStr);
        break;
      case 'pending':
        statePart = l10n.guestStatePending;
        break;
      case 'due':
        final dateStr = _formatDateShort(item.oldestUnpaidDueDate);
        statePart = l10n.guestStateDue(dateStr);
        break;
      case 'paid':
      default:
        if (item.creditPaise > 0) {
          statePart =
              l10n.guestStatePaidAdvance(MoneyFormat.format(item.creditPaise));
        } else {
          statePart = l10n.guestStatePaid;
        }
        break;
    }

    return '$bedPart, $statePart';
  }

  bool _matchesSearch(GuestListItem item, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;

    if (item.fullName != null && item.fullName!.toLowerCase().contains(q)) {
      return true;
    }
    if (item.roomNumber != null && item.roomNumber!.toLowerCase().contains(q)) {
      return true;
    }
    final qDigits = q.replaceAll(RegExp(r'\D'), '');
    final phoneDigits = item.phone.replaceAll(RegExp(r'\D'), '');
    if (qDigits.isNotEmpty && phoneDigits.contains(qDigits)) {
      return true;
    }
    if (item.phone.toLowerCase().contains(q)) {
      return true;
    }
    return false;
  }

  int _compareOpen(GuestListItem a, GuestListItem b) {
    final overdueCmp = b.overduePaise.compareTo(a.overduePaise);
    if (overdueCmp != 0) return overdueCmp;
    final outstandingCmp = b.outstandingPaise.compareTo(a.outstandingPaise);
    if (outstandingCmp != 0) return outstandingCmp;
    final nameA = (a.fullName ?? a.phone).toLowerCase();
    final nameB = (b.fullName ?? b.phone).toLowerCase();
    return nameA.compareTo(nameB);
  }

  int _comparePast(GuestListItem a, GuestListItem b) {
    if (a.leaveDate == null && b.leaveDate == null) return 0;
    if (a.leaveDate == null) return 1;
    if (b.leaveDate == null) return -1;
    return b.leaveDate!.compareTo(a.leaveDate!);
  }

  List<GuestListItem> _filterAndSort(List<GuestListItem> guests) {
    final filteredByTab = guests.where((item) {
      switch (_selectedTab) {
        case 1: // Overdue
          return item.stayStatus != 'vacated' && item.overduePaise > 0;
        case 2: // Due
          return item.stayStatus != 'vacated' &&
              item.outstandingPaise > 0 &&
              item.overduePaise == 0;
        case 3: // Paid
          return item.stayStatus != 'vacated' && item.outstandingPaise == 0;
        case 4: // Past
          return item.stayStatus == 'vacated';
        case 0: // All
        default:
          return item.stayStatus != 'vacated';
      }
    }).toList();

    if (_selectedTab == 4) {
      filteredByTab.sort(_comparePast);
    } else {
      filteredByTab.sort(_compareOpen);
    }

    if (_searchQuery.trim().isEmpty) {
      return filteredByTab;
    }

    return filteredByTab
        .where((item) => _matchesSearch(item, _searchQuery))
        .toList();
  }

  Future<void> _refresh() async {
    ref.invalidate(guestListProvider);
    ref.invalidate(pgOverviewProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activePg = ref.watch(activePgProvider);
    final pgTitle = activePg?.name ?? AppConfig.appName;
    final isOwnerOrManager =
        activePg?.role == 'owner' || activePg?.role == 'manager';

    final guestsAsync = ref.watch(guestListProvider);
    final overviewAsync = ref.watch(pgOverviewProvider);
    final overview = overviewAsync.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.ground,
      appBar: AppTopBar(
        titleWidget: PgSwitcherTitle(
          pgName: pgTitle,
          onTap: () => PgSwitcherSheet.show(context),
        ),
        actions: [
          if (isOwnerOrManager)
            IconButton(
              icon: const Icon(
                AppIcons.add,
                size: AppSize.icon,
                color: AppColors.ink,
              ),
              tooltip: l10n.addGuestTitle,
              onPressed: () async {
                await context.push(RoutePaths.ownerGuestsNew);
                _refresh();
              },
            ),
          const NotificationBellButton(),
        ],
      ),
      body: guestsAsync.when(
        loading: () => Column(
          children: [
            _buildSearchRow(l10n),
            _buildTabs(overview, l10n),
            const Expanded(
              child: SingleChildScrollView(
                physics: NeverScrollableScrollPhysics(),
                padding: EdgeInsets.only(top: AppSpace.x12),
                child: SkeletonList(itemCount: 6),
              ),
            ),
          ],
        ),
        error: (error, _) => ErrorState(
          title: l10n.errorGeneric,
          message: l10n.errorNetwork,
          onRetry: _refresh,
        ),
        data: (allGuests) {
          if (allGuests.isEmpty && _searchQuery.isEmpty) {
            return RefreshIndicator(
              color: AppColors.petrol,
              onRefresh: _refresh,
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: EmptyState(
                      icon: AppIcons.guests,
                      title: l10n.guestsEmptyTitle,
                      body: l10n.guestsEmptyBody,
                      actionLabel:
                          isOwnerOrManager ? l10n.actionAddGuest : null,
                      onAction: isOwnerOrManager
                          ? () async {
                              await context.push(RoutePaths.ownerGuestsNew);
                              _refresh();
                            }
                          : null,
                    ),
                  ),
                ),
              ),
            );
          }

          final visibleGuests = _filterAndSort(allGuests);

          return RefreshIndicator(
            color: AppColors.petrol,
            onRefresh: _refresh,
            child: Column(
              children: [
                _buildSearchRow(l10n),
                _buildTabs(overview, l10n),
                Expanded(
                  child: visibleGuests.isEmpty
                      ? LayoutBuilder(
                          builder: (context, constraints) =>
                              SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight),
                              child: EmptyState(
                                icon: AppIcons.guests,
                                title: l10n.guestsFilterEmptyTitle,
                                body: l10n.guestsFilterEmptyBody,
                              ),
                            ),
                          ),
                        )
                      : ListView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(
                            top: AppSpace.x12,
                            bottom: AppSpace.x32,
                          ),
                          children: [
                            LedgerSheet(
                              margin: EdgeInsets.zero,
                              children: [
                                for (int i = 0; i < visibleGuests.length; i++)
                                  _buildGuestRow(
                                    context,
                                    visibleGuests[i],
                                    i < visibleGuests.length - 1,
                                    l10n,
                                  ),
                              ],
                            ),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchRow(AppLocalizations l10n) {
    return Container(
      color: AppColors.ground,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.x16,
        vertical: AppSpace.x12,
      ),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.control,
          border: Border.all(
            color: AppColors.outline,
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: AppSpace.x12),
            const Icon(
              AppIcons.search,
              size: 20,
              color: AppColors.muted,
            ),
            const SizedBox(width: AppSpace.x8),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: AppText.bodyMedium,
                cursorColor: AppColors.petrol,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: l10n.guestSearchHint,
                  hintStyle:
                      AppText.body.copyWith(color: AppColors.muted),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: AppSpace.x12),
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpace.x12),
                  child: Icon(
                    AppIcons.close,
                    size: 16,
                    color: AppColors.muted,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs(PgOverview? overview, AppLocalizations l10n) {
    return UnderlineTabs(
      selectedIndex: _selectedTab,
      onTabSelected: (index) {
        setState(() => _selectedTab = index);
      },
      tabs: [
        UnderlineTabItem(
          label: l10n.tabAll,
          count: overview?.openCount,
        ),
        UnderlineTabItem(
          label: l10n.tabOverdue,
          count: overview?.overdueCount,
        ),
        UnderlineTabItem(
          label: l10n.tabDue,
          count: overview?.dueCount,
        ),
        UnderlineTabItem(
          label: l10n.tabPaid,
          count: overview?.paidCount,
        ),
        UnderlineTabItem(
          label: l10n.tabPast,
          count: overview?.pastCount,
        ),
      ],
    );
  }

  Widget _buildGuestRow(
    BuildContext context,
    GuestListItem item,
    bool showDivider,
    AppLocalizations l10n,
  ) {
    final title = (item.fullName != null && item.fullName!.trim().isNotEmpty)
        ? item.fullName!.trim()
        : item.phone;
    final subtitle = _buildSubtitle(item, l10n);

    int? paise;
    StatusChipKind? statusKind;
    Widget? trailing;

    if (item.stayStatus == 'vacated') {
      if (item.outstandingPaise > 0) {
        trailing = Money(
          paise: item.outstandingPaise,
          style: AppText.heading.copyWith(color: AppColors.overdueFg),
        );
      }
    } else {
      switch (item.attentionState) {
        case 'overdue':
          paise = item.overduePaise;
          statusKind = StatusChipKind.overdue;
          break;
        case 'pending':
          paise = item.pendingVerificationPaise;
          statusKind = StatusChipKind.pending;
          break;
        case 'due':
          paise = item.outstandingPaise;
          statusKind = StatusChipKind.due;
          break;
        case 'paid':
        default:
          statusKind = StatusChipKind.paid;
          break;
      }
    }

    return LedgerRow(
      leading: RoomTile(label: item.roomNumber),
      title: title,
      subtitle: subtitle,
      paise: paise,
      statusKind: statusKind,
      trailing: trailing,
      showDivider: showDivider,
      onTap: () {
        context.push(
          RoutePaths.ownerGuestDetail.replaceFirst(':stayId', item.stayId),
        );
      },
    );
  }
}
