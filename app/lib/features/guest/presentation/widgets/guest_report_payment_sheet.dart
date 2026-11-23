import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/format/money.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snack.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/date_field.dart';
import '../../../../core/widgets/money_field.dart';
import '../../../../core/widgets/option_row.dart';
import '../../../../core/widgets/option_sheet.dart';
import '../../../../core/widgets/phone_field.dart';
import '../../../../core/widgets/select_field.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../../owner/domain/payment_account.dart';
import '../../../owner/domain/payment_method.dart';
import '../../../owner/domain/upi_app.dart';
import '../providers/guest_provider.dart';

enum GuestReportVariant {
  variantA,
  variantB,
}

class GuestReportPaymentSheet extends ConsumerStatefulWidget {
  final GuestReportVariant variant;
  final String stayId;
  final String pgId;
  final int initialAmountPaise;
  final PaymentAccount? upiAccount;

  const GuestReportPaymentSheet({
    super.key,
    required this.variant,
    required this.stayId,
    required this.pgId,
    required this.initialAmountPaise,
    this.upiAccount,
  });

  static Future<bool?> showVariantA({
    required BuildContext context,
    required String stayId,
    required String pgId,
    required int amountPaise,
    required PaymentAccount upiAccount,
  }) async {
    final result = await AppBottomSheet.show<bool>(
      context: context,
      builder: (context) => GuestReportPaymentSheet(
        variant: GuestReportVariant.variantA,
        stayId: stayId,
        pgId: pgId,
        initialAmountPaise: amountPaise,
        upiAccount: upiAccount,
      ),
    );
    if (result == true && context.mounted) {
      final l10n = AppLocalizations.of(context)!;
      AppSnack.show(context, message: l10n.reportSent);
    }
    return result;
  }

  static Future<bool?> showVariantB({
    required BuildContext context,
    required String stayId,
    required String pgId,
    int? defaultAmountPaise,
    PaymentAccount? defaultUpiAccount,
  }) async {
    final result = await AppBottomSheet.show<bool>(
      context: context,
      builder: (context) => GuestReportPaymentSheet(
        variant: GuestReportVariant.variantB,
        stayId: stayId,
        pgId: pgId,
        initialAmountPaise: defaultAmountPaise ?? 0,
        upiAccount: defaultUpiAccount,
      ),
    );
    if (result == true && context.mounted) {
      final l10n = AppLocalizations.of(context)!;
      AppSnack.show(context, message: l10n.reportSent);
    }
    return result;
  }

  @override
  ConsumerState<GuestReportPaymentSheet> createState() =>
      _GuestReportPaymentSheetState();
}

