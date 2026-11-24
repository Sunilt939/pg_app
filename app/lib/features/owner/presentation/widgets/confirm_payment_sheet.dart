import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/format/money.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/option_sheet.dart';
import '../../../../core/widgets/select_field.dart';
import '../../domain/owner_repository.dart';
import '../../domain/payment_account.dart';
import '../providers/owner_provider.dart';

class ConfirmPaymentSheet extends ConsumerStatefulWidget {
  final PaymentFeedItem payment;

  const ConfirmPaymentSheet({
    super.key,
    required this.payment,
  });

  static Future<bool?> show(
    BuildContext context, {
    required PaymentFeedItem payment,
  }) {
    return AppBottomSheet.show<bool>(
      context: context,
      builder: (context) => ConfirmPaymentSheet(payment: payment),
    );
  }

  @override
  ConsumerState<ConfirmPaymentSheet> createState() => _ConfirmPaymentSheetState();
}

class _ConfirmPaymentSheetState extends ConsumerState<ConfirmPaymentSheet> {
  String? _selectedAccountId;
  bool _accountInitialized = false;
  bool _isLoading = false;

  void _initSelectedAccount(List<PaymentAccount> accounts) {
    if (_accountInitialized || accounts.isEmpty) return;
    _accountInitialized = true;

    final reportedAcc = widget.payment.receivedAccountId;
    if (reportedAcc != null && accounts.any((a) => a.id == reportedAcc)) {
      _selectedAccountId = reportedAcc;
      return;
    }

    final defaultAcc = accounts.where((a) => a.isDefault).firstOrNull;
    if (defaultAcc != null) {
      _selectedAccountId = defaultAcc.id;
      return;
    }

    _selectedAccountId = accounts.first.id;
  }

  Future<void> _handleConfirm() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(ownerRepositoryProvider);
      await repo.confirmPayment(
        paymentId: widget.payment.paymentId,
        accountId: _selectedAccountId,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);

      HapticFeedback.lightImpact();

      final l10n = AppLocalizations.of(context)!;
      final receiptPath = RoutePaths.receipt
          .replaceFirst(':paymentId', widget.payment.paymentId);
      context.push(
        receiptPath,
        extra: {
          'isNew': true,
          'title': l10n.receiptConfirmed,
        },
      );
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accountsAsync = ref.watch(paymentAccountsProvider);
    final accounts = accountsAsync.valueOrNull ?? [];

    if (!_accountInitialized && accounts.isNotEmpty) {
      _initSelectedAccount(accounts);
    }

    PaymentAccount? selectedAccount;
    if (_selectedAccountId != null) {
      selectedAccount =
          accounts.where((a) => a.id == _selectedAccountId).firstOrNull;
    }

    final bodyText = l10n.confirmBody(
      MoneyFormat.format(widget.payment.amountPaise),
      widget.payment.fullName ?? '',
    );

    return AppBottomSheet(
      title: l10n.confirmTitle,
      bottomAction: AppButton.primary(
        label: l10n.actionMarkReceived,
        loading: _isLoading,
        onPressed: _handleConfirm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(bodyText, style: AppText.body),
          if (accounts.isNotEmpty) ...[
            const SizedBox(height: AppSpace.x16),
            SelectField(
              label: l10n.detailReceivedIn,
              value: selectedAccount?.nickname ?? '',
              onTap: () async {
                final options = accounts
                    .map(
                      (a) => OptionSheetItem<String>(
                        value: a.id,
                        title: a.nickname,
                        subtitle: a.kind == 'upi'
                            ? a.upiVpa
                            : (a.accountLast4 != null &&
                                    a.accountLast4!.isNotEmpty
                                ? '${a.bankName ?? ''}, ending ${a.accountLast4}'
                                : a.bankName),
                      ),
                    )
                    .toList();
                final picked = await OptionSheet.show<String>(
                  context: context,
                  title: l10n.detailReceivedIn,
                  options: options,
                  selectedValue: _selectedAccountId,
                );
                if (picked != null) {
                  setState(() => _selectedAccountId = picked);
                }
              },
            ),
          ],
          const SizedBox(height: AppSpace.x16),
        ],
      ),
    );
  }
}

