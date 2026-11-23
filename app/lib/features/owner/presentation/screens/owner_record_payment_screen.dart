import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/format/money.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/date_field.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/ledger_sheet.dart';
import '../../../../core/widgets/money_field.dart';
import '../../../../core/widgets/option_row.dart';
import '../../../../core/widgets/option_sheet.dart';
import '../../../../core/widgets/select_field.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../domain/owner_repository.dart';
import '../../domain/payment_account.dart';
import '../providers/owner_provider.dart';

class OwnerRecordPaymentScreen extends ConsumerStatefulWidget {
  final String stayId;

  const OwnerRecordPaymentScreen({
    super.key,
    required this.stayId,
  });

  @override
  ConsumerState<OwnerRecordPaymentScreen> createState() =>
      _OwnerRecordPaymentScreenState();
}

class _OwnerRecordPaymentScreenState
    extends ConsumerState<OwnerRecordPaymentScreen> {
  final _amountController = TextEditingController();
  final _utrController = TextEditingController();
  final _noteController = TextEditingController();

  int _amountPaise = 0;
  String _selectedMethod = 'cash';
  DateTime _paidOn = DateTime.now();
  String? _selectedAccountId;
  String? _selectedPayerAppCode;

  String? _amountError;
  String? _utrError;
  bool _isSubmitting = false;
  bool _isInitialized = false;

  @override
  void dispose() {
    _amountController.dispose();
    _utrController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _initializeDefaults(
    GuestDetailBundle bundle,
    List<PaymentAccount> accounts,
  ) {
    if (_isInitialized) return;
    _isInitialized = true;

    final guest = bundle.guest;
    final dueNow = guest.dueNowPaise ?? 0;
    if (dueNow > 0) {
      _amountPaise = dueNow;
    } else if (guest.outstandingPaise > 0) {
      _amountPaise = guest.outstandingPaise;
    } else {
      _amountPaise = 0;
    }

    if (_amountPaise > 0) {
      _amountController.text =
          formatRupeesWithGrouping(_amountPaise ~/ 100);
    }

    final activeAccounts = accounts.where((a) => a.isActive).toList();
    if (activeAccounts.isNotEmpty) {
      final defaultAcc =
          activeAccounts.where((a) => a.isDefault).firstOrNull ??
              activeAccounts.first;
      _selectedAccountId = defaultAcc.id;
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _amountError = null;
      _utrError = null;
    });

    if (_amountPaise <= 0) {
      setState(() {
        _amountError = l10n.errAmount;
      });
      return;
    }

    if (_selectedMethod == 'upi') {
      final utr = _utrController.text.trim();
      if (utr.isNotEmpty && (utr.length < 6 || utr.length > 22)) {
        setState(() {
          _utrError = l10n.errUtr;
        });
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final repo = ref.read(ownerRepositoryProvider);
      final paymentId = await repo.recordPayment(
        stayId: widget.stayId,
        amountPaise: _amountPaise,
        methodCode: _selectedMethod,
        paidOn: _paidOn,
        accountId: _selectedMethod != 'cash' ? _selectedAccountId : null,
        note: _noteController.text.trim().isNotEmpty
            ? _noteController.text.trim()
            : null,
        payerAppCode: _selectedMethod == 'upi' ? _selectedPayerAppCode : null,
        utr: _selectedMethod == 'upi' && _utrController.text.trim().isNotEmpty
            ? _utrController.text.trim().toUpperCase()
            : null,
      );

      ref.invalidate(guestDetailBundleProvider(widget.stayId));
      ref.invalidate(guestListProvider);
      ref.invalidate(pgOverviewProvider);

      if (mounted) {
        context.pushReplacement('/receipt/$paymentId', extra: {'isNew': true});
      }
    } on DuplicateUtrException catch (e) {
      if (mounted) {
        setState(() {
          _utrError = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildLoadingSkeleton() {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpace.x16),
      children: const [
        SkeletonBlock(height: 80),
        SizedBox(height: AppSpace.x16),
        SkeletonBlock(height: 240),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bundleAsync = ref.watch(guestDetailBundleProvider(widget.stayId));
    final accountsAsync = ref.watch(paymentAccountsProvider);
    final methodsAsync = ref.watch(paymentMethodsProvider);
    final upiAppsAsync = ref.watch(upiAppsProvider);

    return Scaffold(
      backgroundColor: AppColors.ground,
      appBar: AppTopBar.close(
        title: l10n.recordTitle,
        onLeadingPressed: () => context.pop(),
      ),
      body: bundleAsync.when(
        loading: () => _buildLoadingSkeleton(),
        error: (error, _) => ErrorState(
          title: l10n.errorGeneric,
          message: error.toString(),
          onRetry: () {
            ref.invalidate(guestDetailBundleProvider(widget.stayId));
          },
        ),
        data: (bundle) {
          if (bundle == null) {
            return ErrorState(
              title: l10n.errorGeneric,
              message: l10n.errorGeneric,
              onRetry: () {
                ref.invalidate(guestDetailBundleProvider(widget.stayId));
              },
            );
          }

          final accounts = accountsAsync.value ?? [];
          _initializeDefaults(bundle, accounts);

          final guest = bundle.guest;
          final guestName =
              (guest.fullName != null && guest.fullName!.trim().isNotEmpty)
                  ? guest.fullName!.trim()
                  : guest.phone;

          String roomSubtitle;
          if (guest.roomNumber != null && guest.bedLabel != null) {
            roomSubtitle =
                l10n.guestBedOption(guest.roomNumber!, guest.bedLabel!);
          } else {
            roomSubtitle = l10n.guestBedNone;
          }

          final activeAccounts = accounts.where((a) => a.isActive).toList();
          final methods = methodsAsync.value ?? [];
          final upiApps = upiAppsAsync.value ?? [];

          final methodOptions = methods.isNotEmpty
              ? methods
                  .map((m) => OptionRowItem(value: m.code, label: m.label))
                  .toList()
              : [
                  const OptionRowItem(value: 'cash', label: 'Cash'),
                  const OptionRowItem(value: 'upi', label: 'UPI'),
                  const OptionRowItem(value: 'bank_transfer', label: 'Bank transfer'),
                  const OptionRowItem(value: 'cheque', label: 'Cheque'),
                ];

          // Determine selected account label & subtitle
          PaymentAccount? selectedAcc;
          if (_selectedAccountId != null) {
            selectedAcc = activeAccounts
                .where((a) => a.id == _selectedAccountId)
                .firstOrNull;
          }
          final selectedAccLabel =
              selectedAcc?.nickname ?? l10n.accountNotSure;

          // Determine selected UPI app label
          final selectedUpiApp = upiApps
              .where((a) => a.code == _selectedPayerAppCode)
              .firstOrNull;

          final dueNow = guest.dueNowPaise ?? 0;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpace.x16),
                  children: [
                    LedgerSheet(
                      padding: const EdgeInsets.all(AppSpace.x16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(guestName, style: AppText.heading),
                          const SizedBox(height: AppSpace.x4),
                          Text(roomSubtitle, style: AppText.secondary),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpace.x16),
                    LedgerSheet(
                      padding: const EdgeInsets.all(AppSpace.x16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MoneyField(
                            label: l10n.recordAmount,
                            controller: _amountController,
                            isLarge: true,
                            errorText: _amountError,
                            onChanged: (paise) {
                              setState(() {
                                _amountPaise = paise;
                                _amountError = null;
                              });
                            },
                          ),
                          const SizedBox(height: AppSpace.x8),
                          Wrap(
                            spacing: 14,
                            runSpacing: AppSpace.x8,
                            children: [
                              if (dueNow > 0)
                                AppButton.text(
                                  label: l10n.payDueNow(
                                    MoneyFormat.format(dueNow),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _amountPaise = dueNow;
                                      _amountController.text =
                                          formatRupeesWithGrouping(
                                        dueNow ~/ 100,
                                      );
                                      _amountError = null;
                                    });
                                  },
                                ),
                              if (guest.outstandingPaise > dueNow)
                                AppButton.text(
                                  label: l10n.payAllUnpaid(
                                    MoneyFormat.format(
                                      guest.outstandingPaise,
                                    ),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _amountPaise = guest.outstandingPaise;
                                      _amountController.text =
                                          formatRupeesWithGrouping(
                                        guest.outstandingPaise ~/ 100,
                                      );
                                      _amountError = null;
                                    });
                                  },
                                ),
                            ],
                          ),
                          if (_amountPaise > guest.outstandingPaise) ...[
                            const SizedBox(height: AppSpace.x8),
                            Text(
                              l10n.payAdvanceNote,
                              style: AppText.secondary,
                            ),
                          ],
                          const SizedBox(height: AppSpace.x16),
                          Text(l10n.recordMethod, style: AppText.label),
                          const SizedBox(height: AppSpace.x8),
                          OptionRow<String>(
                            options: methodOptions,
                            selectedValue: _selectedMethod,
                            onChanged: (code) {
                              setState(() {
                                _selectedMethod = code;
                              });
                            },
                          ),
                          const SizedBox(height: AppSpace.x16),
                          DateField(
                            label: l10n.recordPaidOn,
                            value: _paidOn,
                            lastDate: DateTime.now(),
                            onChanged: (date) {
                              setState(() {
                                _paidOn = date;
                              });
                            },
                          ),
                          if (_selectedMethod != 'cash') ...[
                            const SizedBox(height: AppSpace.x16),
                            if (activeAccounts.isNotEmpty)
                              SelectField(
                                label: l10n.recordReceivedIn,
                                value: selectedAccLabel,
                                onTap: () async {
                                  final options = <OptionSheetItem<String?>>[
                                    OptionSheetItem<String?>(
                                      value: null,
                                      title: l10n.accountNotSure,
                                    ),
                                    ...activeAccounts.map((a) {
                                      String? sub;
                                      if (a.kind == 'upi') {
                                        sub = a.upiVpa;
                                      } else if (a.accountLast4 != null &&
                                          a.accountLast4!.isNotEmpty) {
                                        sub =
                                            '${a.bankName ?? ''}, ending ${a.accountLast4}';
                                      } else {
                                        sub = a.bankName;
                                      }
                                      return OptionSheetItem<String?>(
                                        value: a.id,
                                        title: a.nickname,
                                        subtitle: sub,
                                      );
                                    }),
                                  ];
                                  final picked =
                                      await OptionSheet.show<String?>(
                                    context: context,
                                    title: l10n.recordReceivedIn,
                                    options: options,
                                    selectedValue: _selectedAccountId,
                                  );
                                  if (picked != null || picked == null) {
                                    setState(() {
                                      _selectedAccountId = picked;
                                    });
                                  }
                                },
                              )
                            else
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    AppIcons.info,
                                    size: 20,
                                    color: AppColors.muted,
                                  ),
                                  const SizedBox(width: AppSpace.x8),
                                  Expanded(
                                    child: Text(
                                      l10n.noAccountsHint,
                                      style: AppText.secondary,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                          if (_selectedMethod == 'upi') ...[
                            const SizedBox(height: AppSpace.x16),
                            SelectField(
                              label: l10n.recordPaidUsing,
                              value: selectedUpiApp?.label,
                              hint: l10n.recordPaidUsingPick,
                              onTap: () async {
                                final options = <OptionSheetItem<String?>>[
                                  OptionSheetItem<String?>(
                                    value: null,
                                    title: l10n.detailNone,
                                  ),
                                  ...upiApps.map(
                                    (u) => OptionSheetItem<String?>(
                                      value: u.code,
                                      title: u.label,
                                    ),
                                  ),
                                ];
                                final picked =
                                    await OptionSheet.show<String?>(
                                  context: context,
                                  title: l10n.recordPaidUsing,
                                  options: options,
                                  selectedValue: _selectedPayerAppCode,
                                );
                                if (picked != null || picked == null) {
                                  setState(() {
                                    _selectedPayerAppCode = picked;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: AppSpace.x16),
                            AppTextField(
                              label: l10n.recordUtr,
                              hint: '',
                              helperText: l10n.utrHelper,
                              errorText: _utrError,
                              controller: _utrController,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[a-zA-Z0-9]'),
                                ),
                                _UpperCaseTextFormatter(),
                              ],
                              onChanged: (_) {
                                if (_utrError != null) {
                                  setState(() {
                                    _utrError = null;
                                  });
                                }
                              },
                            ),
                          ],
                          const SizedBox(height: AppSpace.x16),
                          AppTextField(
                            label: l10n.recordNote,
                            controller: _noteController,
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                color: AppColors.ground,
                padding: const EdgeInsets.all(AppSpace.x16),
                child: SafeArea(
                  top: false,
                  child: AppButton.primary(
                    label: l10n.recordAction,
                    expand: true,
                    loading: _isSubmitting,
                    onPressed: _amountPaise > 0 ? _submit : null,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
