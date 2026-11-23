import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/format/dates.dart';
import '../../../../core/format/money.dart';
import '../../../../core/format/phone.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/key_value_row.dart';
import '../../../../core/widgets/ledger_row.dart';
import '../../../../core/widgets/ledger_sheet.dart';
import '../../../../core/widgets/money.dart';
import '../../../../core/widgets/room_tile.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../owner/domain/charge_balance.dart';
import '../../../owner/domain/guest_list_item.dart';
import '../../../owner/domain/payment_feed_item.dart';
import '../providers/guest_provider.dart';
import '../widgets/guest_report_payment_sheet.dart';

sealed class _ActivityItem {
  DateTime get date;
}

class _ChargeActivityItem extends _ActivityItem {
  final ChargeBalance charge;
  _ChargeActivityItem(this.charge);

  @override
  DateTime get date =>
      DateTime.tryParse(charge.dueDate) ?? DateTime(2000);
}

class _PaymentActivityItem extends _ActivityItem {
  final PaymentFeedItem payment;
  _PaymentActivityItem(this.payment);

  @override
  DateTime get date =>
      DateTime.tryParse(payment.paidOn) ?? DateTime(2000);
}

class GuestHomeScreen extends ConsumerWidget {
  const GuestHomeScreen({super.key});

  IconData _paymentMethodIcon(String methodCode) {
    switch (methodCode) {
      case 'upi':
        return AppIcons.upi;
      case 'bank_transfer':
        return AppIcons.bank;
      case 'cash':
      case 'cheque':
      default:
        return AppIcons.cash;
    }
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  String _formatDateString(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '';
    final dt = DateTime.tryParse(isoDate);
    if (dt == null) return isoDate;
    return formatDate(dt);
  }

  Widget _buildLoadingSkeleton() {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpace.x16),
      children: const [
        LedgerSheet(
          padding: EdgeInsets.all(AppSpace.x16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBlock(height: 16, width: 140),
              SizedBox(height: AppSpace.x8),
              SkeletonBlock(height: 36, width: 180),
              SizedBox(height: AppSpace.x16),
              SkeletonBlock(height: 48),
            ],
          ),
        ),
        SizedBox(height: AppSpace.x16),
        SkeletonList(itemCount: 4),
      ],
    );
  }

  Widget _buildRentSheet(
    BuildContext context,
    AppLocalizations l10n,
    GuestListItem stay,
  ) {
    final overduePaise = stay.overduePaise;
    final dueNowPaise = stay.dueNowPaise ?? 0;
    final nextDuePaise = stay.nextDuePaise ?? 0;
    final pendingPaise = stay.pendingVerificationPaise;

    final payAmount = overduePaise > 0
        ? (dueNowPaise > 0 ? dueNowPaise : overduePaise)
        : (dueNowPaise > 0
            ? dueNowPaise
            : (nextDuePaise > 0 ? nextDuePaise : 0));

    Widget stateContent;

    if (overduePaise > 0) {
      final dateStr = _formatDateString(stay.oldestUnpaidDueDate);
      stateContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.rentOverdueSince(dateStr),
            style: AppText.sectionHeader.copyWith(
              color: AppColors.overdueFg,
            ),
          ),
          const SizedBox(height: AppSpace.x4),
          Money(
            paise: dueNowPaise > 0 ? dueNowPaise : overduePaise,
            style: AppText.display,
            color: AppColors.overdueFg,
          ),
        ],
      );
    } else if (dueNowPaise > 0) {
      stateContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.rentDueNow,
            style: AppText.sectionHeader.copyWith(
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpace.x4),
          Money(
            paise: dueNowPaise,
            style: AppText.display,
            color: AppColors.ink,
          ),
        ],
      );
    } else if (nextDuePaise > 0) {
      final nextDateStr = _formatDateString(stay.nextDueDate);
      stateContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.rentNextDue(nextDateStr),
            style: AppText.secondary,
          ),
          const SizedBox(height: AppSpace.x4),
          Money(
            paise: nextDuePaise,
            style: AppText.display,
            color: AppColors.ink,
          ),
        ],
      );
    } else {
      stateContent = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            AppIcons.check,
            size: 28,
            color: AppColors.paidFg,
          ),
          const SizedBox(width: AppSpace.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.rentPaidUp,
                  style: AppText.title,
                ),
                const SizedBox(height: AppSpace.x4),
                Text(
                  l10n.rentPaidUpBody,
                  style: AppText.secondary,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return LedgerSheet(
      padding: const EdgeInsets.all(AppSpace.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          stateContent,
          if (pendingPaise > 0) ...[
            const SizedBox(height: AppSpace.x12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.pendingBg,
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.all(AppSpace.x12),
              child: Row(
                children: [
                  const Icon(
                    AppIcons.clock,
                    size: 20,
                    color: AppColors.pendingFg,
                  ),
                  const SizedBox(width: AppSpace.x8),
                  Expanded(
                    child: Text(
                      l10n.rentWaiting(MoneyFormat.format(pendingPaise)),
                      style: AppText.secondary.copyWith(
                        color: AppColors.pendingFg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (payAmount > 0) ...[
            const SizedBox(height: AppSpace.x12),
            AppButton.primary(
              label: l10n.payAction(MoneyFormat.format(payAmount)),
              expand: true,
              onPressed: () {
                context.push('/guest/pay/${stay.stayId}', extra: payAmount);
              },
            ),
            const SizedBox(height: AppSpace.x8),
            Center(
              child: AppButton.text(
                label: l10n.alreadyPaid,
                onPressed: () {
                  GuestReportPaymentSheet.showVariantB(
                    context: context,
                    stayId: stay.stayId,
                    pgId: stay.pgId,
                    defaultAmountPaise: payAmount,
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildYourStaySheet(
    AppLocalizations l10n,
    GuestListItem stay,
  ) {
    String? roomBedValue;
    if (stay.roomNumber != null && stay.roomNumber!.isNotEmpty) {
      if (stay.bedLabel != null && stay.bedLabel!.isNotEmpty) {
        roomBedValue = 'Room ${stay.roomNumber}, bed ${stay.bedLabel}';
      } else {
        roomBedValue = 'Room ${stay.roomNumber}';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.homeYourStay),
        LedgerSheet(
          children: [
            KeyValueRow(
              label: l10n.guestRent,
              value: MoneyFormat.format(stay.monthlyRentPaise ?? 0),
            ),
            KeyValueRow(
              label: l10n.profileDueLabel,
              value: l10n.profileDueDay(stay.billingDay.toString()),
            ),
            if (stay.creditPaise > 0)
              KeyValueRow(
                label: l10n.homeAdvanceBalance,
                value: MoneyFormat.format(stay.creditPaise),
              ),
            if (roomBedValue != null)
              KeyValueRow(
                label: l10n.receiptRoom,
                value: roomBedValue,
                showDivider: false,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection(
    BuildContext context,
    AppLocalizations l10n,
    List<ChargeBalance> charges,
    List<PaymentFeedItem> payments,
  ) {
    final activityItems = <_ActivityItem>[
      ...charges.map(_ChargeActivityItem.new),
      ...payments.map(_PaymentActivityItem.new),
    ]..sort((a, b) => b.date.compareTo(a.date));

    final itemsToShow = activityItems.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.homeRecent),
        if (itemsToShow.isEmpty)
          LedgerSheet(
            padding: const EdgeInsets.all(AppSpace.x24),
            child: Center(
              child: Text(
                l10n.homeNoActivity,
                style: AppText.secondary,
              ),
            ),
          )
        else
          LedgerSheet(
            margin: const EdgeInsets.only(bottom: AppSpace.x12),
            children: [
              for (int i = 0; i < itemsToShow.length; i++)
                _buildActivityRow(
                  context,
                  l10n,
                  itemsToShow[i],
                  i < itemsToShow.length - 1,
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildActivityRow(
    BuildContext context,
    AppLocalizations l10n,
    _ActivityItem item,
    bool showDivider,
  ) {
    if (item is _ChargeActivityItem) {
      final charge = item.charge;
      final displayPaise = charge.status == 'paid'
          ? charge.amountPaise
          : charge.outstandingPaise;

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

      final dateFormatted = _formatDateString(charge.dueDate);

      return LedgerRow(
        title: charge.description,
        subtitle: l10n.chargeDue(dateFormatted),
        paise: displayPaise,
        statusKind: statusKind,
        statusLabel: statusLabel,
        showDivider: showDivider,
      );
    } else if (item is _PaymentActivityItem) {
      final payment = item.payment;
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
        onTap: payment.receiptId != null
            ? () => context.push('/receipt/${payment.paymentId}')
            : null,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildYourPgSheet(
    AppLocalizations l10n,
    GuestListItem stay,
  ) {
    final phone = stay.pgContactPhone;
    if (phone == null || phone.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.homeYourPg),
        LedgerSheet(
          padding: const EdgeInsets.all(AppSpace.x16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.callPg(stay.pgName),
                      style: AppText.bodyMedium,
                    ),
                    const SizedBox(height: AppSpace.x4),
                    Text(
                      PhoneFormat.format(phone),
                      style: AppText.secondary,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  AppIcons.phone,
                  size: 24,
                  color: AppColors.petrol,
                ),
                onPressed: () => _callPhone(phone),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final bundleAsync = ref.watch(guestHomeBundleProvider);

    return Scaffold(
      backgroundColor: AppColors.ground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: bundleAsync.when(
          loading: () => AppBar(
            backgroundColor: AppColors.ground,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: const Text(AppConfig.appName, style: AppText.title),
          ),
          error: (_, __) => AppBar(
            backgroundColor: AppColors.ground,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: const Text(AppConfig.appName, style: AppText.title),
          ),
          data: (bundle) {
            final title = bundle.currentStay?.pgName ??
                bundle.latestPastStay?.pgName ??
                AppConfig.appName;
            return AppBar(
              backgroundColor: AppColors.ground,
              elevation: 0,
              scrolledUnderElevation: 0,
              title: Text(title, style: AppText.title),
            );
          },
        ),
      ),
      body: bundleAsync.when(
        loading: () => _buildLoadingSkeleton(),
        error: (error, _) => ErrorState(
          title: l10n.errorGeneric,
          message: error.toString(),
          onRetry: () => ref.invalidate(guestHomeBundleProvider),
        ),
        data: (bundle) {
          final currentStay = bundle.currentStay;

          if (currentStay == null) {
            final pastStay = bundle.latestPastStay;
            final pgName = pastStay?.pgName ?? AppConfig.appName;

            return RefreshIndicator(
              color: AppColors.petrol,
              onRefresh: () async => ref.invalidate(guestHomeBundleProvider),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpace.x16),
                children: [
                  const SizedBox(height: AppSpace.x32),
                  EmptyState(
                    icon: AppIcons.home,
                    title: l10n.noStayTitle,
                    body: l10n.noStayBody(pgName),
                  ),
                  if (pastStay != null && pastStay.outstandingPaise > 0) ...[
                    const SizedBox(height: AppSpace.x16),
                    Center(
                      child: Text(
                        l10n.noStayOwes(
                          pastStay.pgName,
                          MoneyFormat.format(pastStay.outstandingPaise),
                        ),
                        style: AppText.secondary,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (pastStay.pgContactPhone != null &&
                        pastStay.pgContactPhone!.isNotEmpty) ...[
                      const SizedBox(height: AppSpace.x24),
                      _buildYourPgSheet(l10n, pastStay),
                    ],
                  ],
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.petrol,
            onRefresh: () async => ref.invalidate(guestHomeBundleProvider),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(
                left: AppSpace.x16,
                right: AppSpace.x16,
                top: AppSpace.x12,
                bottom: AppSpace.x32,
              ),
              children: [
                _buildRentSheet(context, l10n, currentStay),
                const SizedBox(height: AppSpace.x16),
                _buildYourStaySheet(l10n, currentStay),
                const SizedBox(height: AppSpace.x16),
                _buildRecentActivitySection(
                  context,
                  l10n,
                  bundle.charges,
                  bundle.payments,
                ),
                if (currentStay.pgContactPhone != null &&
                    currentStay.pgContactPhone!.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.x16),
                  _buildYourPgSheet(l10n, currentStay),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
