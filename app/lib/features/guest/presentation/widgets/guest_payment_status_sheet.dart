import 'package:flutter/material.dart';

import '../../../../core/format/dates.dart';
import '../../../../core/format/money.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/key_value_row.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../owner/domain/guest_list_item.dart';
import '../../../owner/domain/payment_feed_item.dart';
import 'guest_report_payment_sheet.dart';

class GuestPaymentStatusSheet extends StatelessWidget {
  final PaymentFeedItem payment;
  final GuestListItem? stay;
  final bool allowReporting;

  const GuestPaymentStatusSheet({
    super.key,
    required this.payment,
    this.stay,
    this.allowReporting = true,
  });

  static Future<void> show({
    required BuildContext context,
    required PaymentFeedItem payment,
    GuestListItem? stay,
    bool allowReporting = true,
  }) {
    return AppBottomSheet.show<void>(
      context: context,
      builder: (context) => GuestPaymentStatusSheet(
        payment: payment,
        stay: stay,
        allowReporting: allowReporting,
      ),
    );
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return DateFormat.formatDate(dt);
  }

  Widget _buildStatusChip(AppLocalizations l10n) {
    switch (payment.status) {
      case 'pending':
        return const StatusChip.pending();
      case 'rejected':
        return StatusChip.overdue(label: l10n.statusRejected);
      case 'reversed':
        return StatusChip.overdue(label: l10n.statusReversed);
      case 'confirmed':
      default:
        return const StatusChip.paid();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final methodStr = (payment.payerAppLabel != null &&
            payment.payerAppLabel!.isNotEmpty)
        ? '${payment.methodLabel}, ${payment.payerAppLabel}'
        : payment.methodLabel;

    final reportedDateStr = _formatDate(payment.createdAt ?? payment.paidOn);
    final paidDateStr = _formatDate(payment.paidOn);

    return AppBottomSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Amount in display
          Text(
            MoneyFormat.format(payment.amountPaise),
            style: AppText.display,
          ),
          const SizedBox(height: AppSpace.x8),

          // Status chip below amount
          Align(
            alignment: Alignment.centerLeft,
            child: _buildStatusChip(l10n),
          ),
          const SizedBox(height: AppSpace.x16),

          // KeyValueRows (Method, Paid on, Reported on)
          KeyValueRow(
            label: l10n.statusSheetMethod,
            value: methodStr,
          ),
          KeyValueRow(
            label: l10n.statusSheetPaidOn,
            value: paidDateStr,
          ),
          KeyValueRow(
            label: l10n.statusSheetReportedOn,
            value: reportedDateStr,
            showDivider: false,
          ),

          // Status-specific content
          if (payment.status == 'pending') ...[
            const SizedBox(height: AppSpace.x16),
            Text(
              l10n.statusSheetPending,
              style: AppText.secondary,
            ),
          ] else if (payment.status == 'rejected') ...[
            const SizedBox(height: AppSpace.x16),
            Text(
              l10n.statusSheetRejected(payment.statusReason ?? ''),
              style: AppText.secondary,
            ),
            if (allowReporting) ...[
              const SizedBox(height: AppSpace.x16),
              Center(
                child: AppButton.text(
                  label: l10n.statusSheetPayAgain,
                  onPressed: () {
                    Navigator.of(context).pop();
                    final targetPgId = stay?.pgId ?? payment.pgId ?? '';
                    GuestReportPaymentSheet.showVariantB(
                      context: context,
                      stayId: payment.stayId,
                      pgId: targetPgId,
                      defaultAmountPaise: payment.amountPaise,
                    );
                  },
                ),
              ),
            ],
          ] else if (payment.status == 'reversed') ...[
            if (payment.statusReason != null &&
                payment.statusReason!.isNotEmpty) ...[
              const SizedBox(height: AppSpace.x16),
              Text(
                payment.statusReason!,
                style: AppText.secondary,
              ),
            ],
          ],
          const SizedBox(height: AppSpace.x16),
        ],
      ),
    );
  }
}

