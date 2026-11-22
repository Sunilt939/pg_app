import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/format/dates.dart';
import '../../../../core/format/money.dart';
import '../../../../core/format/phone.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/key_value_row.dart';
import '../../../../core/widgets/ledger_row.dart';
import '../../../../core/widgets/ledger_sheet.dart';
import '../../../../core/widgets/money.dart';
import '../../../../core/widgets/room_tile.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../domain/charge_balance.dart';
import '../../domain/emergency_contact.dart';
import '../../domain/guest_list_item.dart';
import '../../domain/payment_feed_item.dart';
import '../providers/owner_provider.dart';

class OwnerGuestDetailScreen extends ConsumerWidget {
  final String stayId;

  const OwnerGuestDetailScreen({
    super.key,
    required this.stayId,
  });

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

  Future<void> _callPhone(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _shareInvite(
    BuildContext context,
    AppLocalizations l10n,
    GuestListItem guest,
  ) {
    final message = l10n.inviteMessage(
      guest.fullName ?? '',
      guest.pgName,
      AppConfig.appName,
    );
    final textToShare = AppConfig.playStoreUrl.isNotEmpty
        ? '$message\n\n${AppConfig.playStoreUrl}'
        : message;
    Share.share(textToShare);
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

  void _openAllChargesSheet(
    BuildContext context,
    AppLocalizations l10n,
    List<ChargeBalance> charges,
  ) {
    AppBottomSheet.show(
      context: context,
      builder: (context) => AppBottomSheet(
        title: l10n.allChargesTitle,
        child: ListView.builder(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          itemCount: charges.length,
          itemBuilder: (context, i) {
            final charge = charges[i];
            return _buildChargeRow(charge, i < charges.length - 1, l10n);
          },
        ),
      ),
    );
  }

  void _openAllPaymentsSheet(
    BuildContext context,
    AppLocalizations l10n,
    List<PaymentFeedItem> payments,
  ) {
    AppBottomSheet.show(
      context: context,
      builder: (context) => AppBottomSheet(
        title: l10n.allPaymentsTitle,
        child: ListView.builder(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          itemCount: payments.length,
          itemBuilder: (context, i) {
            final payment = payments[i];
            return _buildPaymentRow(payment, i < payments.length - 1, l10n);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final bundleAsync = ref.watch(guestDetailBundleProvider(stayId));

    return bundleAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.ground,
        appBar: AppTopBar.back(
          title: l10n.guestsTitle,
          onLeadingPressed: () => context.pop(),
        ),
        body: _buildLoadingSkeleton(),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: AppColors.ground,
        appBar: AppTopBar.back(
          title: l10n.guestsTitle,
          onLeadingPressed: () => context.pop(),
        ),
        body: ErrorState(
          title: l10n.errorGeneric,
          message: l10n.errorNetwork,
          onRetry: () => ref.refresh(guestDetailBundleProvider(stayId)),
        ),
      ),
      data: (bundle) {
        if (bundle == null) {
          return Scaffold(
            backgroundColor: AppColors.ground,
            appBar: AppTopBar.back(
              title: l10n.guestsTitle,
              onLeadingPressed: () => context.pop(),
            ),
            body: ErrorState(
              title: l10n.errorGeneric,
              message: l10n.errorNetwork,
              onRetry: () => ref.refresh(guestDetailBundleProvider(stayId)),
            ),
          );
        }

        final guest = bundle.guest;
        final guestTitle = (guest.fullName != null &&
                guest.fullName!.trim().isNotEmpty)
            ? guest.fullName!.trim()
            : guest.phone;

        return Scaffold(
          backgroundColor: AppColors.ground,
          appBar: AppTopBar.back(
            title: guestTitle,
            onLeadingPressed: () => context.pop(),
          ),
          body: RefreshIndicator(
            color: AppColors.petrol,
            onRefresh: () async {
              ref.invalidate(guestDetailBundleProvider(stayId));
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: AppSpace.x32),
              children: [
                _buildHeaderSheet(context, l10n, guest),
                _buildBalanceSheet(l10n, guest),
                if (bundle.charges.isNotEmpty)
                  _buildChargesSection(context, l10n, bundle.charges),
                if (bundle.payments.isNotEmpty)
                  _buildPaymentsSection(context, l10n, bundle.payments),
                _buildDetailsSection(
                  context,
                  l10n,
                  guest,
                  bundle.emergencyContact,
                  bundle.documentsCount,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: AppSpace.x12),
      children: const [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpace.x16,
            vertical: AppSpace.x12,
          ),
          child: Row(
            children: [
              SkeletonBlock(
                width: 44,
                height: 44,
                borderRadius: AppRadius.tile,
              ),
              SizedBox(width: AppSpace.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FractionallySizedBox(
                      widthFactor: 0.6,
                      child: SkeletonBlock(height: 16),
                    ),
                    SizedBox(height: AppSpace.x8),
                    FractionallySizedBox(
                      widthFactor: 0.4,
                      child: SkeletonBlock(height: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpace.x16),
        SkeletonList(itemCount: 4),
      ],
    );
  }

  Widget _buildHeaderSheet(
    BuildContext context,
    AppLocalizations l10n,
    GuestListItem guest,
  ) {
    final title = (guest.fullName != null && guest.fullName!.trim().isNotEmpty)
        ? guest.fullName!.trim()
        : guest.phone;
    final formattedPhone = PhoneFormat.format(guest.phone);

    String staySubtitle;
    if (guest.stayStatus == 'vacated') {
      if (guest.roomNumber != null && guest.bedLabel != null) {
        staySubtitle = l10n.guestDetailStayEnded(
          guest.roomNumber!,
          guest.bedLabel!,
          _formatDate(guest.joinDate),
          _formatDate(guest.leaveDate),
        );
      } else {
        staySubtitle = l10n.guestDetailStayNoBedEnded(
          _formatDate(guest.joinDate),
          _formatDate(guest.leaveDate),
        );
      }
    } else {
      if (guest.roomNumber != null && guest.bedLabel != null) {
        staySubtitle = l10n.guestDetailStay(
          guest.roomNumber!,
          guest.bedLabel!,
          _formatDate(guest.joinDate),
        );
      } else {
        staySubtitle = l10n.guestDetailStayNoBed(
          _formatDate(guest.joinDate),
        );
      }
    }

    StatusChip? chip;
    if (guest.stayStatus != 'vacated') {
      switch (guest.attentionState) {
        case 'overdue':
          chip = const StatusChip.overdue();
          break;
        case 'pending':
          chip = const StatusChip.pending();
          break;
        case 'due':
          chip = const StatusChip.due();
          break;
        case 'paid':
        default:
          chip = const StatusChip.paid();
          break;
      }
    }

    return LedgerSheet(
      padding: const EdgeInsets.all(AppSpace.x16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RoomTile(label: guest.roomNumber),
          const SizedBox(width: AppSpace.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppText.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (chip != null) ...[
                      const SizedBox(width: AppSpace.x8),
                      chip,
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        formattedPhone,
                        style: AppText.secondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _callPhone(guest.phone),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpace.x8),
                        child: const Icon(
                          AppIcons.phone,
                          size: 20,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  staySubtitle,
                  style: AppText.secondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceSheet(
    AppLocalizations l10n,
    GuestListItem guest,
  ) {
    final outstandingColor =
        guest.overduePaise > 0 ? AppColors.overdueFg : AppColors.ink;

    return LedgerSheet(
      padding: const EdgeInsets.all(AppSpace.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.balanceOutstanding,
            style: AppText.secondary,
          ),
          const SizedBox(height: AppSpace.x4),
          Money(
            paise: guest.outstandingPaise,
            style: AppText.display.copyWith(color: outstandingColor),
          ),
          const SizedBox(height: AppSpace.x16),
          Container(
            height: AppSize.hairline,
            color: AppColors.hairline,
          ),
          const SizedBox(height: AppSpace.x16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.balanceCharged, style: AppText.secondary),
                    const SizedBox(height: AppSpace.x4),
                    Money(paise: guest.chargedPaise, style: AppText.heading),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.balancePaid, style: AppText.secondary),
                    const SizedBox(height: AppSpace.x4),
                    Money(paise: guest.paidPaise, style: AppText.heading),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.balanceAdvance, style: AppText.secondary),
                    const SizedBox(height: AppSpace.x4),
                    Money(paise: guest.creditPaise, style: AppText.heading),
                  ],
                ),
              ),
            ],
          ),
          if (guest.pendingVerificationPaise > 0) ...[
            const SizedBox(height: AppSpace.x16),
            Container(
              padding: const EdgeInsets.all(AppSpace.x12),
              decoration: const BoxDecoration(
                color: AppColors.pendingBg,
                borderRadius: AppRadius.chip,
              ),
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
                      l10n.balanceWaiting(
                        MoneyFormat.format(guest.pendingVerificationPaise),
                      ),
                      style: AppText.secondary.copyWith(
                        color: AppColors.pendingFg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChargesSection(
    BuildContext context,
    AppLocalizations l10n,
    List<ChargeBalance> charges,
  ) {
    final chargesToShow = charges.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: l10n.detailCharges,
          trailing: charges.length > 6
              ? GestureDetector(
                  onTap: () => _openAllChargesSheet(context, l10n, charges),
                  child: Text(
                    l10n.detailSeeAll,
                    style:
                        AppText.buttonSmall.copyWith(color: AppColors.petrol),
                  ),
                )
              : null,
        ),
        LedgerSheet(
          margin: const EdgeInsets.only(bottom: AppSpace.x12),
          children: [
            for (int i = 0; i < chargesToShow.length; i++)
              _buildChargeRow(
                chargesToShow[i],
                i < chargesToShow.length - 1,
                l10n,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildChargeRow(
    ChargeBalance charge,
    bool showDivider,
    AppLocalizations l10n,
  ) {
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

    if (charge.status == 'void') {
      return LedgerRow(
        title: charge.description,
        subtitle: l10n.chargeDue(_formatDateShort(charge.dueDate)),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Money(
              paise: displayPaise,
              style: AppText.heading.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: AppSpace.x4),
            StatusChip(
              kind: statusKind,
              label: statusLabel,
            ),
          ],
        ),
        showDivider: showDivider,
      );
    }

    return LedgerRow(
      title: charge.description,
      subtitle: l10n.chargeDue(_formatDateShort(charge.dueDate)),
      paise: displayPaise,
      statusKind: statusKind,
      statusLabel: statusLabel,
      showDivider: showDivider,
    );
  }

  Widget _buildPaymentsSection(
    BuildContext context,
    AppLocalizations l10n,
    List<PaymentFeedItem> payments,
  ) {
    final paymentsToShow = payments.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: l10n.detailPayments,
          trailing: payments.length > 6
              ? GestureDetector(
                  onTap: () => _openAllPaymentsSheet(context, l10n, payments),
                  child: Text(
                    l10n.detailSeeAll,
                    style:
                        AppText.buttonSmall.copyWith(color: AppColors.petrol),
                  ),
                )
              : null,
        ),
        LedgerSheet(
          margin: const EdgeInsets.only(bottom: AppSpace.x12),
          children: [
            for (int i = 0; i < paymentsToShow.length; i++)
              _buildPaymentRow(
                paymentsToShow[i],
                i < paymentsToShow.length - 1,
                l10n,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentRow(
    PaymentFeedItem payment,
    bool showDivider,
    AppLocalizations l10n,
  ) {
    final title = (payment.payerAppLabel != null &&
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

    return LedgerRow(
      leading: RoomTile(icon: _paymentMethodIcon(payment.methodCode)),
      title: title,
      subtitle: _formatDate(payment.paidOn),
      paise: payment.amountPaise,
      statusKind: statusKind,
      statusLabel: statusLabel,
      showDivider: showDivider,
    );
  }

  Widget _buildDetailsSection(
    BuildContext context,
    AppLocalizations l10n,
    GuestListItem guest,
    EmergencyContact? emergencyContact,
    int documentsCount,
  ) {
    final isOpenStay = guest.stayStatus != 'vacated';

    String emergencyValue;
    if (emergencyContact != null) {
      if (emergencyContact.relationship != null &&
          emergencyContact.relationship!.isNotEmpty) {
        emergencyValue =
            '${emergencyContact.name} (${emergencyContact.relationship})';
      } else {
        emergencyValue = emergencyContact.name;
      }
    } else {
      emergencyValue = l10n.detailNone;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.detailDetails),
        LedgerSheet(
          children: [
            KeyValueRow(
              label: l10n.guestRent,
              value: MoneyFormat.format(guest.monthlyRentPaise ?? 0),
            ),
            KeyValueRow(
              label: l10n.guestBillingDay,
              value: l10n.profileDueDay(guest.billingDay.toString()),
            ),
            KeyValueRow(
              label: l10n.guestJoinDate,
              value: _formatDate(guest.joinDate),
            ),
            KeyValueRow(
              label: l10n.detailApp,
              value: guest.hasSignedIn
                  ? l10n.detailAppSignedIn
                  : l10n.detailAppNotYet,
              showDivider: isOpenStay,
              customValueWidget: guest.hasSignedIn
                  ? null
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.detailAppNotYet,
                          style: AppText.body,
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: AppSpace.x4),
                        GestureDetector(
                          onTap: () => _shareInvite(context, l10n, guest),
                          behavior: HitTestBehavior.opaque,
                          child: Text(
                            l10n.detailInviteAgain,
                            style: AppText.buttonSmall
                                .copyWith(color: AppColors.petrol),
                          ),
                        ),
                      ],
                    ),
            ),
            if (isOpenStay) ...[
              KeyValueRow(
                label: l10n.detailEmergency,
                value: emergencyValue,
                onTap: emergencyContact != null
                    ? () => _callPhone(emergencyContact.phone)
                    : null,
                trailing: emergencyContact != null
                    ? const Icon(
                        AppIcons.phone,
                        size: 16,
                        color: AppColors.petrol,
                      )
                    : null,
              ),
              KeyValueRow(
                label: l10n.detailDocuments,
                value: documentsCount > 0
                    ? l10n.detailDocumentsCount(documentsCount)
                    : l10n.detailNone,
                showDivider: false,
              ),
            ],
          ],
        ),
      ],
    );
  }
}