class _GuestReportPaymentSheetState
    extends ConsumerState<GuestReportPaymentSheet> {
  bool _expanded = false;
  bool _submitting = false;

  // Variant A & B shared detail fields
  UpiApp? _selectedUpiApp;
  late final TextEditingController _utrController;
  late final TextEditingController _phoneController;
  String? _utrError;

  // Variant B fields
  late int _amountPaise;
  late final TextEditingController _amountController;
  String _selectedMethodCode = 'cash';
  DateTime _paidOn = DateTime.now();
  PaymentAccount? _selectedUpiAccount;
  PaymentAccount? _selectedBankAccount;
  bool _bankAccountNotSure = false;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _amountPaise = widget.initialAmountPaise;
    _amountController = TextEditingController();
    if (_amountPaise > 0) {
      _amountController.text =
          formatRupeesWithGrouping(_amountPaise ~/ 100);
    }
    _utrController = TextEditingController();
    _phoneController = TextEditingController();
    _noteController = TextEditingController();
    _selectedUpiAccount = widget.upiAccount;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _utrController.dispose();
    _phoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickUpiApp(BuildContext context, List<UpiApp> apps) async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await OptionSheet.show<UpiApp>(
      context: context,
      title: l10n.reportPaidUsing,
      options: apps
          .map(
            (a) => OptionSheetItem<UpiApp>(
              value: a,
              title: a.label,
            ),
          )
          .toList(),
      selectedValue: _selectedUpiApp,
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedUpiApp = picked;
      });
    }
  }

  Future<void> _pickUpiAccount(
    BuildContext context,
    List<PaymentAccount> accounts,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await OptionSheet.show<PaymentAccount>(
      context: context,
      title: l10n.reportPaidTo,
      options: accounts
          .map(
            (a) => OptionSheetItem<PaymentAccount>(
              value: a,
              title: a.nickname,
              subtitle: a.upiVpa,
            ),
          )
          .toList(),
      selectedValue: _selectedUpiAccount,
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedUpiAccount = picked;
      });
    }
  }

  Future<void> _pickBankAccount(
    BuildContext context,
    List<PaymentAccount> accounts,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final notSureItem = OptionSheetItem<PaymentAccount?>(
      value: null,
      title: l10n.accountNotSure,
    );

    final options = <OptionSheetItem<PaymentAccount?>>[
      notSureItem,
      ...accounts.map(
        (a) => OptionSheetItem<PaymentAccount?>(
          value: a,
          title: a.nickname,
          subtitle: a.accountLast4 != null
              ? '•••• ${a.accountLast4}'
              : (a.bankName ?? ''),
        ),
      ),
    ];

    final picked = await OptionSheet.show<PaymentAccount?>(
      context: context,
      title: l10n.reportPaidTo,
      options: options,
      selectedValue:
          _bankAccountNotSure ? null : _selectedBankAccount,
    );

    if (mounted) {
      setState(() {
        if (picked == null) {
          _bankAccountNotSure = true;
          _selectedBankAccount = null;
        } else {
          _bankAccountNotSure = false;
          _selectedBankAccount = picked;
        }
      });
    }
  }

  bool _validateUtr() {
    final utr = _utrController.text.trim();
    if (utr.isNotEmpty && (utr.length < 6 || utr.length > 22)) {
      setState(() {
        _utrError = 'Enter 6 to 22 letters or numbers';
        _expanded = true;
      });
      return false;
    }
    setState(() {
      _utrError = null;
    });
    return true;
  }

  Future<void> _submitReport({
    required int amountPaise,
    required String methodCode,
    DateTime? paidOn,
    String? accountId,
    String? note,
  }) async {
    if (!_validateUtr()) return;

    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _submitting = true;
      _utrError = null;
    });

    final utr = _utrController.text.trim().isNotEmpty
        ? _utrController.text.trim()
        : null;
    final phoneDigits =
        _phoneController.text.replaceAll(RegExp(r'\D'), '');
    final payerPhone = phoneDigits.isNotEmpty ? phoneDigits : null;

    try {
      final repo = ref.read(guestRepositoryProvider);
      await repo.reportPayment(
        stayId: widget.stayId,
        amountPaise: amountPaise,
        methodCode: methodCode,
        paidOn: paidOn,
        accountId: accountId,
        payerAppCode: _selectedUpiApp?.code,
        payerPhone: payerPhone,
        utr: utr,
        note: note,
      );

      HapticFeedback.lightImpact();
      ref.invalidate(guestHomeBundleProvider);
      ref.invalidate(guestStayProvider(widget.stayId));

      if (mounted) {
        setState(() {
          _submitting = false;
        });
        Navigator.of(context).pop(true);
      }
    } on PostgrestException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
      });

      if (e.code == '23505') {
        setState(() {
          _utrError = e.message;
          _expanded = true;
        });
      } else {
        AppSnack.show(context, message: e.message);
      }
    } on SocketException {
      if (!mounted) return;
      setState(() {
        _submitting = false;
      });
      AppSnack.show(context, message: l10n.errorNetwork);
    } on AuthNetworkException {
      if (!mounted) return;
      setState(() {
        _submitting = false;
      });
      AppSnack.show(context, message: l10n.errorNetwork);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
      });
      AppSnack.show(context, message: e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Widget _buildCollapsibleDetails(
    BuildContext context,
    AppLocalizations l10n,
    List<UpiApp> upiApps,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: AppRadius.control,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.x8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.reportDetails,
                    style: AppText.buttonSmall.copyWith(
                      color: AppColors.petrol,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0.0,
                  duration: AppMotion.base,
                  curve: AppMotion.curve,
                  child: const Icon(
                    AppIcons.chevronDown,
                    size: 20,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: AppSpace.x8),
          SelectField(
            label: l10n.reportPaidUsing,
            value: _selectedUpiApp?.label,
            hint: 'Select app',
            onTap: () => _pickUpiApp(context, upiApps),
          ),
          const SizedBox(height: AppSpace.x12),
          AppTextField(
            label: l10n.reportUtr,
            controller: _utrController,
            helperText: l10n.utrHelper,
            errorText: _utrError,
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'[a-zA-Z0-9]'),
              ),
            ],
            maxLength: 22,
          ),
          const SizedBox(height: AppSpace.x12),
          PhoneField(
            label: l10n.reportFromNumber,
            controller: _phoneController,
          ),
        ],
      ],
    );
  }

  Widget _buildVariantA(
    BuildContext context,
    AppLocalizations l10n,
    List<UpiApp> upiApps,
  ) {
    final accountName = widget.upiAccount?.nickname ?? '';
    final amountFormatted =
        MoneyFormat.format(widget.initialAmountPaise);

    return AppBottomSheet(
      title: l10n.reportTitleA,
      bottomAction: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppButton.primary(
            label: l10n.reportYes,
            loading: _submitting,
            expand: true,
            onPressed: () => _submitReport(
              amountPaise: widget.initialAmountPaise,
              methodCode: 'upi',
              paidOn: null,
              accountId: widget.upiAccount?.id,
            ),
          ),
          const SizedBox(height: AppSpace.x8),
          Center(
            child: AppButton.text(
              label: l10n.reportNotYet,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.reportSummaryA(amountFormatted, accountName),
            style: AppText.secondary,
          ),
          const SizedBox(height: AppSpace.x16),
          _buildCollapsibleDetails(context, l10n, upiApps),
          const SizedBox(height: AppSpace.x16),
        ],
      ),
    );
  }

  Widget _buildVariantB(
    BuildContext context,
    AppLocalizations l10n,
    List<PaymentMethod> methods,
    List<PaymentAccount> upiAccounts,
    List<PaymentAccount> bankAccounts,
    List<UpiApp> upiApps,
  ) {
    final eligibleMethods =
        methods.where((m) => m.code != 'cheque').toList();

    // Default UPI account if not selected
    if (_selectedUpiAccount == null && upiAccounts.isNotEmpty) {
      _selectedUpiAccount =
          upiAccounts.where((a) => a.isDefault).firstOrNull ??
              upiAccounts.firstOrNull;
    }

    String? accountId;
    if (_selectedMethodCode == 'upi') {
      accountId = _selectedUpiAccount?.id;
    } else if (_selectedMethodCode == 'bank_transfer') {
      accountId = _selectedBankAccount?.id;
    }

    final isSubmitEnabled = _amountPaise > 0;

    return AppBottomSheet(
      title: l10n.reportTitleB,
      bottomAction: AppButton.primary(
        label: l10n.reportSend,
        loading: _submitting,
        expand: true,
        onPressed: isSubmitEnabled
            ? () => _submitReport(
                  amountPaise: _amountPaise,
                  methodCode: _selectedMethodCode,
                  paidOn: _paidOn,
                  accountId: accountId,
                  note: _noteController.text.trim().isNotEmpty
                      ? _noteController.text.trim()
                      : null,
                )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
            // Amount
            MoneyField(
              label: l10n.payAmount,
              controller: _amountController,
              isLarge: true,
              onChanged: (paise) {
                setState(() {
                  _amountPaise = paise;
                });
              },
            ),
            const SizedBox(height: AppSpace.x16),

            // How did you pay?
            Text(l10n.reportHow, style: AppText.label),
            const SizedBox(height: AppSpace.x8),
            OptionRow<String>(
              options: eligibleMethods
                  .map(
                    (m) => OptionRowItem<String>(
                      value: m.code,
                      label: m.label,
                    ),
                  )
                  .toList(),
              selectedValue: _selectedMethodCode,
              onChanged: (code) {
                setState(() {
                  _selectedMethodCode = code;
                });
              },
            ),
            const SizedBox(height: AppSpace.x16),

            // Paid on
            DateField(
              label: 'Paid on',
              value: _paidOn,
              lastDate: DateTime.now(),
              onChanged: (date) {
                setState(() {
                  _paidOn = date;
                });
              },
            ),
            const SizedBox(height: AppSpace.x16),

            // Contextual account selection
            if (_selectedMethodCode == 'upi') ...[
              if (upiAccounts.isNotEmpty) ...[
                SelectField(
                  label: l10n.reportPaidTo,
                  value: _selectedUpiAccount?.nickname,
                  onTap: () => _pickUpiAccount(context, upiAccounts),
                ),
                const SizedBox(height: AppSpace.x12),
              ],
              _buildCollapsibleDetails(context, l10n, upiApps),
              const SizedBox(height: AppSpace.x16),
            ] else if (_selectedMethodCode == 'bank_transfer') ...[
              if (bankAccounts.isNotEmpty) ...[
                SelectField(
                  label: l10n.reportPaidTo,
                  value: _bankAccountNotSure
                      ? l10n.accountNotSure
                      : (_selectedBankAccount?.nickname ??
                          l10n.accountNotSure),
                  onTap: () => _pickBankAccount(context, bankAccounts),
                ),
                const SizedBox(height: AppSpace.x16),
              ],
            ],

            // Note (optional)
            AppTextField(
              label: 'Note (optional)',
              controller: _noteController,
              maxLines: 2,
            ),
            const SizedBox(height: AppSpace.x16),
          ],
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final upiApps = ref.watch(guestUpiAppsProvider).value ?? const [];

    if (widget.variant == GuestReportVariant.variantA) {
      return _buildVariantA(context, l10n, upiApps);
    }

    final methods =
        ref.watch(guestPaymentMethodsProvider).value ?? const [];
    final upiAccounts =
        ref.watch(guestUpiAccountsProvider(widget.pgId)).value ??
            const [];
    final bankAccounts =
        ref.watch(guestBankAccountsProvider(widget.pgId)).value ??
            const [];

    return _buildVariantB(
      context,
      l10n,
      methods,
      upiAccounts,
      bankAccounts,
      upiApps,
    );
  }
}
