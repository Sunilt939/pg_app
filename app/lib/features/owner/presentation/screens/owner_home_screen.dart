import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/format/dates.dart';
import '../../../../core/format/money.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/ledger_row.dart';
import '../../../../core/widgets/ledger_sheet.dart';
import '../../../../core/widgets/money.dart';
import '../../../../core/widgets/option_sheet.dart';
import '../../../../core/widgets/pg_switcher_title.dart';
import '../../../../core/widgets/progress_bar_thin.dart';
import '../../../../core/widgets/room_tile.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/guest_list_item.dart';
import '../../domain/owner_home_bundle.dart';
import '../../domain/payment_feed_item.dart';
import '../../domain/pg_setup_status.dart';
import '../providers/owner_provider.dart';
import '../widgets/confirm_payment_sheet.dart';
import '../widgets/pg_switcher_sheet.dart';
import '../widgets/reject_payment_sheet.dart';

class OwnerHomeScreen extends ConsumerStatefulWidget {
  const OwnerHomeScreen({super.key});

  @override
  ConsumerState<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends ConsumerState<OwnerHomeScreen> {
  late DateTime _selectedMonth;
  late final DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    final nowIst = DateFormat.toIst(DateTime.now());
    _currentMonth = DateTime(nowIst.year, nowIst.month, 1);
    _selectedMonth = _currentMonth;
  }

  String get _monthKey {
    final year = _selectedMonth.year.toString().padLeft(4, '0');
    final month = _selectedMonth.month.toString().padLeft(2, '0');
    return '$year-$month-01';
  }

  bool get _isCurrentMonth =>
      _selectedMonth.year == _currentMonth.year &&
      _selectedMonth.month == _currentMonth.month;

  bool get _canGoNext {
    return _selectedMonth.year < _currentMonth.year ||
        (_selectedMonth.year == _currentMonth.year &&
            _selectedMonth.month < _currentMonth.month);
  }

  bool get _canGoPrevious {
    final monthsDiff = (_currentMonth.year - _selectedMonth.year) * 12 +
        (_currentMonth.month - _selectedMonth.month);
    return monthsDiff < 24;
  }

