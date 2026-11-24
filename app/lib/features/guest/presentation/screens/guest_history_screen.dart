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
import '../../../../core/widgets/room_tile.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/widgets/underline_tabs.dart';
import '../../../owner/domain/charge_balance.dart';
import '../../../owner/domain/guest_list_item.dart';
import '../../../owner/domain/payment_feed_item.dart';
import '../../domain/guest_home_bundle.dart';
import '../../../shared/presentation/widgets/notification_bell_button.dart';
import '../providers/guest_provider.dart';
import '../widgets/guest_payment_status_sheet.dart';

class GuestHistoryScreen extends ConsumerStatefulWidget {
  const GuestHistoryScreen({super.key});

  @override
  ConsumerState<GuestHistoryScreen> createState() => _GuestHistoryScreenState();
}

class _GuestHistoryScreenState extends ConsumerState<GuestHistoryScreen> {
  int _selectedTabIndex = 0;

  IconData _paymentMethodIcon(String methodCode) {
    switch (methodCode) {
      case 'upi':
        return AppIcons.upi;
      case 'bank_transfer':
      case 'bank':
        return AppIcons.bank;
      case 'cash':
      case 'cheque':
      default:
        return AppIcons.cash;
    }
  }

  String _formatDateString(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '';
    final dt = DateTime.tryParse(isoDate);
    if (dt == null) return isoDate;
    return DateFormat.formatDate(dt);
  }

  Map<String, List<PaymentFeedItem>> _groupPaymentsByMonth(
    List<PaymentFeedItem> payments,
  ) {
    final groups = <String, List<PaymentFeedItem>>{};
    for (final p in payments) {
      final dt = DateTime.tryParse(p.paidOn);
      final key = dt != null ? DateFormat.formatMonthYear(dt) : 'Other';
      groups.putIfAbsent(key, () => []).add(p);
    }
    return groups;
  }

  Map<String, List<ChargeBalance>> _groupChargesByMonth(
    List<ChargeBalance> charges,
  ) {
    final groups = <String, List<ChargeBalance>>{};
    for (final c in charges) {
      final dt = DateTime.tryParse(c.dueDate);
      final key = dt != null ? DateFormat.formatMonthYear(dt) : 'Other';
      groups.putIfAbsent(key, () => []).add(c);
    }
    return groups;
  }

  Widget _buildPaymentRow(
    BuildContext context,
    AppLocalizations l10n,
    PaymentFeedItem payment,
    GuestListItem? stay,
    bool showDivider,
  ) {
    final methodStr = (payment.payerAppLabel != null &&
            payment.payerAppLabel!.isNotEmpty)
        ? '${payment.methodLabel}, ${payment.payerAppLabel}'
        : payment.methodLabel;

    StatusChipKind? statusKind;
    String? statusLabel;

    if (payment.status == 'pending') {
      statusKind = StatusChipKind.pending;
    } else if (payment.status == 'rejected') {
      statusKind = StatusChipKind.overdue;
      statusLabel = l10n.statusRejected;
    } else if (payment.status == 'reversed') {
      statusKind = StatusChipKind.overdue;
      statusLabel = l10n.statusReversed;
    }

    final dateFormatted = _formatDateString(payment.paidOn);

    return LedgerRow(
      leading: RoomTile(icon: _paymentMethodIcon(payment.methodCode)),
      title: l10n.activityPayment(methodStr),
      subtitle: dateFormatted,
      paise: payment.amountPaise,
      statusKind: statusKind,
      statusLabel: statusLabel,
      showDivider: showDivider,
      onTap: () {
        if (payment.receiptId != null) {
          context.push('/receipt/${payment.paymentId}');
        } else {
          GuestPaymentStatusSheet.show(
            context: context,
            payment: payment,
            stay: stay,
          );
        }
      },
    );
  }

  Widget _buildPreviousStayRow(
    BuildContext context,
    AppLocalizations l10n,
    GuestListItem stay,
    bool showDivider,
  ) {
    final fromDate = _formatDateString(stay.joinDate);
    final toDate = stay.leaveDate != null ? _formatDateString(stay.leaveDate!) : '';
    final datesSubtitle = l10n.historyStayDates(fromDate, toDate);

    return LedgerRow(
      title: stay.pgName,
      titleStyle: AppText.bodyMedium,
      subtitle: datesSubtitle,
      trailing: const Icon(
        AppIcons.chevronRight,
        size: 20,
        color: AppColors.muted,
      ),
      showDivider: showDivider,
      onTap: () => context.push('/guest/stay/${stay.stayId}'),
    );
  }

