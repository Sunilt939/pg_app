import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snack.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/owner_repository.dart';
import '../providers/owner_provider.dart';

class ReversePaymentSheet extends ConsumerStatefulWidget {
  final PaymentFeedItem payment;

  const ReversePaymentSheet({
    super.key,
    required this.payment,
  });

  static Future<bool?> show(
    BuildContext context, {
    required PaymentFeedItem payment,
  }) {
    return AppBottomSheet.show<bool>(
      context: context,
      builder: (context) => ReversePaymentSheet(payment: payment),
    );
  }

  @override
  ConsumerState<ReversePaymentSheet> createState() => _ReversePaymentSheetState();
}

class _ReversePaymentSheetState extends ConsumerState<ReversePaymentSheet> {
  final _reasonController = TextEditingController();
  String? _errorText;
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _handleReverse() async {
    final reason = _reasonController.text.trim();
    final l10n = AppLocalizations.of(context)!;
    if (reason.isEmpty) {
      setState(() => _errorText = l10n.errReasonRequired);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(ownerRepositoryProvider);
      await repo.reversePayment(
        paymentId: widget.payment.paymentId,
        reason: reason,
      );

      if (!mounted) return;
      AppSnack.show(context, message: l10n.paymentReversed);
      Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppBottomSheet(
      title: l10n.reverseTitle,
      bottomAction: AppButton.destructive(
        label: l10n.actionReversePayment,
        loading: _isLoading,
        onPressed: _handleReverse,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.reverseBody,
            style: AppText.body,
          ),
          const SizedBox(height: AppSpace.x16),
          AppTextField(
            label: l10n.reverseReason,
            controller: _reasonController,
            errorText: _errorText,
            maxLines: 3,
            onChanged: (val) {
              if (_errorText != null && val.trim().isNotEmpty) {
                setState(() => _errorText = null);
              }
            },
          ),
          const SizedBox(height: AppSpace.x16),
        ],
      ),
    );
  }
}
