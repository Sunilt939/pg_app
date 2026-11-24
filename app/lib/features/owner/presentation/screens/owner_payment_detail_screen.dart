import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/format/dates.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snack.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/key_value_row.dart';
import '../../../../core/widgets/ledger_sheet.dart';
import '../../../../core/widgets/money.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/owner_provider.dart';
import '../widgets/confirm_payment_sheet.dart';
import '../widgets/reject_payment_sheet.dart';
import '../widgets/reverse_payment_sheet.dart';

class OwnerPaymentDetailScreen extends ConsumerWidget {
  final String paymentId;

  const OwnerPaymentDetailScreen({
    super.key,
    required this.paymentId,
  });

  Widget _buildStatusChip(String status, AppLocalizations l10n) {
    switch (status) {
      case 'confirmed':
        return StatusChip.paid(label: l10n.statusConfirmed);
      case 'rejected':
        return StatusChip.overdue(label: l10n.statusRejected);
      case 'reversed':
        return StatusChip.overdue(label: l10n.statusReversed);
      case 'pending':
      default:
        return const StatusChip.pending();
    }
  }

  void _openFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, _, __) {
          return Scaffold(
            backgroundColor: AppColors.ink,
            body: SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: InteractiveViewer(
                      panEnabled: true,
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Positioned(
                    top: AppSpace.x16,
                    right: AppSpace.x16,
                    child: IconButton(
                      icon: const Icon(
                        AppIcons.close,
                        color: AppColors.surface,
                        size: 24,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScreenshotRow(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    String screenshotFileId,
  ) {
    final signedUrlAsync = ref.watch(signedFileUrlProvider(screenshotFileId));

    return Container(
      constraints: const BoxConstraints(minHeight: AppSize.button),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.x16,
        vertical: AppSpace.x12,
      ),
      color: AppColors.surface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              l10n.detailScreenshot,
              style: AppText.secondary,
            ),
          ),
          const SizedBox(width: AppSpace.x12),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: signedUrlAsync.when(
                loading: () => const SkeletonBlock(
                  width: 96,
                  height: 96,
                  borderRadius: BorderRadius.all(Radius.circular(6)),
                ),
                error: (_, __) => Text(
                  l10n.screenshotFailed,
                  style: AppText.secondary,
                  textAlign: TextAlign.right,
                ),
                data: (signedUrl) {
                  if (signedUrl == null) {
                    return Text(
                      l10n.screenshotFailed,
                      style: AppText.secondary,
                      textAlign: TextAlign.right,
                    );
                  }
                  return GestureDetector(
                    onTap: () => _openFullScreenImage(context, signedUrl),
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.hairline,
                          width: 1.0,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.network(
                        signedUrl,
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(
                            l10n.screenshotFailed,
                            style: AppText.secondary,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final paymentAsync = ref.watch(paymentDetailProvider(paymentId));

    return paymentAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.ground,
        appBar: AppTopBar.back(
          title: l10n.paymentTitle,
          onLeadingPressed: () => context.pop(),
        ),
        body: const Padding(
          padding: EdgeInsets.all(AppSpace.x16),
          child: Column(
            children: [
              SkeletonBlock(height: 80, borderRadius: AppRadius.control),
              SizedBox(height: AppSpace.x16),
              SkeletonBlock(height: 240, borderRadius: AppRadius.control),
            ],
          ),
        ),
      ),
      error: (_, __) => Scaffold(
        backgroundColor: AppColors.ground,
        appBar: AppTopBar.back(
          title: l10n.paymentTitle,
          onLeadingPressed: () => context.pop(),
        ),
        body: ErrorState(
          title: l10n.errorGeneric,
          message: l10n.errorNetwork,
          onRetry: () => ref.refresh(paymentDetailProvider(paymentId)),
        ),
      ),
      data: (payment) {
        if (payment == null) {
          return Scaffold(
            backgroundColor: AppColors.ground,
            appBar: AppTopBar.back(
              title: l10n.paymentTitle,
              onLeadingPressed: () => context.pop(),
            ),
            body: ErrorState(
              title: l10n.errorGeneric,
              message: l10n.errorNetwork,
              onRetry: () => ref.refresh(paymentDetailProvider(paymentId)),
            ),
          );
        }

        final activePg = ref.watch(activePgProvider);
        final isOwnerOrManager =
            activePg?.role == 'owner' || activePg?.role == 'manager';

        // Format dates
        String? formattedPaidOn;
        if (payment.paidOn.isNotEmpty) {
          final paidOnDt = DateTime.tryParse(payment.paidOn);
          formattedPaidOn = paidOnDt != null
              ? DateFormat.formatDate(paidOnDt)
              : payment.paidOn;
        }

        String? formattedReported;
        if (payment.createdAt != null && payment.createdAt!.isNotEmpty) {
          final createdDt = DateTime.tryParse(payment.createdAt!);
          final dateStr = createdDt != null
              ? DateFormat.formatDate(createdDt, convertToIst: true)
              : payment.createdAt!;
          formattedReported = payment.reportedByGuest
              ? '$dateStr ${l10n.reportedByGuest}'
              : dateStr;
        }

        String? formattedConfirmed;
        if (payment.confirmedAt != null && payment.confirmedAt!.isNotEmpty) {
          final confirmedDt = DateTime.tryParse(payment.confirmedAt!);
          formattedConfirmed = confirmedDt != null
              ? DateFormat.formatDate(confirmedDt, convertToIst: true)
              : payment.confirmedAt!;
        }

        String? roomText;
        if (payment.roomNumber != null && payment.roomNumber!.isNotEmpty) {
          if (payment.bedLabel != null && payment.bedLabel!.isNotEmpty) {
            roomText = 'Room ${payment.roomNumber}, bed ${payment.bedLabel}';
          } else {
            roomText = 'Room ${payment.roomNumber}';
          }
        }

        Widget? bottomNavigationBar;
        if (payment.status == 'pending') {
          bottomNavigationBar = Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(
                  color: AppColors.hairline,
                  width: AppSize.hairline,
                ),
              ),
            ),
            padding: EdgeInsets.only(
              left: AppSpace.x16,
              right: AppSpace.x16,
              top: AppSpace.x16,
              bottom: AppSpace.x16 + MediaQuery.paddingOf(context).bottom,
            ),
            child: Row(
              children: [
                Expanded(
                  child: AppButton.secondary(
                    label: l10n.actionReject,
                    expand: true,
                    onPressed: () async {
                      final res = await RejectPaymentSheet.show(
                        context,
                        payment: payment,
                      );
                      if (res == true && context.mounted) {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton.primary(
                    label: l10n.actionMarkReceived,
                    expand: true,
                    onPressed: () async {
                      final res = await ConfirmPaymentSheet.show(
                        context,
                        payment: payment,
                      );
                      if (res == true) {
                        ref.invalidate(paymentDetailProvider(paymentId));
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        } else if (payment.status == 'confirmed') {
          bottomNavigationBar = Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(
                  color: AppColors.hairline,
                  width: AppSize.hairline,
                ),
              ),
            ),
            padding: EdgeInsets.only(
              left: AppSpace.x16,
              right: AppSpace.x16,
              top: AppSpace.x16,
              bottom: AppSpace.x16 + MediaQuery.paddingOf(context).bottom,
            ),
            child: AppButton.primary(
              label: l10n.actionViewReceipt,
              expand: true,
              onPressed: () {
                final receiptPath = RoutePaths.receipt
                    .replaceFirst(':paymentId', payment.paymentId);
                context.push(receiptPath);
              },
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.ground,
          appBar: AppTopBar.back(
            title: l10n.paymentTitle,
            onLeadingPressed: () => context.pop(),
          ),
          bottomNavigationBar: bottomNavigationBar,
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSpace.x32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 2. Summary sheet
                LedgerSheet(
                  padding: const EdgeInsets.all(AppSpace.x16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Money(
                        paise: payment.amountPaise,
                        style: AppText.display,
                      ),
                      _buildStatusChip(payment.status, l10n),
                    ],
                  ),
                ),

                // 3. Details sheet
                LedgerSheet(
                  children: [
                    if (payment.fullName != null &&
                        payment.fullName!.isNotEmpty)
                      KeyValueRow(
                        label: l10n.detailGuest,
                        value: payment.fullName!,
                        trailing: const Icon(
                          AppIcons.chevronRight,
                          size: 16,
                          color: AppColors.muted,
                        ),
                        onTap: () =>
                            context.push('/owner/guests/${payment.stayId}'),
                      ),
                    if (roomText != null)
                      KeyValueRow(
                        label: l10n.detailRoom,
                        value: roomText,
                      ),
                    if (payment.methodLabel.isNotEmpty)
                      KeyValueRow(
                        label: l10n.detailMethod,
                        value: payment.methodLabel,
                      ),
                    if (formattedPaidOn != null)
                      KeyValueRow(
                        label: l10n.detailPaidOn,
                        value: formattedPaidOn,
                      ),
                    KeyValueRow(
                      label: l10n.detailReceivedIn,
                      value: payment.accountNickname ?? l10n.detailNone,
                    ),
                    if (payment.payerAppLabel != null &&
                        payment.payerAppLabel!.isNotEmpty)
                      KeyValueRow(
                        label: l10n.detailPaidUsing,
                        value: payment.payerAppLabel!,
                      ),
                    if (payment.utr != null && payment.utr!.isNotEmpty)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onLongPress: () {
                          Clipboard.setData(ClipboardData(text: payment.utr!));
                          AppSnack.show(context, message: l10n.copied);
                        },
                        child: KeyValueRow(
                          label: l10n.detailUtr,
                          value: payment.utr!,
                        ),
                      ),
                    if (payment.payerPhone != null &&
                        payment.payerPhone!.isNotEmpty)
                      KeyValueRow(
                        label: l10n.detailFromNumber,
                        value: payment.payerPhone!,
                      ),
                    if (formattedReported != null)
                      KeyValueRow(
                        label: l10n.detailReported,
                        value: formattedReported,
                      ),
                    if (formattedConfirmed != null)
                      KeyValueRow(
                        label: l10n.detailConfirmed,
                        value: formattedConfirmed,
                      ),
                    if (payment.note != null && payment.note!.isNotEmpty)
                      KeyValueRow(
                        label: l10n.detailNote,
                        value: payment.note!,
                      ),
                    if ((payment.status == 'rejected' ||
                            payment.status == 'reversed') &&
                        payment.statusReason != null &&
                        payment.statusReason!.isNotEmpty)
                      KeyValueRow(
                        label: l10n.detailReason,
                        value: payment.statusReason!,
                      ),
                    if (payment.screenshotFileId != null &&
                        payment.screenshotFileId!.isNotEmpty)
                      _buildScreenshotRow(
                        context,
                        ref,
                        l10n,
                        payment.screenshotFileId!,
                      ),
                  ],
                ),

                // Reverse payment button (below details sheet, owner and manager only)
                if (payment.status == 'confirmed' && isOwnerOrManager) ...[
                  const SizedBox(height: AppSpace.x16),
                  Center(
                    child: AppButton.text(
                      label: l10n.actionReversePayment,
                      textColor: AppColors.overdueFg,
                      onPressed: () async {
                        final res = await ReversePaymentSheet.show(
                          context,
                          payment: payment,
                        );
                        if (res == true) {
                          ref.invalidate(paymentDetailProvider(paymentId));
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