  Widget _buildPaymentsTab(
    BuildContext context,
    AppLocalizations l10n,
    GuestHomeBundle bundle,
  ) {
    final payments = bundle.payments;
    final previousStays = bundle.previousStays;

    if (payments.isEmpty && previousStays.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref.refresh(guestHomeBundleProvider.future),
        color: AppColors.petrol,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 400,
            child: EmptyState(
              icon: AppIcons.payments,
              title: l10n.historyEmptyPaymentsTitle,
              body: l10n.historyEmptyPaymentsBody,
            ),
          ),
        ),
      );
    }

    final grouped = _groupPaymentsByMonth(payments);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(guestHomeBundleProvider.future),
      color: AppColors.petrol,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpace.x16),
        children: [
          for (final entry in grouped.entries) ...[
            SectionHeader(title: entry.key),
            LedgerSheet(
              margin: const EdgeInsets.only(bottom: AppSpace.x12),
              children: [
                for (int i = 0; i < entry.value.length; i++)
                  _buildPaymentRow(
                    context,
                    l10n,
                    entry.value[i],
                    bundle.latestStay,
                    i < entry.value.length - 1,
                  ),
              ],
            ),
          ],
          if (previousStays.isNotEmpty) ...[
            SectionHeader(title: l10n.historyPrevious),
            LedgerSheet(
              margin: const EdgeInsets.only(bottom: AppSpace.x16),
              children: [
                for (int i = 0; i < previousStays.length; i++)
                  _buildPreviousStayRow(
                    context,
                    l10n,
                    previousStays[i],
                    i < previousStays.length - 1,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChargeRow(
    AppLocalizations l10n,
    ChargeBalance charge,
    bool showDivider,
  ) {
    StatusChipKind statusKind;
    String? statusLabel;

    switch (charge.status) {
      case 'paid':
        statusKind = StatusChipKind.paid;
        break;
      case 'overdue':
        statusKind = StatusChipKind.overdue;
        break;
      case 'partial':
        statusKind = StatusChipKind.due;
        statusLabel = l10n.chargePartPaid;
        break;
      case 'void':
        statusKind = StatusChipKind.due;
        statusLabel = l10n.chargeCancelled;
        break;
      case 'due':
      default:
        statusKind = StatusChipKind.due;
        break;
    }

    final displayPaise = charge.outstandingPaise > 0
        ? charge.outstandingPaise
        : charge.amountPaise;
    final dateFormatted = _formatDateString(charge.dueDate);

    return LedgerRow(
      title: charge.description,
      subtitle: l10n.chargeDue(dateFormatted),
      paise: displayPaise,
      statusKind: statusKind,
      statusLabel: statusLabel,
      showDivider: showDivider,
    );
  }

  Widget _buildChargesTab(
    BuildContext context,
    AppLocalizations l10n,
    GuestHomeBundle bundle,
  ) {
    final charges = bundle.charges;

    if (charges.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref.refresh(guestHomeBundleProvider.future),
        color: AppColors.petrol,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 400,
            child: EmptyState(
              icon: AppIcons.history,
              title: l10n.historyEmptyChargesTitle,
              body: '',
            ),
          ),
        ),
      );
    }

    final grouped = _groupChargesByMonth(charges);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(guestHomeBundleProvider.future),
      color: AppColors.petrol,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpace.x16),
        children: [
          for (final entry in grouped.entries) ...[
            SectionHeader(title: entry.key),
            LedgerSheet(
              margin: const EdgeInsets.only(bottom: AppSpace.x12),
              children: [
                for (int i = 0; i < entry.value.length; i++)
                  _buildChargeRow(
                    l10n,
                    entry.value[i],
                    i < entry.value.length - 1,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpace.x16),
      children: const [
        SectionHeader(title: 'Loading...'),
        LedgerSheet(
          padding: EdgeInsets.all(AppSpace.x16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBlock(height: 16, width: 140),
              SizedBox(height: AppSpace.x8),
              SkeletonBlock(height: 24, width: 200),
            ],
          ),
        ),
        SizedBox(height: AppSpace.x16),
        SkeletonList(itemCount: 4),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bundleAsync = ref.watch(guestHomeBundleProvider);

    return Scaffold(
      backgroundColor: AppColors.ground,
      appBar: AppTopBar(
        title: l10n.historyTitle,
        actions: const [
          NotificationBellButton(),
        ],
      ),
      body: bundleAsync.when(
        loading: _buildLoadingSkeleton,
        error: (err, _) => ErrorState(
          title: l10n.errorGeneric,
          message: err.toString(),
          onRetry: () => ref.refresh(guestHomeBundleProvider),
        ),
        data: (bundle) {
          final isPastStay =
              bundle.currentStay == null && bundle.latestPastStay != null;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isPastStay)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.x16,
                    vertical: AppSpace.x12,
                  ),
                  child: Text(
                    l10n.historyPastNotice(bundle.latestPastStay!.pgName),
                    style: AppText.secondary,
                  ),
                ),
              UnderlineTabs(
                tabs: [
                  UnderlineTabItem(label: l10n.tabPayments),
                  UnderlineTabItem(label: l10n.tabCharges),
                ],
                selectedIndex: _selectedTabIndex,
                onTabSelected: (index) {
                  setState(() {
                    _selectedTabIndex = index;
                  });
                },
              ),
              Expanded(
                child: _selectedTabIndex == 0
                    ? _buildPaymentsTab(context, l10n, bundle)
                    : _buildChargesTab(context, l10n, bundle),
              ),
            ],
          );
        },
      ),
    );
  }
}
