import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/format/dates.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/ledger_row.dart';
import '../../../../core/widgets/ledger_sheet.dart';
import '../../../../core/widgets/money.dart';
import '../../../../core/widgets/room_tile.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../domain/month_collections.dart';
import '../providers/owner_provider.dart';

class OwnerCollectionsScreen extends ConsumerStatefulWidget {
  const OwnerCollectionsScreen({super.key});

  @override
  ConsumerState<OwnerCollectionsScreen> createState() =>
      _OwnerCollectionsScreenState();
}

class _OwnerCollectionsScreenState
    extends ConsumerState<OwnerCollectionsScreen> {
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
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    if (!_canGoNext) return;
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    });
  }

  IconData _paymentMethodIcon(String methodCode) {
    switch (methodCode.toLowerCase()) {
      case 'upi':
        return AppIcons.upi;
      case 'bank':
        return AppIcons.bank;
      case 'cash':
      case 'cheque':
      default:
        return AppIcons.cash;
    }
  }

  void _refresh() {
    ref.invalidate(monthCollectionsProvider(_monthKey));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final collectionsAsync = ref.watch(monthCollectionsProvider(_monthKey));

    return Scaffold(
      backgroundColor: AppColors.ground,
      appBar: AppTopBar.back(
        title: l10n.collectionsTitle,
        onLeadingPressed: () => context.pop(),
      ),
      body: RefreshIndicator(
        color: AppColors.petrol,
        onRefresh: () async => _refresh(),
        child: collectionsAsync.when(
          loading: () => _buildLoadingState(l10n),
          error: (err, stack) => _buildErrorState(l10n, err),
          data: (collections) => _buildContent(context, l10n, collections),
        ),
      ),
    );
  }

  Widget _buildLoadingState(AppLocalizations l10n) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: AppSpace.x12),
      children: [
        _buildTotalSheet(l10n, totalPaise: 0, paymentCount: 0, isLoading: true),
        const SizedBox(height: AppSpace.x12),
        const SkeletonList(itemCount: 3),
      ],
    );
  }

  Widget _buildErrorState(AppLocalizations l10n, Object err) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: AppSpace.x12),
      children: [
        _buildTotalSheet(l10n, totalPaise: 0, paymentCount: 0),
        const SizedBox(height: AppSpace.x24),
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
    MonthCollections collections,
  ) {
    final byAccount = collections.byAccount;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: AppSpace.x12, bottom: AppSpace.x32),
      children: [
        _buildTotalSheet(
          l10n,
          totalPaise: collections.totalPaise,
          paymentCount: collections.paymentCount,
        ),
        const SizedBox(height: AppSpace.x12),
        if (byAccount.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.x24),
            child: EmptyState(
              icon: AppIcons.payments,
              title: l10n.collectionsEmptyTitle,
              body: l10n.collectionsEmptyBody,
            ),
          )
        else
          LedgerSheet(
            margin: const EdgeInsets.symmetric(horizontal: AppSpace.x16),
            children: [
              for (int i = 0; i < byAccount.length; i++)
                _buildAccountRow(
                  l10n,
                  byAccount[i],
                  i < byAccount.length - 1,
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildTotalSheet(
    AppLocalizations l10n, {
    required int totalPaise,
    required int paymentCount,
    bool isLoading = false,
  }) {
    final monthName = DateFormat.formatMonthYear(_selectedMonth);

    return LedgerSheet(
      margin: const EdgeInsets.symmetric(horizontal: AppSpace.x16),
      padding: const EdgeInsets.all(AppSpace.x16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              monthName,
              style: AppText.label.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
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
        Text(
          l10n.collectionsReceivedIn(monthName),
          style: AppText.secondary,
        ),
        const SizedBox(height: AppSpace.x4),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpace.x4),
            child: SkeletonBlock(width: 140, height: 32),
          )
        else
          Money(
            paise: totalPaise,
            style: AppText.display,
          ),
        const SizedBox(height: AppSpace.x4),
        Text(
          paymentCount > 0
              ? l10n.collectionsPayments(paymentCount)
              : l10n.collectionsNone,
          style: AppText.secondary,
        ),
      ],
    );
  }

  Widget _buildAccountRow(
    AppLocalizations l10n,
    AccountCollection account,
    bool showDivider,
  ) {
    final title = (account.accountNickname != null &&
            account.accountNickname!.trim().isNotEmpty)
        ? account.accountNickname!.trim()
        : account.methodLabel;

    return LedgerRow(
      leading: RoomTile(icon: _paymentMethodIcon(account.methodCode)),
      title: title,
      subtitle: l10n.collectionsPayments(account.paymentCount),
      paise: account.totalPaise,
      showDivider: showDivider,
      onTap: null, // Non-tappable row
    );
  }
}

