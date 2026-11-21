import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/format/phone.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/ledger_sheet.dart';
import '../../../../core/widgets/option_row.dart';
import '../../../../core/widgets/phone_field.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/switch_row.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/owner_repository.dart';
import '../../domain/payment_account.dart';
import '../providers/owner_provider.dart';

class OwnerAccountFormScreen extends ConsumerStatefulWidget {
  final String? accountId;

  const OwnerAccountFormScreen({
    super.key,
    this.accountId,
  });

  @override
  ConsumerState<OwnerAccountFormScreen> createState() =>
      _OwnerAccountFormScreenState();
}

class _OwnerAccountFormScreenState
    extends ConsumerState<OwnerAccountFormScreen> {
  static final _upiRegex = RegExp(r'^[a-zA-Z0-9.\-_]+@[a-zA-Z]+$');

  late final TextEditingController _nicknameController;
  late final TextEditingController _upiController;
  late final TextEditingController _holderNameController;
  late final TextEditingController _bankNameController;
  late final TextEditingController _last4Controller;
  late final TextEditingController _bankHolderController;
  late final TextEditingController _phoneController;

  String _type = 'upi'; // 'upi' or 'bank'
  bool _isDefault = false;
  bool _isActive = true;
  bool _initialized = false;
  bool _isSubmitting = false;

  String? _nicknameError;
  String? _upiError;
  String? _bankNameError;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController();
    _upiController = TextEditingController();
    _holderNameController = TextEditingController();
    _bankNameController = TextEditingController();
    _last4Controller = TextEditingController();
    _bankHolderController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _upiController.dispose();
    _holderNameController.dispose();
    _bankNameController.dispose();
    _last4Controller.dispose();
    _bankHolderController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _initFromAccount(PaymentAccount account) {
    if (_initialized) return;
    _initialized = true;
    _type = account.kind;
    _nicknameController.text = account.nickname;
    if (account.kind == 'upi') {
      _upiController.text = account.upiVpa ?? '';
      _holderNameController.text = account.holderName ?? '';
    } else {
      _bankNameController.text = account.bankName ?? '';
      _last4Controller.text = account.accountLast4 ?? '';
      _bankHolderController.text = account.holderName ?? '';
    }
    if (account.linkedPhone != null) {
      final digits = PhoneFormat.extractDigits(account.linkedPhone!);
      final tenDigits =
          digits.length >= 10 ? digits.substring(digits.length - 10) : digits;
      if (tenDigits.length > 5) {
        _phoneController.text =
            '${tenDigits.substring(0, 5)} ${tenDigits.substring(5)}';
      } else {
        _phoneController.text = tenDigits;
      }
    }
    _isDefault = account.isDefault;
    _isActive = account.isActive;
  }

  void _initDefaultOnFirstAccount(List<PaymentAccount> accounts) {
    if (_initialized) return;
    _initialized = true;
    if (accounts.isEmpty) {
      _isDefault = true;
    }
  }

  Future<void> _save(AppLocalizations l10n) async {
    setState(() {
      _nicknameError = null;
      _upiError = null;
      _bankNameError = null;
      _phoneError = null;
    });

    final nickname = _nicknameController.text.trim();
    bool hasError = false;

    if (nickname.isEmpty) {
      _nicknameError = l10n.errNickname;
      hasError = true;
    }

    if (_type == 'upi') {
      final upiId = _upiController.text.trim();
      if (upiId.isEmpty || !_upiRegex.hasMatch(upiId)) {
        _upiError = l10n.errUpiId;
        hasError = true;
      }
    } else {
      final bankName = _bankNameController.text.trim();
      if (bankName.isEmpty) {
        _bankNameError = l10n.errBankName;
        hasError = true;
      }
    }

    final phoneDigits = PhoneFormat.extractDigits(_phoneController.text);
    if (phoneDigits.isNotEmpty && !PhoneFormat.isValidIndianMobile(phoneDigits)) {
      _phoneError = l10n.phoneInvalid;
      hasError = true;
    }

    if (hasError) {
      setState(() {});
      return;
    }

    final activePg = ref.read(activePgProvider);
    final pgId = activePg?.pgId;
    if (pgId == null) return;

    setState(() => _isSubmitting = true);

    final String? linkedPhone =
        phoneDigits.isNotEmpty ? PhoneFormat.normalize(phoneDigits) : null;

    final account = PaymentAccount(
      id: widget.accountId ?? '',
      pgId: pgId,
      nickname: nickname,
      kind: _type,
      upiVpa: _type == 'upi' ? _upiController.text.trim() : null,
      bankName: _type == 'bank' ? _bankNameController.text.trim() : null,
      accountLast4: _type == 'bank' && _last4Controller.text.trim().isNotEmpty
          ? _last4Controller.text.trim()
          : null,
      holderName: _type == 'upi'
          ? (_holderNameController.text.trim().isNotEmpty
              ? _holderNameController.text.trim()
              : null)
          : (_bankHolderController.text.trim().isNotEmpty
              ? _bankHolderController.text.trim()
              : null),
      linkedPhone: linkedPhone,
      isDefault: _isActive && _isDefault,
      isActive: _isActive,
    );

    try {
      final repo = ref.read(ownerRepositoryProvider);
      if (widget.accountId != null) {
        await repo.updatePaymentAccount(account);
      } else {
        await repo.createPaymentAccount(account);
      }

      ref.invalidate(paymentAccountsProvider);
      if (widget.accountId != null) {
        ref.invalidate(paymentAccountDetailProvider(widget.accountId!));
      }

      if (mounted) {
        context.pop();
      }
    } on DuplicateNicknameException {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _nicknameError = l10n.errAccountNickname;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditMode = widget.accountId != null;

    if (isEditMode) {
      final accountAsync =
          ref.watch(paymentAccountDetailProvider(widget.accountId!));
      return accountAsync.when(
        loading: () => Scaffold(
          backgroundColor: AppColors.ground,
          appBar: AppTopBar.back(
            title: l10n.accountsTitle,
          ),
          body: const Padding(
            padding: EdgeInsets.only(top: AppSpace.x12),
            child: SkeletonList(),
          ),
        ),
        error: (error, _) => Scaffold(
          backgroundColor: AppColors.ground,
          appBar: AppTopBar.back(
            title: l10n.accountsTitle,
          ),
          body: Center(
            child: ErrorState(
              title: l10n.errorGeneric,
              message: error.toString().replaceFirst('Exception: ', ''),
              onRetry: () => ref.invalidate(
                paymentAccountDetailProvider(widget.accountId!),
              ),
            ),
          ),
        ),
        data: (account) {
          if (account == null) {
            return Scaffold(
              backgroundColor: AppColors.ground,
              appBar: AppTopBar.back(
                title: l10n.accountsTitle,
              ),
              body: const SizedBox.shrink(),
            );
          }
          _initFromAccount(account);
          return _buildForm(context, l10n, isEditMode: true);
        },
      );
    } else {
      final accountsAsync = ref.watch(paymentAccountsProvider);
      accountsAsync.whenData((accounts) {
        _initDefaultOnFirstAccount(accounts);
      });
      return _buildForm(context, l10n, isEditMode: false);
    }
  }

  Widget _buildForm(
    BuildContext context,
    AppLocalizations l10n, {
    required bool isEditMode,
  }) {
    return Scaffold(
      backgroundColor: AppColors.ground,
      appBar: AppTopBar.back(
        title: l10n.accountsTitle,
      ),
      body: ListView(
        padding: const EdgeInsets.only(
          top: AppSpace.x12,
          bottom: AppSpace.x32,
        ),
        children: [
          // Sheet 1: Input Fields
          LedgerSheet(
            padding: const EdgeInsets.all(AppSpace.x16),
            children: [
              Text(
                l10n.accountType,
                style: AppText.label,
              ),
              const SizedBox(height: 6),
              OptionRow<String>(
                options: [
                  OptionRowItem(
                    value: 'upi',
                    label: l10n.accountTypeUpi,
                  ),
                  OptionRowItem(
                    value: 'bank',
                    label: l10n.accountTypeBank,
                  ),
                ],
                selectedValue: _type,
                onChanged: (val) {
                  setState(() {
                    _type = val;
                    _upiError = null;
                    _bankNameError = null;
                  });
                },
              ),
              const SizedBox(height: AppSpace.x16),
              AppTextField(
                label: l10n.accountNickname,
                controller: _nicknameController,
                errorText: _nicknameError,
                onChanged: (_) {
                  if (_nicknameError != null) {
                    setState(() => _nicknameError = null);
                  }
                },
              ),
              const SizedBox(height: AppSpace.x16),
              if (_type == 'upi') ...[
                AppTextField(
                  label: l10n.accountUpiId,
                  controller: _upiController,
                  errorText: _upiError,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) {
                    if (_upiError != null) {
                      setState(() => _upiError = null);
                    }
                  },
                ),
                const SizedBox(height: AppSpace.x16),
                AppTextField(
                  label: l10n.accountHolderName,
                  controller: _holderNameController,
                  helperText: l10n.accountHolderHelper,
                ),
              ] else ...[
                AppTextField(
                  label: l10n.accountBankName,
                  controller: _bankNameController,
                  errorText: _bankNameError,
                  onChanged: (_) {
                    if (_bankNameError != null) {
                      setState(() => _bankNameError = null);
                    }
                  },
                ),
                const SizedBox(height: AppSpace.x16),
                AppTextField(
                  label: l10n.accountLast4,
                  controller: _last4Controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                ),
                const SizedBox(height: AppSpace.x16),
                AppTextField(
                  label: l10n.accountBankHolder,
                  controller: _bankHolderController,
                ),
              ],
              const SizedBox(height: AppSpace.x16),
              PhoneField(
                label: l10n.accountLinkedPhone,
                controller: _phoneController,
                errorText: _phoneError,
                onChanged: (_) {
                  if (_phoneError != null) {
                    setState(() => _phoneError = null);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpace.x12),
          // Sheet 2: Switches
          LedgerSheet(
            padding: EdgeInsets.zero,
            children: [
              SwitchRow(
                label: l10n.accountUseDefault,
                value: _isDefault,
                showDivider: isEditMode,
                onChanged: _isActive
                    ? (val) {
                        setState(() => _isDefault = val);
                      }
                    : null,
              ),
              if (isEditMode)
                SwitchRow(
                  label: l10n.accountActive,
                  value: _isActive,
                  showDivider: false,
                  onChanged: (val) {
                    setState(() {
                      _isActive = val;
                      if (!_isActive) {
                        _isDefault = false;
                      }
                    });
                  },
                ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(
              color: AppColors.hairline,
              width: AppSize.hairline,
            ),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          AppSpace.x16,
          AppSpace.x16,
          AppSpace.x16,
          AppSpace.x16 + MediaQuery.paddingOf(context).bottom,
        ),
        child: AppButton.primary(
          label: l10n.accountSave,
          expand: true,
          loading: _isSubmitting,
          onPressed: () => _save(l10n),
        ),
      ),
    );
  }
}

