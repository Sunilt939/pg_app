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
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snack.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/date_field.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/key_value_row.dart';
import '../../../../core/widgets/ledger_row.dart';
import '../../../../core/widgets/ledger_sheet.dart';
import '../../../../core/widgets/money.dart';
import '../../../../core/widgets/money_field.dart';
import '../../../../core/widgets/option_sheet.dart';
import '../../../../core/widgets/room_tile.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/select_field.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/owner_repository.dart';
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
    WidgetRef ref,
    AppLocalizations l10n,
    List<ChargeBalance> charges,
    bool isOwnerOrManager,
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
            return _buildChargeRow(
              context,
              ref,
              l10n,
              charge,
              i < charges.length - 1,
              isOwnerOrManager,
            );
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

        final activePg = ref.watch(activePgProvider);
        final isOwnerOrManager =
            activePg?.role == 'owner' || activePg?.role == 'manager';

        return Scaffold(
          backgroundColor: AppColors.ground,
          appBar: AppTopBar.back(
            title: guestTitle,
            onLeadingPressed: () => context.pop(),
            actions: [
              if (isOwnerOrManager)
                IconButton(
                  icon: const Icon(
                    AppIcons.more,
                    size: 24,
                    color: AppColors.ink,
                  ),
                  onPressed: () => _openActionsSheet(context, ref, l10n, guest),
                ),
            ],
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
                  _buildChargesSection(
                    context,
                    ref,
                    l10n,
                    bundle.charges,
                    isOwnerOrManager,
                  ),
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
    WidgetRef ref,
    AppLocalizations l10n,
    List<ChargeBalance> charges,
    bool isOwnerOrManager,
  ) {
    final chargesToShow = charges.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: l10n.detailCharges,
          trailing: charges.length > 6
              ? GestureDetector(
                  onTap: () => _openAllChargesSheet(
                    context,
                    ref,
                    l10n,
                    charges,
                    isOwnerOrManager,
                  ),
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
                context,
                ref,
                l10n,
                chargesToShow[i],
                i < chargesToShow.length - 1,
                isOwnerOrManager,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildChargeRow(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    ChargeBalance charge,
    bool showDivider,
    bool isOwnerOrManager,
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
        onTap: () => _openChargeDetailSheet(
          context,
          ref,
          l10n,
          charge,
          isOwnerOrManager,
        ),
      );
    }

    return LedgerRow(
      title: charge.description,
      subtitle: l10n.chargeDue(_formatDateShort(charge.dueDate)),
      paise: displayPaise,
      statusKind: statusKind,
      statusLabel: statusLabel,
      showDivider: showDivider,
      onTap: () => _openChargeDetailSheet(
        context,
        ref,
        l10n,
        charge,
        isOwnerOrManager,
      ),
    );
  }

  void _openChargeDetailSheet(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    ChargeBalance charge,
    bool isOwnerOrManager,
  ) {
    final canCancel = isOwnerOrManager &&
        charge.status != 'paid' &&
        charge.status != 'void';

    AppBottomSheet.show(
      context: context,
      builder: (sheetContext) => AppBottomSheet(
        title: charge.description,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LedgerSheet(
              margin: EdgeInsets.zero,
              children: [
                KeyValueRow(
                  label: l10n.chargeAmount,
                  value: MoneyFormat.format(charge.amountPaise),
                ),
                KeyValueRow(
                  label: l10n.chargeDueDate,
                  value: _formatDate(charge.dueDate),
                ),
                if (charge.paidPaise > 0)
                  KeyValueRow(
                    label: l10n.balancePaid,
                    value: MoneyFormat.format(charge.paidPaise),
                  ),
                if (charge.outstandingPaise > 0)
                  KeyValueRow(
                    label: l10n.balanceOutstanding,
                    value: MoneyFormat.format(charge.outstandingPaise),
                  ),
              ],
            ),
            if (canCancel) ...[
              const SizedBox(height: AppSpace.x16),
              AppButton.text(
                label: l10n.chargeCancelAction,
                textColor: AppColors.overdueFg,
                expand: true,
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  _openCancelChargeConfirmSheet(context, ref, l10n, charge);
                },
              ),
            ],
            const SizedBox(height: AppSpace.x8),
          ],
        ),
      ),
    );
  }

  Future<void> _openCancelChargeConfirmSheet(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    ChargeBalance charge,
  ) async {
    final cancelled = await ConfirmSheet.show(
      context: context,
      title: l10n.chargeCancelTitle,
      body: '',
      showReasonField: true,
      isReasonRequired: true,
      reasonLabel: l10n.chargeCancelReason,
      reasonError: l10n.errChargeReason,
      confirmLabel: l10n.chargeCancelAction,
      isDestructive: true,
      onConfirm: (reason) async {
        await ref.read(ownerRepositoryProvider).voidCharge(
              chargeId: charge.chargeId,
              reason: reason,
            );
      },
    );

    if (cancelled == true && context.mounted) {
      AppSnack.show(context, message: l10n.chargeCancelledToast);
      ref.invalidate(guestDetailBundleProvider(stayId));
    }
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

  void _openActionsSheet(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    GuestListItem guest,
  ) {
    final isOpenStay = guest.stayStatus != 'vacated';
    final canCorrectName = !guest.hasSignedIn && isOpenStay;

    AppBottomSheet.show(
      context: context,
      builder: (sheetContext) => AppBottomSheet(
        child: LedgerSheet(
          margin: EdgeInsets.zero,
          children: [
            if (isOpenStay)
              LedgerRow(
                title: l10n.actionChangeRent,
                titleStyle: AppText.body,
                minHeight: 56,
                showDivider: true,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openChangeRentSheet(context, ref, l10n, guest);
                },
              ),
            LedgerRow(
              title: l10n.actionAddCharge,
              titleStyle: AppText.body,
              minHeight: 56,
              showDivider: isOpenStay,
              onTap: () {
                Navigator.of(sheetContext).pop();
                _openAddChargeSheet(context, ref, l10n, guest);
              },
            ),
            if (canCorrectName)
              LedgerRow(
                title: l10n.actionCorrectName,
                titleStyle: AppText.body,
                minHeight: 56,
                showDivider: true,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openCorrectNameSheet(context, ref, l10n, guest);
                },
              ),
            if (isOpenStay)
              LedgerRow(
                title: l10n.actionVacate,
                titleStyle: AppText.body.copyWith(color: AppColors.overdueFg),
                minHeight: 56,
                showDivider: false,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openVacateSheet(context, ref, l10n, guest);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _openChangeRentSheet(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    GuestListItem guest,
  ) {
    AppBottomSheet.show(
      context: context,
      builder: (context) => _ChangeRentSheet(guest: guest),
    );
  }

  void _openAddChargeSheet(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    GuestListItem guest,
  ) {
    AppBottomSheet.show(
      context: context,
      builder: (context) => _AddChargeSheet(guest: guest),
    );
  }

  void _openCorrectNameSheet(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    GuestListItem guest,
  ) {
    AppBottomSheet.show(
      context: context,
      builder: (context) => _CorrectNameSheet(guest: guest),
    );
  }

  Future<void> _openVacateSheet(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    GuestListItem guest,
  ) async {
    final vacated = await AppBottomSheet.show<bool>(
      context: context,
      builder: (sheetContext) => _VacateSheet(guest: guest),
    );

    if (vacated == true && context.mounted) {
      AppSnack.show(
        context,
        message: l10n.vacatedToast(guest.fullName ?? ''),
      );
      context.pop();
    }
  }
}

class _ChangeRentSheet extends ConsumerStatefulWidget {
  final GuestListItem guest;

  const _ChangeRentSheet({required this.guest});

  @override
  ConsumerState<_ChangeRentSheet> createState() => _ChangeRentSheetState();
}

class _ChangeRentSheetState extends ConsumerState<_ChangeRentSheet> {
  late int _rentPaise;
  late DateTime _effectiveFrom;
  String? _rentError;
  String? _dateError;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _rentPaise = widget.guest.monthlyRentPaise ?? 0;
    _effectiveFrom = DateTime.now();
  }

  Future<void> _submit(AppLocalizations l10n) async {
    if (_rentPaise <= 0) {
      setState(() => _rentError = l10n.errRent);
      return;
    }

    setState(() {
      _isLoading = true;
      _rentError = null;
      _dateError = null;
    });

    try {
      await ref.read(ownerRepositoryProvider).setStayRent(
            stayId: widget.guest.stayId,
            monthlyRentPaise: _rentPaise,
            effectiveFrom: _effectiveFrom,
          );
      if (mounted) {
        Navigator.of(context).pop();
        AppSnack.show(context, message: l10n.rentChanged);
        ref.invalidate(guestDetailBundleProvider(widget.guest.stayId));
      }
    } on DuplicateRentDateException {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _dateError = l10n.errRentDate;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnack.show(
          context,
          message: e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppBottomSheet(
      title: l10n.actionChangeRent,
      bottomAction: AppButton.primary(
        label: l10n.rentChangeAction,
        loading: _isLoading,
        expand: true,
        onPressed: () => _submit(l10n),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpace.x8),
          MoneyField(
            label: l10n.rentNew,
            initialPaise: _rentPaise,
            errorText: _rentError,
            onChanged: (val) {
              _rentPaise = val;
              if (_rentError != null && val > 0) {
                setState(() => _rentError = null);
              }
            },
          ),
          const SizedBox(height: AppSpace.x16),
          DateField(
            label: l10n.rentFrom,
            value: _effectiveFrom,
            helperText: _dateError == null ? l10n.rentChangeHelper : null,
            errorText: _dateError,
            onChanged: (newDate) {
              setState(() {
                _effectiveFrom = newDate;
                _dateError = null;
              });
            },
          ),
          const SizedBox(height: AppSpace.x24),
        ],
      ),
    );
  }
}

class _AddChargeSheet extends ConsumerStatefulWidget {
  final GuestListItem guest;

  const _AddChargeSheet({required this.guest});

  @override
  ConsumerState<_AddChargeSheet> createState() => _AddChargeSheetState();
}

class _AddChargeSheetState extends ConsumerState<_AddChargeSheet> {
  ChargeType? _selectedChargeType;
  int _amountPaise = 0;
  late DateTime _dueDate;
  final TextEditingController _noteController = TextEditingController();
  String? _typeError;
  String? _amountError;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _dueDate = DateTime.now();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickChargeType(
    BuildContext context,
    AppLocalizations l10n,
    List<ChargeType> chargeTypes,
  ) async {
    final chosen = await OptionSheet.show<ChargeType>(
      context: context,
      title: l10n.chargeType,
      options: [
        for (final ct in chargeTypes)
          OptionSheetItem(
            value: ct,
            title: ct.label,
          ),
      ],
      selectedValue: _selectedChargeType,
    );

    if (chosen != null) {
      setState(() {
        _selectedChargeType = chosen;
        _typeError = null;
      });
    }
  }

  Future<void> _submit(AppLocalizations l10n) async {
    bool hasError = false;

    if (_selectedChargeType == null) {
      setState(() => _typeError = l10n.errChargeType);
      hasError = true;
    }
    if (_amountPaise <= 0) {
      setState(() => _amountError = l10n.errChargeAmount);
      hasError = true;
    }

    if (hasError) return;

    setState(() {
      _isLoading = true;
      _typeError = null;
      _amountError = null;
    });

    try {
      final chargeType = _selectedChargeType!;
      DateTime? periodMonth;
      if (chargeType.code != 'security_deposit') {
        periodMonth = DateTime(_dueDate.year, _dueDate.month, 1);
      }

      final note = _noteController.text.trim();
      final description = note.isNotEmpty ? note : chargeType.label;

      await ref.read(ownerRepositoryProvider).addCharge(
            stayId: widget.guest.stayId,
            chargeTypeCode: chargeType.code,
            amountPaise: _amountPaise,
            dueDate: _dueDate,
            description: description,
            periodMonth: periodMonth,
          );

      if (mounted) {
        Navigator.of(context).pop();
        AppSnack.show(context, message: l10n.chargeAdded);
        ref.invalidate(guestDetailBundleProvider(widget.guest.stayId));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnack.show(
          context,
          message: e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final chargeTypesAsync = ref.watch(chargeTypesProvider);
    final chargeTypes = chargeTypesAsync.valueOrNull ?? [];

    return AppBottomSheet(
      title: l10n.actionAddCharge,
      bottomAction: AppButton.primary(
        label: l10n.chargeAddAction,
        loading: _isLoading,
        expand: true,
        onPressed: () => _submit(l10n),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpace.x8),
          SelectField(
            label: l10n.chargeType,
            value: _selectedChargeType?.label ?? '',
            hint: l10n.chargeType,
            errorText: _typeError,
            onTap: () => _pickChargeType(context, l10n, chargeTypes),
          ),
          const SizedBox(height: AppSpace.x16),
          MoneyField(
            label: l10n.chargeAmount,
            errorText: _amountError,
            onChanged: (val) {
              _amountPaise = val;
              if (_amountError != null && val > 0) {
                setState(() => _amountError = null);
              }
            },
          ),
          const SizedBox(height: AppSpace.x16),
          DateField(
            label: l10n.chargeDueDate,
            value: _dueDate,
            onChanged: (newDate) {
              setState(() => _dueDate = newDate);
            },
          ),
          const SizedBox(height: AppSpace.x16),
          AppTextField(
            label: l10n.chargeNote,
            controller: _noteController,
          ),
          const SizedBox(height: AppSpace.x24),
        ],
      ),
    );
  }
}

class _CorrectNameSheet extends ConsumerStatefulWidget {
  final GuestListItem guest;

  const _CorrectNameSheet({required this.guest});

  @override
  ConsumerState<_CorrectNameSheet> createState() => _CorrectNameSheetState();
}

class _CorrectNameSheetState extends ConsumerState<_CorrectNameSheet> {
  late final TextEditingController _nameController;
  String? _nameError;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.guest.fullName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit(AppLocalizations l10n) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = l10n.errGuestName);
      return;
    }

    setState(() {
      _isLoading = true;
      _nameError = null;
    });

    try {
      await ref.read(ownerRepositoryProvider).correctGuestName(
            personId: widget.guest.personId,
            fullName: name,
          );
      if (mounted) {
        Navigator.of(context).pop();
        AppSnack.show(context, message: l10n.nameCorrected);
        ref.invalidate(guestDetailBundleProvider(widget.guest.stayId));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnack.show(
          context,
          message: e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppBottomSheet(
      title: l10n.actionCorrectName,
      bottomAction: AppButton.primary(
        label: l10n.actionSave,
        loading: _isLoading,
        expand: true,
        onPressed: () => _submit(l10n),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpace.x8),
          AppTextField(
            label: l10n.guestName,
            controller: _nameController,
            errorText: _nameError,
            onChanged: (val) {
              if (_nameError != null && val.trim().isNotEmpty) {
                setState(() => _nameError = null);
              }
            },
          ),
          const SizedBox(height: AppSpace.x24),
        ],
      ),
    );
  }
}

class _VacateSheet extends ConsumerStatefulWidget {
  final GuestListItem guest;

  const _VacateSheet({required this.guest});

  @override
  ConsumerState<_VacateSheet> createState() => _VacateSheetState();
}

class _VacateSheetState extends ConsumerState<_VacateSheet> {
  late DateTime _leaveDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _leaveDate = DateTime.now();
  }

  Future<void> _submit(AppLocalizations l10n) async {
    setState(() => _isLoading = true);

    try {
      await ref.read(ownerRepositoryProvider).vacateStay(
            stayId: widget.guest.stayId,
            leaveDate: _leaveDate,
          );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnack.show(
          context,
          message: e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final guestName = widget.guest.fullName ?? '';
    final bodyText = widget.guest.outstandingPaise > 0
        ? l10n.vacateBodyOwes(
            guestName,
            MoneyFormat.format(widget.guest.outstandingPaise),
          )
        : l10n.vacateBody;

    return AppBottomSheet(
      title: l10n.vacateTitle(guestName),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpace.x8),
          DateField(
            label: l10n.vacateLeaving,
            value: _leaveDate,
            onChanged: (newDate) {
              setState(() => _leaveDate = newDate);
            },
          ),
          const SizedBox(height: AppSpace.x16),
          Text(
            bodyText,
            style: AppText.body,
          ),
          const SizedBox(height: AppSpace.x24),
          AppButton.destructive(
            label: l10n.actionVacate,
            loading: _isLoading,
            expand: true,
            onPressed: () => _submit(l10n),
          ),
          const SizedBox(height: AppSpace.x12),
          AppButton.secondary(
            label: l10n.actionCancel,
            expand: true,
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: AppSpace.x8),
        ],
      ),
    );
  }
}