  void _previousMonth() {
    if (!_canGoPrevious) return;
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    if (!_canGoNext) return;
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    });
  }

  String _formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '';
    final parsed = DateTime.tryParse(rawDate);
    if (parsed == null) return rawDate;
    return DateFormat.formatDate(parsed);
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

  void _refresh() {
    ref.invalidate(ownerHomeBundleProvider(_monthKey));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activePg = ref.watch(activePgProvider);
    final pgTitle = activePg?.name ?? AppConfig.appName;
    final isOwnerOrManager =
        activePg?.role == 'owner' || activePg?.role == 'manager';
    final homeAsync = ref.watch(ownerHomeBundleProvider(_monthKey));

    return Scaffold(
      backgroundColor: AppColors.ground,
      appBar: AppTopBar(
        titleWidget: PgSwitcherTitle(
          pgName: pgTitle,
          onTap: () => PgSwitcherSheet.show(context),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.petrol,
        onRefresh: () async => _refresh(),
        child: homeAsync.when(
          loading: () => _buildLoadingState(),
          error: (err, stack) => _buildErrorState(l10n),
          data: (bundle) {
            if (bundle == null) return const SizedBox.shrink();
            return _buildContent(context, l10n, bundle, isOwnerOrManager);
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: AppSpace.x12),
      children: const [
        LedgerSheet(
          margin: EdgeInsets.symmetric(horizontal: AppSpace.x16),
          padding: EdgeInsets.all(AppSpace.x16),
          children: [
            SkeletonBlock(width: 140, height: 20),
            SizedBox(height: AppSpace.x12),
            SkeletonBlock(width: 100, height: 14),
            SizedBox(height: AppSpace.x8),
            SkeletonBlock(width: 160, height: 32),
            SizedBox(height: AppSpace.x12),
            SkeletonBlock(height: 6),
            SizedBox(height: AppSpace.x8),
            SkeletonBlock(width: 120, height: 14),
          ],
        ),
        SizedBox(height: AppSpace.x16),
        SkeletonList(itemCount: 4),
      ],
    );
  }

  Widget _buildErrorState(AppLocalizations l10n) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        ErrorState(
          title: l10n.errorGeneric,
          message: l10n.errorNetwork,
          onRetry: _refresh,
        ),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    OwnerHomeBundle bundle,
    bool isOwnerOrManager,
  ) {
    final setup = bundle.setupStatus;
    final hasGuests = setup.guestsCount > 0;
    final showSetupChecklist = !setup.isCompleted;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: AppSpace.x12, bottom: AppSpace.x32),
      children: [
        if (showSetupChecklist) _buildSetupCard(context, l10n, setup),
        if (hasGuests) ...[
          _buildSummarySheet(context, l10n, bundle),
          _buildButtonsRow(context, l10n, bundle, isOwnerOrManager),
          _buildNeedsAttentionSection(context, l10n, bundle),
        ],
        _buildMoneyReceivedRow(context, l10n),
      ],
    );
  }

  Widget _buildSetupCard(
    BuildContext context,
    AppLocalizations l10n,
    PgSetupStatus setup,
  ) {
    return LedgerSheet(
      margin: const EdgeInsets.only(
        left: AppSpace.x16,
        right: AppSpace.x16,
        bottom: AppSpace.x16,
      ),
      padding: const EdgeInsets.all(AppSpace.x16),
      children: [
        Text(
          l10n.setupTitle,
          style: AppText.heading,
        ),
        const SizedBox(height: AppSpace.x4),
        Text(
          l10n.setupBody,
          style: AppText.secondary,
        ),
        const SizedBox(height: AppSpace.x8),
        _buildChecklistRow(
          title: l10n.setupRooms,
          isDone: setup.roomsCount > 0,
          onTap: () async {
            await context.push('/owner/rooms/setup');
            _refresh();
          },
        ),
        _buildChecklistRow(
          title: l10n.setupAccount,
          isDone: setup.accountsCount > 0,
          onTap: () async {
            await context.push('/owner/accounts/new');
            _refresh();
          },
        ),
        _buildChecklistRow(
          title: l10n.setupGuest,
          isDone: setup.guestsCount > 0,
          onTap: () async {
            await context.push('/owner/guests/new');
            _refresh();
          },
          showDivider: false,
        ),
      ],
    );
  }

  Widget _buildChecklistRow({
    required String title,
    required bool isDone,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone ? AppColors.paidFg : AppColors.transparent,
                    border: isDone
                        ? null
                        : Border.all(color: AppColors.outline, width: 2),
                  ),
                  child: isDone
                      ? const Icon(
                          AppIcons.check,
                          size: 16,
                          color: AppColors.surface,
                        )
                      : null,
                ),
                const SizedBox(width: AppSpace.x12),
                Expanded(
                  child: Text(
                    title,
                    style: AppText.body.copyWith(
                      color: isDone ? AppColors.muted : AppColors.ink,
                    ),
                  ),
                ),
                const Icon(
                  AppIcons.chevronRight,
                  size: 20,
                  color: AppColors.muted,
                ),
              ],
            ),
          ),
          if (showDivider)
            const Divider(
              height: 1,
              thickness: 1,
              color: AppColors.hairline,
            ),
        ],
      ),
    );
  }

  Widget _buildSummarySheet(
    BuildContext context,
    AppLocalizations l10n,
    OwnerHomeBundle bundle,
  ) {
    final monthName = DateFormat.formatMonthYear(_selectedMonth);
    final summary = bundle.monthlySummary;
    final overview = bundle.overview;
    final overdueTotalPaise = overview?.overdueTotalPaise ?? 0;

    final expected = summary?.expectedPaise ?? 0;
    final collected = summary?.collectedPaise ?? 0;
    final pending = summary?.pendingPaise ?? 0;
    final hasSummary = summary != null && (expected > 0 || collected > 0);

    final progress = expected > 0 ? (collected / expected) : 0.0;

    return LedgerSheet(
      margin: const EdgeInsets.only(
        left: AppSpace.x16,
        right: AppSpace.x16,
        bottom: AppSpace.x16,
      ),
      padding: const EdgeInsets.all(AppSpace.x16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              monthName,
              style: AppText.roomTile,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      AppIcons.chevronLeft,
                      size: 24,
                      color: _canGoPrevious ? AppColors.ink : AppColors.muted,
                    ),
                    onPressed: _canGoPrevious ? _previousMonth : null,
                  ),
                ),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      AppIcons.chevronRight,
                      size: 24,
                      color: _canGoNext ? AppColors.ink : AppColors.muted,
                    ),
                    onPressed: _canGoNext ? _nextMonth : null,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpace.x8),
        if (!hasSummary) ...[
          Text(
            l10n.monthNoCharges(monthName),
            style: AppText.secondary,
          ),
        ] else ...[
          Text(
            _isCurrentMonth
                ? l10n.monthToCollect
                : l10n.monthToCollectIn(monthName),
            style: AppText.secondary,
          ),
          const SizedBox(height: AppSpace.x4),
          Money(
            paise: pending,
            style: AppText.display,
          ),
          const SizedBox(height: AppSpace.x12),
          ProgressBarThin(progress: progress),
          const SizedBox(height: AppSpace.x8),
          Text(
            l10n.monthCollected(
              MoneyFormat.format(collected),
              MoneyFormat.format(expected),
            ),
            style: AppText.secondary,
          ),
        ],
        const SizedBox(height: AppSpace.x16),
        const Divider(
          height: 1,
          thickness: 1,
          color: AppColors.hairline,
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => context.go('/owner/guests?tab=overdue'),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              children: [
                Text(
                  l10n.overdueLabel,
                  style: AppText.body,
                ),
                const Spacer(),
                if (overdueTotalPaise > 0)
                  Money(
                    paise: overdueTotalPaise,
                    color: AppColors.overdueFg,
                    style: AppText.roomTile.copyWith(
                      color: AppColors.overdueFg,
                    ),
                  )
                else
                  Text(
                    l10n.overdueNone,
                    style: AppText.body.copyWith(color: AppColors.muted),
                  ),
                const SizedBox(width: AppSpace.x8),
                const Icon(
                  AppIcons.chevronRight,
                  size: 20,
                  color: AppColors.muted,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButtonsRow(
    BuildContext context,
    AppLocalizations l10n,
    OwnerHomeBundle bundle,
    bool isOwnerOrManager,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpace.x16,
        right: AppSpace.x16,
        bottom: AppSpace.x16,
      ),
      child: Row(
        children: [
          Expanded(
            child: AppButton.primary(
              label: l10n.actionRecordPayment,
              onPressed: () => _openRecordPaymentPicker(
                context,
                bundle.openGuests,
                l10n,
              ),
            ),
          ),
          if (isOwnerOrManager) ...[
            const SizedBox(width: AppSpace.x12),
            Expanded(
              child: AppButton.secondary(
                label: l10n.actionAddGuest,
                onPressed: () async {
                  await context.push('/owner/guests/new');
                  _refresh();
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openRecordPaymentPicker(
    BuildContext context,
    List<GuestListItem> openGuests,
    AppLocalizations l10n,
  ) async {
    final options = openGuests.map((g) {
      final title = (g.fullName != null && g.fullName!.trim().isNotEmpty)
          ? g.fullName!.trim()
          : g.phone;
      final roomSub = (g.roomNumber != null && g.roomNumber!.isNotEmpty)
          ? 'Room ${g.roomNumber}'
          : null;
      return OptionSheetItem<String>(
        value: g.stayId,
        title: title,
        subtitle: roomSub,
      );
    }).toList();

    final pickedStayId = await OptionSheet.show<String>(
      context: context,
      title: l10n.pickGuestTitle,
      showSearch: true,
      searchHint: l10n.pickGuestSearch,
      options: options,
    );

    if (pickedStayId != null && context.mounted) {
      await context.push('/owner/guests/$pickedStayId/pay');
      _refresh();
    }
  }

  Widget _buildNeedsAttentionSection(
    BuildContext context,
    AppLocalizations l10n,
    OwnerHomeBundle bundle,
  ) {
    final pending = bundle.pendingPayments;
    final overdue = bundle.overdueGuests;

    // Up to 10 in total across pending and overdue
    final pendingSlots = pending.length.clamp(0, 10);
    final remainingSlots = 10 - pendingSlots;
    final overdueToShow = overdue.take(remainingSlots).toList();
    final overflowOverdueCount = overdue.length - overdueToShow.length;

    final totalCount = pending.length + overdue.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: l10n.needsAttention,
          trailing: totalCount > 0
              ? Text(
                  '$totalCount',
                  style: AppText.secondary,
                )
              : null,
        ),
        if (totalCount == 0)
          LedgerSheet(
            margin: const EdgeInsets.only(
              left: AppSpace.x16,
              right: AppSpace.x16,
              bottom: AppSpace.x16,
            ),
            padding: const EdgeInsets.all(AppSpace.x24),
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      AppIcons.check,
                      size: 28,
                      color: AppColors.paidFg,
                    ),
                    const SizedBox(height: AppSpace.x8),
                    Text(
                      l10n.needsAttentionEmptyTitle,
                      style: AppText.heading,
                    ),
                    const SizedBox(height: AppSpace.x4),
                    Text(
                      l10n.needsAttentionEmptyBody,
                      style: AppText.secondary,
                    ),
                  ],
                ),
              ),
            ],
          )
        else
          LedgerSheet(
            margin: const EdgeInsets.only(
              left: AppSpace.x16,
              right: AppSpace.x16,
              bottom: AppSpace.x16,
            ),
            children: [
              for (int i = 0; i < pendingSlots; i++)
                _buildPendingPaymentRow(
                  context,
                  l10n,
                  pending[i],
                  i < pendingSlots - 1 || overdueToShow.isNotEmpty,
                ),
              for (int i = 0; i < overdueToShow.length; i++)
                _buildOverdueGuestRow(
                  context,
                  l10n,
                  overdueToShow[i],
                  i < overdueToShow.length - 1 || overflowOverdueCount > 0,
                ),
              if (overflowOverdueCount > 0)
                LedgerRow(
                  title: l10n.seeAllOverdue(overflowOverdueCount),
                  trailing: const Icon(
                    AppIcons.chevronRight,
                    size: 20,
                    color: AppColors.muted,
                  ),
                  showDivider: false,
                  onTap: () => context.go('/owner/guests?tab=overdue'),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildPendingPaymentRow(
    BuildContext context,
    AppLocalizations l10n,
    PaymentFeedItem payment,
    bool showDivider,
  ) {
    final title = (payment.fullName != null &&
            payment.fullName!.trim().isNotEmpty)
        ? payment.fullName!.trim()
        : (payment.phone ?? '');

    return LedgerRow(
      leading: RoomTile(label: payment.roomNumber),
      title: title,
      subtitle: l10n.rowReported(
        MoneyFormat.format(payment.amountPaise),
        payment.methodLabel,
        _formatDate(payment.paidOn),
      ),
      paise: payment.amountPaise,
      statusKind: StatusChipKind.pending,
      showDivider: showDivider,
      onTap: () async {
        await context.push('/owner/payments/${payment.paymentId}');
        _refresh();
      },
      inlineActions: [
        AppButton.text(
          label: l10n.actionReject,
          textColor: AppColors.overdueFg,
          onPressed: () async {
            final res = await RejectPaymentSheet.show(
              context,
              payment: payment,
            );
            if (res == true) {
              _refresh();
            }
          },
        ),
        AppButton.text(
          label: l10n.actionConfirm,
          textColor: AppColors.petrol,
          onPressed: () async {
            final res = await ConfirmPaymentSheet.show(
              context,
              payment: payment,
            );
            if (res == true) {
              _refresh();
            }
          },
        ),
      ],
    );
  }

  Widget _buildOverdueGuestRow(
    BuildContext context,
    AppLocalizations l10n,
    GuestListItem guest,
    bool showDivider,
  ) {
    final title = (guest.fullName != null && guest.fullName!.trim().isNotEmpty)
        ? guest.fullName!.trim()
        : guest.phone;

    return LedgerRow(
      leading: RoomTile(label: guest.roomNumber),
      title: title,
      subtitle: l10n.rowOverdueSince(_formatDateShort(guest.oldestUnpaidDueDate)),
      paise: guest.overduePaise,
      statusKind: StatusChipKind.overdue,
      showDivider: showDivider,
      onTap: () async {
        await context.push('/owner/guests/${guest.stayId}');
        _refresh();
      },
      inlineActions: [
        AppButton.text(
          label: l10n.actionRecordPayment,
          textColor: AppColors.petrol,
          onPressed: () async {
            await context.push('/owner/guests/${guest.stayId}/pay');
            _refresh();
          },
        ),
        if (AppFlags.remindersEnabled)
          AppButton.text(
            label: l10n.actionRemind,
            textColor: AppColors.petrol,
            onPressed: () {
              // Reminders not sent yet per flags
            },
          ),
      ],
    );
  }

  Widget _buildMoneyReceivedRow(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return LedgerSheet(
      margin: const EdgeInsets.only(
        left: AppSpace.x16,
        right: AppSpace.x16,
        bottom: AppSpace.x16,
      ),
      children: [
        LedgerRow(
          title: l10n.collectionsLink,
          trailing: const Icon(
            AppIcons.chevronRight,
            size: 20,
            color: AppColors.muted,
          ),
          showDivider: false,
          onTap: () => context.push('/owner/collections'),
        ),
      ],
    );
  }
}
