import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format/phone.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snack.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/key_value_row.dart';
import '../../../../core/widgets/ledger_sheet.dart';
import '../../../../core/widgets/option_row.dart';
import '../../../../core/widgets/option_sheet.dart';
import '../../../../core/widgets/phone_field.dart';
import '../../../../core/widgets/select_field.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/city.dart';
import '../../domain/pg_details.dart';
import '../providers/owner_provider.dart';

const String _emDash = '—';

class OwnerSettingsScreen extends ConsumerWidget {
  const OwnerSettingsScreen({super.key});

  static String _genderLabel(AppLocalizations l10n, String policy) {
    switch (policy) {
      case 'men':
        return l10n.genderMen;
      case 'women':
        return l10n.genderWomen;
      case 'any':
      default:
        return l10n.genderAny;
    }
  }

  void _editName(BuildContext context, PgDetails details) {
    AppBottomSheet.show<void>(
      context: context,
      builder: (sheetContext) => _EditPgNameSheet(details: details),
    );
  }

  void _editGender(BuildContext context, PgDetails details) {
    AppBottomSheet.show<void>(
      context: context,
      builder: (sheetContext) => _EditPgGenderSheet(details: details),
    );
  }

  void _editAddress(BuildContext context, PgDetails details) {
    AppBottomSheet.show<void>(
      context: context,
      builder: (sheetContext) => _EditPgAddressSheet(details: details),
    );
  }

