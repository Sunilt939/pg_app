import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/format/phone.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/natural_sort.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snack.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/date_field.dart';
import '../../../../core/widgets/ledger_sheet.dart';
import '../../../../core/widgets/money_field.dart';
import '../../../../core/widgets/option_sheet.dart';
import '../../../../core/widgets/phone_field.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/select_field.dart';
import '../../../../core/widgets/switch_row.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/bed_occupancy.dart';
import '../../domain/owner_repository.dart';
import '../providers/owner_provider.dart';

class AddGuestScreen extends ConsumerStatefulWidget {
  final String? initialBedId;

  const AddGuestScreen({
    super.key,
    this.initialBedId,
  });

  @override
  ConsumerState<AddGuestScreen> createState() => _AddGuestScreenState();
}

class _AddGuestScreenState extends ConsumerState<AddGuestScreen> {
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();

  final _phoneFocusNode = FocusNode();
  final _nameFocusNode = FocusNode();

  bool _phoneLostFocus = false;
  bool _nameLostFocus = false;

  String? _selectedBedId;
  String? _selectedBedDisplay;
  bool _bedSelectedExplicitly = false;

  DateTime _joinDate = DateTime.now();
  int? _rentPaise;
  int _depositPaise = 0;

  late int _billingDay;
  bool _billingDayManuallyPicked = false;

  bool _alreadyStaying = false;
  DateTime _billingStartsFrom = DateTime.now();
  bool _depositAlreadyPaid = true;

  bool _submitted = false;
  bool _isSubmitting = false;

  String? _phoneDbError;
  String? _bedDbError;

  bool _initialBedLoaded = false;

  static const _noBedOptionValue = '__NO_BED__';

