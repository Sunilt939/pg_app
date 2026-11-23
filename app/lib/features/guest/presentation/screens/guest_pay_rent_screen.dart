import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/format/money.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snack.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/ledger_sheet.dart';
import '../../../../core/widgets/money_field.dart';
import '../../../../core/widgets/option_sheet.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../owner/domain/guest_list_item.dart';
import '../../../owner/domain/payment_account.dart';
import '../providers/guest_provider.dart';
import '../widgets/guest_report_payment_sheet.dart';

class GuestPayRentScreen extends ConsumerStatefulWidget {
  final String stayId;
  final int? initialAmountPaise;
  final Future<bool> Function(Uri uri)? onLaunchUpi;

  const GuestPayRentScreen({
    super.key,
    required this.stayId,
    this.initialAmountPaise,
    this.onLaunchUpi,
  });

  @override
  ConsumerState<GuestPayRentScreen> createState() => _GuestPayRentScreenState();
}

class _GuestPayRentScreenState extends ConsumerState<GuestPayRentScreen>
    with WidgetsBindingObserver {
  late final TextEditingController _amountController;
  int _amountPaise = 0;
  bool _initializedAmount = false;
  PaymentAccount? _selectedAccount;
  bool _upiPaymentInitiated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _amountController = TextEditingController();
    if (widget.initialAmountPaise != null && widget.initialAmountPaise! > 0) {
      _amountPaise = widget.initialAmountPaise!;
      _amountController.text =
          formatRupeesWithGrouping(widget.initialAmountPaise! ~/ 100);
      _initializedAmount = true;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _amountController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _upiPaymentInitiated) {
      _upiPaymentInitiated = false;
      _openVariantAOnReturn();
    }
  }

  Future<void> _openVariantAOnReturn() async {
    final stay = ref.read(guestStayProvider(widget.stayId)).value;
    if (stay == null || !mounted) return;

    final accounts =
        ref.read(guestUpiAccountsProvider(stay.pgId)).value ?? const [];
    final chosenAccount = _resolveSelectedAccount(accounts);
    if (chosenAccount == null) return;

    final success = await GuestReportPaymentSheet.showVariantA(
      context: context,
      stayId: stay.stayId,
      pgId: stay.pgId,
      amountPaise: _amountPaise,
      upiAccount: chosenAccount,
    );
    if (success == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _initAmountFromStay(GuestListItem stay) {
    if (_initializedAmount) return;
    _initializedAmount = true;

    final dueNow = stay.dueNowPaise ?? 0;
    final overdue = stay.overduePaise;
    final nextDue = stay.nextDuePaise ?? 0;

    final defaultPaise = overdue > 0
        ? (dueNow > 0 ? dueNow : overdue)
        : (dueNow > 0 ? dueNow : nextDue);

    if (defaultPaise > 0) {
      _amountPaise = defaultPaise;
      _amountController.text =
          formatRupeesWithGrouping(defaultPaise ~/ 100);
    }
  }

  PaymentAccount? _resolveSelectedAccount(List<PaymentAccount> accounts) {
    if (accounts.isEmpty) return null;
    if (_selectedAccount != null &&
        accounts.any((a) => a.id == _selectedAccount!.id)) {
      return _selectedAccount;
    }
    return accounts.where((a) => a.isDefault).firstOrNull ??
        accounts.firstOrNull;
  }

  Future<void> _pickAccount(
    BuildContext context,
    AppLocalizations l10n,
    List<PaymentAccount> accounts,
    PaymentAccount current,
  ) async {
    final picked = await OptionSheet.show<PaymentAccount>(
      context: context,
      title: l10n.payOtherAccount,
      options: accounts
          .map(
            (a) => OptionSheetItem<PaymentAccount>(
              value: a,
              title: a.nickname,
              subtitle: a.upiVpa,
            ),
          )
          .toList(),
      selectedValue: current,
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedAccount = picked;
      });
    }
  }

  Future<void> _copyUpiId(BuildContext context, String upiId) async {
    final l10n = AppLocalizations.of(context)!;
    await Clipboard.setData(ClipboardData(text: upiId));
    if (context.mounted) {
      AppSnack.show(context, message: l10n.copied);
    }
  }

  Future<void> _payWithUpi(
    BuildContext context,
    GuestListItem stay,
    PaymentAccount account,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final vpa = account.upiVpa ?? '';
    final name = (account.holderName != null &&
            account.holderName!.trim().isNotEmpty)
        ? account.holderName!.trim()
        : stay.pgName;
    final amountFormatted = (_amountPaise / 100).toStringAsFixed(2);

    final uri = Uri(
      scheme: 'upi',
      host: 'pay',
      queryParameters: {
        'pa': vpa,
        'pn': name,
        'am': amountFormatted,
        'cu': 'INR',
        'tn': 'Rent',
      },
    );

    try {
      final launcher = widget.onLaunchUpi ??
          ((u) => launchUrl(u, mode: LaunchMode.externalApplication));
      final success = await launcher(uri);
      if (success) {
        _upiPaymentInitiated = true;
      } else {
        if (context.mounted) {
          AppSnack.show(context, message: l10n.payNoUpiApp);
        }
      }
    } catch (_) {
      if (context.mounted) {
        AppSnack.show(context, message: l10n.payNoUpiApp);
      }
    }
  }

  Widget _buildLoadingSkeleton(BuildContext context, AppLocalizations l10n) {
    return Scaffold(
      backgroundColor: AppColors.ground,
      appBar: AppTopBar.back(title: l10n.payTitle),
      body: const Padding(
        padding: EdgeInsets.all(AppSpace.x16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBlock(
              height: 120,
              borderRadius: BorderRadius.all(AppRadius.sheet),
            ),
            SizedBox(height: AppSpace.x16),
            SkeletonBlock(
              height: 140,
              borderRadius: BorderRadius.all(AppRadius.sheet),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stayAsync = ref.watch(guestStayProvider(widget.stayId));

    return stayAsync.when(
      loading: () => _buildLoadingSkeleton(context, l10n),
      error: (err, stack) => Scaffold(
        backgroundColor: AppColors.ground,
        appBar: AppTopBar.back(title: l10n.payTitle),
        body: Center(
          child: ErrorState(
            title: l10n.errorGeneric,
            message: err.toString(),
            onRetry: () => ref.invalidate(guestStayProvider(widget.stayId)),
          ),
        ),
      ),
      data: (stay) {
        if (stay == null) {
          return Scaffold(
            backgroundColor: AppColors.ground,
            appBar: AppTopBar.back(title: l10n.payTitle),
            body: Center(
              child: EmptyState(
                icon: AppIcons.home,
                title: l10n.noStayTitle,
                body: l10n.homeNoActivity,
              ),
            ),
          );
        }

        _initAmountFromStay(stay);

        final accountsAsync = ref.watch(guestUpiAccountsProvider(stay.pgId));

        return Scaffold(
          backgroundColor: AppColors.ground,
          appBar: AppTopBar.back(title: l10n.payTitle),
          body: accountsAsync.when(
            loading: () => _buildLoadingSkeleton(context, l10n),
            error: (err, stack) => Center(
              child: ErrorState(
                title: l10n.errorGeneric,
                message: err.toString(),
                onRetry: () =>
                    ref.invalidate(guestUpiAccountsProvider(stay.pgId)),
              ),
            ),
            data: (accounts) {
              final chosenAccount = _resolveSelectedAccount(accounts);
              final dueNow = stay.dueNowPaise ?? 0;
              final nextDue = stay.nextDuePaise ?? 0;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpace.x16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Amount Sheet
                    LedgerSheet(
                      padding: const EdgeInsets.all(AppSpace.x16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                          if (dueNow > 0 || nextDue > 0) ...[
                            const SizedBox(height: AppSpace.x8),
                            Wrap(
                              spacing: AppSpace.x8,
                              runSpacing: AppSpace.x8,
                              children: [
                                if (dueNow > 0)
                                  AppButton.text(
                                    label: l10n.payQuickDueNow(
                                      MoneyFormat.format(dueNow),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _amountPaise = dueNow;
                                        _amountController.text =
                                            formatRupeesWithGrouping(
                                                dueNow ~/ 100);
                                      });
                                    },
                                  ),
                                if (nextDue > 0)
                                  AppButton.text(
                                    label: l10n.payQuickNext(
                                      MoneyFormat.format(nextDue),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _amountPaise = nextDue;
                                        _amountController.text =
                                            formatRupeesWithGrouping(
                                                nextDue ~/ 100);
                                      });
                                    },
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpace.x16),

                    // Pay to Sheet or No Account State
                    if (chosenAccount == null)
                      LedgerSheet(
                        padding: const EdgeInsets.all(AppSpace.x24),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                AppIcons.info,
                                size: 28,
                                color: AppColors.muted,
                              ),
                              const SizedBox(height: AppSpace.x8),
                              Text(
                                l10n.payNoAccountTitle,
                                style: AppText.heading,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSpace.x4),
                              Text(
                                l10n.payNoAccountBody,
                                style: AppText.secondary,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      SectionHeader(title: l10n.payTo),
                      LedgerSheet(
                        padding: const EdgeInsets.all(AppSpace.x16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        chosenAccount.nickname,
                                        style: AppText.heading,
                                      ),
                                      const SizedBox(height: AppSpace.x4),
                                      Text(
                                        chosenAccount.upiVpa ?? '',
                                        style: AppText.secondary,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    AppIcons.copy,
                                    size: 20,
                                    color: AppColors.ink,
                                  ),
                                  onPressed: chosenAccount.upiVpa != null &&
                                          chosenAccount.upiVpa!.isNotEmpty
                                      ? () => _copyUpiId(
                                          context, chosenAccount.upiVpa!)
                                      : null,
                                ),
                              ],
                            ),
                            if (accounts.length > 1) ...[
                              const SizedBox(height: AppSpace.x8),
                              AppButton.text(
                                label: l10n.payOtherAccount,
                                onPressed: () => _pickAccount(
                                  context,
                                  l10n,
                                  accounts,
                                  chosenAccount,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          bottomNavigationBar: accountsAsync.maybeWhen(
            data: (accounts) {
              final chosenAccount = _resolveSelectedAccount(accounts);
              final isPayEnabled = _amountPaise > 0 && chosenAccount != null;

              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.x16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppButton.primary(
                        label: l10n.payUpiAction,
                        expand: true,
                        onPressed: isPayEnabled
                            ? () => _payWithUpi(context, stay, chosenAccount)
                            : null,
                      ),
                      const SizedBox(height: AppSpace.x8),
                      Center(
                        child: AppButton.text(
                          label: l10n.payOtherWay,
                          onPressed: () async {
                            final success =
                                await GuestReportPaymentSheet.showVariantB(
                              context: context,
                              stayId: stay.stayId,
                              pgId: stay.pgId,
                              defaultAmountPaise: _amountPaise,
                              defaultUpiAccount: chosenAccount,
                            );
                            if (success == true && context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            orElse: () => null,
          ),
        );
      },
    );
  }
}