  void _editContact(BuildContext context, PgDetails details) {
    AppBottomSheet.show<void>(
      context: context,
      builder: (sheetContext) => _EditPgContactSheet(details: details),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final detailsAsync = ref.watch(pgDetailsProvider);

    return Scaffold(
      backgroundColor: AppColors.ground,
      appBar: AppTopBar.back(
        title: l10n.pgDetailsTitle,
      ),
      body: detailsAsync.when(
        loading: () => ListView(
          padding: const EdgeInsets.only(top: AppSpace.x16, bottom: AppSpace.x32),
          children: const [
            LedgerSheet(
              children: [
                SkeletonList(itemCount: 4),
              ],
            ),
          ],
        ),
        error: (err, stack) => Center(
          child: ErrorState(
            title: l10n.errorGeneric,
            message: l10n.errorNetwork,
            onRetry: () => ref.refresh(pgDetailsProvider),
          ),
        ),
        data: (details) {
          if (details == null) {
            return Center(
              child: ErrorState(
                title: l10n.errorGeneric,
                message: l10n.errorNetwork,
                onRetry: () => ref.refresh(pgDetailsProvider),
              ),
            );
          }

          final displayAddress =
              details.formattedAddress.isEmpty ? _emDash : details.formattedAddress;
          final displayContact =
              details.contactPhone != null && details.contactPhone!.isNotEmpty
                  ? PhoneFormat.format(details.contactPhone!)
                  : _emDash;

          return ListView(
            padding: const EdgeInsets.only(top: AppSpace.x16, bottom: AppSpace.x32),
            children: [
              LedgerSheet(
                children: [
                  KeyValueRow(
                    label: l10n.addPgName,
                    value: details.name,
                    trailing: const Icon(
                      AppIcons.chevronRight,
                      size: 20,
                      color: AppColors.muted,
                    ),
                    showDivider: true,
                    onTap: () => _editName(context, details),
                  ),
                  KeyValueRow(
                    label: l10n.addPgWho,
                    value: _genderLabel(l10n, details.genderPolicy),
                    trailing: const Icon(
                      AppIcons.chevronRight,
                      size: 20,
                      color: AppColors.muted,
                    ),
                    showDivider: true,
                    onTap: () => _editGender(context, details),
                  ),
                  KeyValueRow(
                    label: l10n.addPgAddress,
                    value: displayAddress,
                    customValueWidget: Text(
                      displayAddress,
                      style: AppText.body,
                      textAlign: TextAlign.right,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(
                      AppIcons.chevronRight,
                      size: 20,
                      color: AppColors.muted,
                    ),
                    showDivider: true,
                    onTap: () => _editAddress(context, details),
                  ),
                  KeyValueRow(
                    label: l10n.addPgContact,
                    value: displayContact,
                    trailing: const Icon(
                      AppIcons.chevronRight,
                      size: 20,
                      color: AppColors.muted,
                    ),
                    showDivider: false,
                    onTap: () => _editContact(context, details),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EditPgNameSheet extends ConsumerStatefulWidget {
  final PgDetails details;

  const _EditPgNameSheet({required this.details});

  @override
  ConsumerState<_EditPgNameSheet> createState() => _EditPgNameSheetState();
}

class _EditPgNameSheetState extends ConsumerState<_EditPgNameSheet> {
  late final TextEditingController _controller;
  String? _errorText;
  bool _isLoading = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.details.name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validate(AppLocalizations l10n) {
    if (_controller.text.trim().isEmpty) {
      return l10n.errPgName;
    }
    return null;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _submitted = true);
    final err = _validate(l10n);
    if (err != null) {
      setState(() => _errorText = err);
      return;
    }

    setState(() {
      _errorText = null;
      _isLoading = true;
    });

    try {
      final newName = _controller.text.trim();
      final repo = ref.read(ownerRepositoryProvider);
      await repo.updatePgName(pgId: widget.details.id, name: newName);

      ref.invalidate(pgDetailsProvider);
      ref.invalidate(ownerPgsProvider);
      ref.read(authContextProvider.notifier).refreshContext();

      if (mounted) {
        Navigator.of(context).pop();
        AppSnack.show(context, message: l10n.pgDetailsSaved);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final msg = e.toString().contains('42501')
            ? l10n.errorNotAllowed
            : l10n.errorGeneric;
        AppSnack.show(context, message: msg);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppBottomSheet(
      title: l10n.addPgName,
      bottomAction: AppButton.primary(
        label: l10n.actionSave,
        loading: _isLoading,
        expand: true,
        onPressed: _save,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            label: l10n.addPgName,
            controller: _controller,
            errorText: _errorText,
            maxLength: 60,
            autofocus: true,
            onChanged: (_) {
              if (_submitted && _errorText != null) {
                setState(() => _errorText = _validate(l10n));
              }
            },
          ),
          const SizedBox(height: AppSpace.x16),
        ],
      ),
    );
  }
}

class _EditPgGenderSheet extends ConsumerStatefulWidget {
  final PgDetails details;

  const _EditPgGenderSheet({required this.details});

  @override
  ConsumerState<_EditPgGenderSheet> createState() => _EditPgGenderSheetState();
}

class _EditPgGenderSheetState extends ConsumerState<_EditPgGenderSheet> {
  late String _selectedGender;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedGender = widget.details.genderPolicy;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(ownerRepositoryProvider);
      await repo.updatePgGenderPolicy(
        pgId: widget.details.id,
        genderPolicy: _selectedGender,
      );

      ref.invalidate(pgDetailsProvider);

      if (mounted) {
        Navigator.of(context).pop();
        AppSnack.show(context, message: l10n.pgDetailsSaved);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final msg = e.toString().contains('42501')
            ? l10n.errorNotAllowed
            : l10n.errorGeneric;
        AppSnack.show(context, message: msg);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppBottomSheet(
      title: l10n.addPgWho,
      bottomAction: AppButton.primary(
        label: l10n.actionSave,
        loading: _isLoading,
        expand: true,
        onPressed: _save,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OptionRow<String>(
            selectedValue: _selectedGender,
            options: [
              OptionRowItem(value: 'men', label: l10n.genderMen),
              OptionRowItem(value: 'women', label: l10n.genderWomen),
              OptionRowItem(value: 'any', label: l10n.genderAny),
            ],
            onChanged: (val) {
              setState(() => _selectedGender = val);
            },
          ),
          const SizedBox(height: AppSpace.x16),
        ],
      ),
    );
  }
}

class _EditPgAddressSheet extends ConsumerStatefulWidget {
  final PgDetails details;

  const _EditPgAddressSheet({required this.details});

  @override
  ConsumerState<_EditPgAddressSheet> createState() => _EditPgAddressSheetState();
}

class _EditPgAddressSheetState extends ConsumerState<_EditPgAddressSheet> {
  late final TextEditingController _addressController;
  late final TextEditingController _areaController;
  late final TextEditingController _pincodeController;
  City? _selectedCity;

  String? _addressError;
  String? _cityError;
  String? _pincodeError;

  bool _submitted = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: widget.details.line1);
    _areaController = TextEditingController(text: widget.details.area ?? '');
    _pincodeController = TextEditingController(text: widget.details.pincode ?? '');
    if (widget.details.cityId > 0 && widget.details.cityName.isNotEmpty) {
      _selectedCity = City(
        id: widget.details.cityId,
        name: widget.details.cityName,
        stateName: widget.details.stateName,
      );
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _areaController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  String? _validateAddress(AppLocalizations l10n) {
    if (_addressController.text.trim().isEmpty) {
      return l10n.errPgAddress;
    }
    return null;
  }

  String? _validateCity(AppLocalizations l10n) {
    if (_selectedCity == null) {
      return l10n.addPgCityPick;
    }
    return null;
  }

  String? _validatePincode(AppLocalizations l10n) {
    final text = _pincodeController.text.trim();
    if (text.isEmpty) return null;
    final regex = RegExp(r'^[1-9][0-9]{5}$');
    if (!regex.hasMatch(text)) {
      return l10n.errPincode;
    }
    return null;
  }

  Future<void> _pickCity() async {
    try {
      final cities = await ref.read(citiesProvider.future);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final items = cities
          .map(
            (c) => OptionSheetItem<City>(
              value: c,
              title: c.name,
              subtitle: c.stateName,
            ),
          )
          .toList();

      final selected = await OptionSheet.show<City>(
        context: context,
        title: l10n.addPgCityPick,
        options: items,
        selectedValue: _selectedCity,
        showSearch: true,
      );

      if (selected != null && mounted) {
        setState(() {
          _selectedCity = selected;
          if (_submitted) {
            _cityError = _validateCity(l10n);
          }
        });
      }
    } catch (_) {
      if (mounted) {
        AppSnack.show(
          context,
          message: AppLocalizations.of(context)!.errorGeneric,
        );
      }
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _submitted = true);

    final addrErr = _validateAddress(l10n);
    final cityErr = _validateCity(l10n);
    final pinErr = _validatePincode(l10n);

    setState(() {
      _addressError = addrErr;
      _cityError = cityErr;
      _pincodeError = pinErr;
    });

    if (addrErr != null || cityErr != null || pinErr != null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final line1 = _addressController.text.trim();
      final area = _areaController.text.trim();
      final pincode = _pincodeController.text.trim();

      final repo = ref.read(ownerRepositoryProvider);
      await repo.updatePgAddress(
        pgId: widget.details.id,
        addressId: widget.details.addressId ?? '',
        line1: line1,
        area: area.isNotEmpty ? area : null,
        cityId: _selectedCity!.id,
        pincode: pincode.isNotEmpty ? pincode : null,
      );

      ref.invalidate(pgDetailsProvider);

      if (mounted) {
        Navigator.of(context).pop();
        AppSnack.show(context, message: l10n.pgDetailsSaved);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final msg = e.toString().contains('42501')
            ? l10n.errorNotAllowed
            : l10n.errorGeneric;
        AppSnack.show(context, message: msg);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppBottomSheet(
      title: l10n.addPgAddress,
      bottomAction: AppButton.primary(
        label: l10n.actionSave,
        loading: _isLoading,
        expand: true,
        onPressed: _save,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            label: l10n.addPgAddress,
            hint: l10n.addPgAddressHint,
            controller: _addressController,
            errorText: _addressError,
            onChanged: (_) {
              if (_submitted && _addressError != null) {
                setState(() => _addressError = _validateAddress(l10n));
              }
            },
          ),
          const SizedBox(height: AppSpace.x16),
          AppTextField(
            label: l10n.addPgArea,
            hint: l10n.addPgAreaHint,
            controller: _areaController,
          ),
          const SizedBox(height: AppSpace.x16),
          SelectField(
            label: l10n.addPgCity,
            hint: l10n.addPgCityPick,
            value: _selectedCity?.name,
            errorText: _cityError,
            onTap: _pickCity,
          ),
          const SizedBox(height: AppSpace.x16),
          AppTextField(
            label: l10n.addPgPincode,
            controller: _pincodeController,
            errorText: _pincodeError,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            onChanged: (_) {
              if (_submitted && _pincodeError != null) {
                setState(() => _pincodeError = _validatePincode(l10n));
              }
            },
          ),
          const SizedBox(height: AppSpace.x16),
        ],
      ),
    );
  }
}

class _EditPgContactSheet extends ConsumerStatefulWidget {
  final PgDetails details;

  const _EditPgContactSheet({required this.details});

  @override
  ConsumerState<_EditPgContactSheet> createState() => _EditPgContactSheetState();
}

class _EditPgContactSheetState extends ConsumerState<_EditPgContactSheet> {
  late final TextEditingController _controller;
  String? _errorText;
  bool _isLoading = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    final rawPhone = widget.details.contactPhone ?? '';
    final digits = PhoneFormat.extractDigits(rawPhone);
    String tenDigits = digits;
    if (digits.length == 12 && digits.startsWith('91')) {
      tenDigits = digits.substring(2);
    } else if (digits.length > 10) {
      tenDigits = digits.substring(digits.length - 10);
    }
    final initialContact = tenDigits.isNotEmpty
        ? PhoneInputFormatter()
            .formatEditUpdate(
              TextEditingValue.empty,
              TextEditingValue(text: tenDigits),
            )
            .text
        : '';
    _controller = TextEditingController(text: initialContact);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validate(AppLocalizations l10n) {
    final text = _controller.text.trim();
    if (text.isEmpty) return null;
    final digits = PhoneFormat.extractDigits(text);
    if (!PhoneFormat.isValidIndianMobile(digits)) {
      return l10n.phoneInvalid;
    }
    return null;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _submitted = true);
    final err = _validate(l10n);
    if (err != null) {
      setState(() => _errorText = err);
      return;
    }

    setState(() {
      _errorText = null;
      _isLoading = true;
    });

    try {
      final text = _controller.text.trim();
      final digits = PhoneFormat.extractDigits(text);
      final contactPhone =
          digits.isNotEmpty ? PhoneFormat.normalize(digits) : null;

      final repo = ref.read(ownerRepositoryProvider);
      await repo.updatePgContactPhone(
        pgId: widget.details.id,
        contactPhone: contactPhone,
      );

      ref.invalidate(pgDetailsProvider);

      if (mounted) {
        Navigator.of(context).pop();
        AppSnack.show(context, message: l10n.pgDetailsSaved);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final msg = e.toString().contains('42501')
            ? l10n.errorNotAllowed
            : l10n.errorGeneric;
        AppSnack.show(context, message: msg);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppBottomSheet(
      title: l10n.addPgContact,
      bottomAction: AppButton.primary(
        label: l10n.actionSave,
        loading: _isLoading,
        expand: true,
        onPressed: _save,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PhoneField(
            label: l10n.addPgContact,
            helperText: l10n.addPgContactHelper,
            controller: _controller,
            errorText: _errorText,
            autofocus: true,
            onChanged: (_) {
              if (_submitted && _errorText != null) {
                setState(() => _errorText = _validate(l10n));
              }
            },
          ),
          const SizedBox(height: AppSpace.x16),
        ],
      ),
    );
  }
}