  @override
  void initState() {
    super.initState();
    _billingDay = _joinDate.day > 28 ? 28 : _joinDate.day;

    _phoneFocusNode.addListener(() {
      if (!_phoneFocusNode.hasFocus && !_phoneLostFocus) {
        setState(() => _phoneLostFocus = true);
      }
    });

    _nameFocusNode.addListener(() {
      if (!_nameFocusNode.hasFocus && !_nameLostFocus) {
        setState(() => _nameLostFocus = true);
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _phoneFocusNode.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _syncInitialBed(List<BedOccupancy> beds, AppLocalizations l10n) {
    if (_initialBedLoaded || widget.initialBedId == null || beds.isEmpty) return;

    final match = beds.where((b) => b.bedId == widget.initialBedId).firstOrNull;
    if (match != null) {
      _initialBedLoaded = true;
      _selectedBedId = match.bedId;
      _selectedBedDisplay = l10n.guestBedOption(match.roomNumber, match.bedLabel);
      _bedSelectedExplicitly = true;
    }
  }

  Future<void> _pickBed(
    BuildContext context,
    AppLocalizations l10n,
    List<BedOccupancy> allBeds,
  ) async {
    final freeBeds = allBeds
        .where((b) => b.isFree && b.bedIsActive && b.roomIsActive)
        .toList()
      ..sort((a, b) {
        final cmpRoom = naturalCompare(a.roomNumber, b.roomNumber);
        if (cmpRoom != 0) return cmpRoom;
        return naturalCompare(a.bedLabel, b.bedLabel);
      });

    final options = <OptionSheetItem<String>>[
      OptionSheetItem<String>(
        value: _noBedOptionValue,
        title: l10n.guestBedNone,
      ),
      for (final bed in freeBeds)
        OptionSheetItem<String>(
          value: bed.bedId,
          title: l10n.guestBedOption(bed.roomNumber, bed.bedLabel),
          subtitle: bed.roomTypeLabel,
        ),
    ];

    final currentSelectedValue = _selectedBedId ?? (_bedSelectedExplicitly ? _noBedOptionValue : null);

    final picked = await OptionSheet.show<String>(
      context: context,
      title: l10n.guestBedPick,
      options: options,
      selectedValue: currentSelectedValue,
    );

    if (picked != null) {
      setState(() {
        _bedDbError = null;
        _bedSelectedExplicitly = true;
        if (picked == _noBedOptionValue) {
          _selectedBedId = null;
          _selectedBedDisplay = l10n.guestBedNone;
        } else {
          _selectedBedId = picked;
          final match = freeBeds.firstWhere((b) => b.bedId == picked);
          _selectedBedDisplay = l10n.guestBedOption(match.roomNumber, match.bedLabel);
        }
      });
    }
  }

  Future<void> _pickBillingDay(BuildContext context, AppLocalizations l10n) async {
    final options = <OptionSheetItem<int>>[
      for (int day = 1; day <= 28; day++)
        OptionSheetItem<int>(
          value: day,
          title: '$day',
        ),
    ];

    final picked = await OptionSheet.show<int>(
      context: context,
      title: l10n.guestBillingDay,
      options: options,
      selectedValue: _billingDay,
    );

    if (picked != null) {
      setState(() {
        _billingDay = picked;
        _billingDayManuallyPicked = true;
      });
    }
  }

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
      _phoneDbError = null;
      _bedDbError = null;
    });

    final l10n = AppLocalizations.of(context)!;
    final phoneText = _phoneController.text;
    final phoneDigits = PhoneFormat.extractDigits(phoneText);
    final isPhoneValid = PhoneFormat.isValidIndianMobile(phoneText);
    final isNameValid = _nameController.text.trim().isNotEmpty;
    final isRentValid = _rentPaise != null && _rentPaise! > 0;

    if (!isPhoneValid || !isNameValid || !isRentValid) {
      return;
    }

    final activePg = ref.read(activePgProvider);
    if (activePg == null) return;

    setState(() => _isSubmitting = true);

    try {
      final ownerRepo = ref.read(ownerRepositoryProvider);
      final normalizedPhone = PhoneFormat.normalize(phoneDigits);
      final fullName = _nameController.text.trim();

      await ownerRepo.createStay(
        pgId: activePg.pgId,
        phone: normalizedPhone,
        fullName: fullName,
        bedId: _selectedBedId,
        joinDate: _joinDate,
        monthlyRentPaise: _rentPaise!,
        depositPaise: _depositPaise,
        billingDay: _billingDay,
        billingStartsOn: _alreadyStaying ? _billingStartsFrom : null,
        depositAlreadyPaid: _alreadyStaying ? _depositAlreadyPaid : false,
      );

      ref.invalidate(bedOccupancyProvider);

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      // Show invite bottom sheet
      await AppBottomSheet.show(
        context: context,
        builder: (sheetContext) => _buildInviteSheet(
          sheetContext,
          l10n: l10n,
          name: fullName,
          phone: PhoneFormat.format(normalizedPhone),
          pgName: activePg.name,
        ),
      );

      if (mounted) {
        if (Navigator.of(context).canPop()) {
          context.pop();
        }
      }
    } on DuplicateGuestStayException {
      if (!mounted) return;
      setState(() {
        _phoneDbError = l10n.errGuestExists;
      });
      AppSnack.show(context, message: l10n.errGuestExists);
    } on BedAlreadyTakenException {
      if (!mounted) return;
      setState(() {
        _bedDbError = l10n.errBedTaken;
      });
      AppSnack.show(context, message: l10n.errBedTaken);
    } catch (e) {
      if (!mounted) return;
      final errorStr = e.toString();
      if (errorStr.contains('42501')) {
        AppSnack.show(context, message: l10n.errorNotAllowed);
      } else {
        AppSnack.show(
          context,
          message: errorStr.replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildInviteSheet(
    BuildContext sheetContext, {
    required AppLocalizations l10n,
    required String name,
    required String phone,
    required String pgName,
  }) {
    return AppBottomSheet(
      title: l10n.inviteTitle,
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16),
      bottomAction: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppButton.primary(
            label: l10n.inviteAction,
            expand: true,
            onPressed: () {
              final message = l10n.inviteMessage(
                name,
                pgName,
                AppConfig.appName,
              );
              final textToShare = AppConfig.playStoreUrl.isNotEmpty
                  ? '$message\n${AppConfig.playStoreUrl}'
                  : message;
              Share.share(textToShare);
            },
          ),
          const SizedBox(height: AppSpace.x12),
          AppButton.text(
            label: l10n.actionDone,
            expand: true,
            onPressed: () => Navigator.of(sheetContext).pop(),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.x16),
        child: Text(
          l10n.inviteBody(name, phone),
          style: AppText.body,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bedsAsync = ref.watch(bedOccupancyProvider);

    final allBeds = bedsAsync.valueOrNull ?? [];
    _syncInitialBed(allBeds, l10n);

    final showPhoneValidation = _submitted || _phoneLostFocus;
    final isPhoneValid = PhoneFormat.isValidIndianMobile(_phoneController.text);
    final phoneError = _phoneDbError ??
        (showPhoneValidation && !isPhoneValid ? l10n.phoneInvalid : null);

    final showNameValidation = _submitted || _nameLostFocus;
    final nameError = showNameValidation && _nameController.text.trim().isEmpty
        ? l10n.errGuestName
        : null;

    final rentError = _submitted && (_rentPaise == null || _rentPaise! <= 0)
        ? l10n.errRent
        : null;

    final bedError = _bedDbError;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final joinDay = DateTime(_joinDate.year, _joinDate.month, _joinDate.day);
    final isPastJoinDate = joinDay.isBefore(today);

    return Scaffold(
      backgroundColor: AppColors.ground,
      appBar: AppTopBar.back(
        title: l10n.addGuestTitle,
        onLeadingPressed: () => context.pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.only(
          top: AppSpace.x16,
          bottom: AppSpace.x32,
        ),
        children: [
          SectionHeader(title: l10n.addGuestSection),
          LedgerSheet(
            margin: const EdgeInsets.only(bottom: AppSpace.x16),
            padding: const EdgeInsets.all(AppSpace.x16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PhoneField(
                  label: l10n.guestMobile,
                  helperText: l10n.guestMobileHelper,
                  errorText: phoneError,
                  controller: _phoneController,
                  focusNode: _phoneFocusNode,
                  onChanged: (_) {
                    if (_phoneDbError != null) {
                      setState(() => _phoneDbError = null);
                    } else if (showPhoneValidation) {
                      setState(() {});
                    }
                  },
                ),
                const SizedBox(height: AppSpace.x16),
                AppTextField(
                  label: l10n.guestName,
                  errorText: nameError,
                  controller: _nameController,
                  focusNode: _nameFocusNode,
                  onChanged: (_) {
                    if (showNameValidation) setState(() {});
                  },
                ),
              ],
            ),
          ),

          SectionHeader(title: l10n.addGuestStaySection),
          LedgerSheet(
            margin: const EdgeInsets.only(bottom: AppSpace.x16),
            padding: const EdgeInsets.all(AppSpace.x16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectField(
                  label: l10n.guestBed,
                  hint: l10n.guestBedPick,
                  value: _selectedBedDisplay,
                  errorText: bedError,
                  onTap: () => _pickBed(context, l10n, allBeds),
                ),
                const SizedBox(height: AppSpace.x16),
                DateField(
                  label: l10n.guestJoinDate,
                  value: _joinDate,
                  helperText: isPastJoinDate ? l10n.guestJoinDatePastNotice : null,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                  onChanged: (newDate) {
                    setState(() {
                      _joinDate = newDate;
                      if (!_billingDayManuallyPicked) {
                        _billingDay = newDate.day > 28 ? 28 : newDate.day;
                      }
                    });
                  },
                ),
              ],
            ),
          ),

          SectionHeader(title: l10n.addGuestMoneySection),
          LedgerSheet(
            margin: const EdgeInsets.only(bottom: AppSpace.x16),
            padding: const EdgeInsets.all(AppSpace.x16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MoneyField(
                  label: l10n.guestRent,
                  initialPaise: _rentPaise,
                  errorText: rentError,
                  onChanged: (val) {
                    _rentPaise = val;
                    if (_submitted) setState(() {});
                  },
                ),
                const SizedBox(height: AppSpace.x16),
                MoneyField(
                  label: l10n.guestDeposit,
                  initialPaise: _depositPaise,
                  onChanged: (val) => _depositPaise = val,
                ),
                const SizedBox(height: AppSpace.x16),
                SelectField(
                  label: l10n.guestBillingDay,
                  value: '$_billingDay',
                  helperText: l10n.billingDayHelper,
                  onTap: () => _pickBillingDay(context, l10n),
                ),
              ],
            ),
          ),

          LedgerSheet(
            margin: const EdgeInsets.only(bottom: AppSpace.x16),
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchRow(
                  label: l10n.alreadyStaying,
                  helper: l10n.alreadyStayingHelper,
                  value: _alreadyStaying,
                  showDivider: _alreadyStaying,
                  onChanged: (val) => setState(() => _alreadyStaying = val),
                ),
                if (_alreadyStaying) ...[
                  Padding(
                    padding: const EdgeInsets.all(AppSpace.x16),
                    child: DateField(
                      label: l10n.billingStartsFrom,
                      value: _billingStartsFrom,
                      helperText: l10n.billingStartHelper,
                      onChanged: (val) => setState(() => _billingStartsFrom = val),
                    ),
                  ),
                  SwitchRow(
                    label: l10n.depositReceived,
                    helper: l10n.depositReceivedHelper,
                    value: _depositAlreadyPaid,
                    showDivider: false,
                    onChanged: (val) => setState(() => _depositAlreadyPaid = val),
                  ),
                ],
              ],
            ),
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
        padding: EdgeInsets.only(
          left: AppSpace.x16,
          right: AppSpace.x16,
          top: AppSpace.x16,
          bottom: AppSpace.x16 + MediaQuery.paddingOf(context).bottom,
        ),
        child: AppButton.primary(
          label: l10n.addGuestAction,
          loading: _isSubmitting,
          expand: true,
          onPressed: _submit,
        ),
      ),
    );
  }
}

