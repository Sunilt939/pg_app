import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/format/phone.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snack.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/ledger_sheet.dart';
import '../../../../core/widgets/option_row.dart';
import '../../../../core/widgets/option_sheet.dart';
import '../../../../core/widgets/phone_field.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/select_field.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/city.dart';
import '../providers/owner_provider.dart';

class AddPgScreen extends ConsumerStatefulWidget {
  const AddPgScreen({super.key});

  @override
  ConsumerState<AddPgScreen> createState() => _AddPgScreenState();
}

class _AddPgScreenState extends ConsumerState<AddPgScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _areaController = TextEditingController();
  final _pincodeController = TextEditingController();
  late final TextEditingController _contactController;

  final _nameFocusNode = FocusNode();
  final _addressFocusNode = FocusNode();
  final _pincodeFocusNode = FocusNode();
  final _contactFocusNode = FocusNode();

  bool _nameLostFocus = false;
  bool _addressLostFocus = false;
  bool _pincodeLostFocus = false;
  bool _contactLostFocus = false;
  bool _contactEdited = false;

  String _genderPolicy = 'any';
  City? _selectedCity;

  bool _submitted = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    final authContext = ref.read(authContextProvider).valueOrNull;
    final rawPhone = authContext?.person?.phone ?? '';
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
    _contactController = TextEditingController(text: initialContact);

    _nameFocusNode.addListener(() {
      if (!_nameFocusNode.hasFocus && !_nameLostFocus) {
        setState(() => _nameLostFocus = true);
      }
    });
    _addressFocusNode.addListener(() {
      if (!_addressFocusNode.hasFocus && !_addressLostFocus) {
        setState(() => _addressLostFocus = true);
      }
    });
    _pincodeFocusNode.addListener(() {
      if (!_pincodeFocusNode.hasFocus && !_pincodeLostFocus) {
        setState(() => _pincodeLostFocus = true);
      }
    });
    _contactFocusNode.addListener(() {
      if (!_contactFocusNode.hasFocus && !_contactLostFocus) {
        setState(() => _contactLostFocus = true);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _areaController.dispose();
    _pincodeController.dispose();
    _contactController.dispose();

    _nameFocusNode.dispose();
    _addressFocusNode.dispose();
    _pincodeFocusNode.dispose();
    _contactFocusNode.dispose();
    super.dispose();
  }

  String? _getNameError(AppLocalizations l10n) {
    final text = _nameController.text.trim();
    if (text.isEmpty) {
      return l10n.errPgName;
    }
    return null;
  }

  String? _getAddressError(AppLocalizations l10n) {
    final text = _addressController.text.trim();
    if (text.isEmpty) {
      return l10n.errPgAddress;
    }
    return null;
  }

  String? _getCityError(AppLocalizations l10n) {
    if (_selectedCity == null) {
      return l10n.errPgCity;
    }
    return null;
  }

  String? _getPincodeError(AppLocalizations l10n) {
    final text = _pincodeController.text.trim();
    if (text.isEmpty) return null;
    final regex = RegExp(r'^[1-9][0-9]{5}$');
    if (!regex.hasMatch(text)) {
      return l10n.errPincode;
    }
    return null;
  }

  String? _getContactError(AppLocalizations l10n) {
    final text = _contactController.text.trim();
    if (text.isEmpty) return null;
    final digits = PhoneFormat.extractDigits(text);
    if (!PhoneFormat.isValidIndianMobile(digits)) {
      return l10n.phoneInvalid;
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

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _submitted = true);

    final hasError = _getNameError(l10n) != null ||
        _getAddressError(l10n) != null ||
        _getCityError(l10n) != null ||
        _getPincodeError(l10n) != null ||
        _getContactError(l10n) != null;

    if (hasError) return;

    setState(() => _isSubmitting = true);

    try {
      final name = _nameController.text.trim();
      final line1 = _addressController.text.trim();
      final area = _areaController.text.trim();
      final pincode = _pincodeController.text.trim();
      final contactDigits = PhoneFormat.extractDigits(_contactController.text);
      final contactPhone =
          contactDigits.isNotEmpty ? PhoneFormat.normalize(contactDigits) : null;

      final ownerRepo = ref.read(ownerRepositoryProvider);
      final newPgId = await ownerRepo.createPg(
        name: name,
        line1: line1,
        cityId: _selectedCity!.id,
        pincode: pincode.isNotEmpty ? pincode : null,
        area: area.isNotEmpty ? area : null,
        contactPhone: contactPhone,
        genderPolicy: _genderPolicy,
      );

      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.setSelectedPgId(newPgId);
      await authRepo.setLastView('owner');
      await ref.read(authContextProvider.notifier).refreshContext();

      if (mounted) {
        AppSnack.show(context, message: l10n.pgCreated);
        context.go(RoutePaths.ownerHome);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        AppSnack.show(context, message: l10n.errorGeneric);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authContext = ref.watch(authContextProvider).valueOrNull;

    if (!_contactEdited &&
        _contactController.text.isEmpty &&
        authContext?.person?.phone != null) {
      final rawPhone = authContext!.person!.phone;
      final digits = PhoneFormat.extractDigits(rawPhone);
      String tenDigits = digits;
      if (digits.length == 12 && digits.startsWith('91')) {
        tenDigits = digits.substring(2);
      } else if (digits.length > 10) {
        tenDigits = digits.substring(digits.length - 10);
      }
      if (tenDigits.isNotEmpty) {
        _contactController.text = PhoneInputFormatter()
            .formatEditUpdate(
              TextEditingValue.empty,
              TextEditingValue(text: tenDigits),
            )
            .text;
      }
    }

    final nameError =
        _submitted || _nameLostFocus ? _getNameError(l10n) : null;
    final addressError =
        _submitted || _addressLostFocus ? _getAddressError(l10n) : null;
    final cityError = _submitted ? _getCityError(l10n) : null;
    final pincodeError =
        _submitted || _pincodeLostFocus ? _getPincodeError(l10n) : null;
    final contactError =
        _submitted || _contactLostFocus ? _getContactError(l10n) : null;

    return Scaffold(
      backgroundColor: AppColors.ground,
      appBar: AppTopBar.back(
        title: l10n.addPgTitle,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionHeader(title: l10n.addPgAbout),
                  LedgerSheet(
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.all(AppSpace.x16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTextField(
                          label: l10n.addPgName,
                          controller: _nameController,
                          focusNode: _nameFocusNode,
                          errorText: nameError,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(60),
                          ],
                          onChanged: (_) {
                            if (_submitted || _nameLostFocus) setState(() {});
                          },
                        ),
                        const SizedBox(height: AppSpace.x16),
                        Text(
                          l10n.addPgWho,
                          style: AppText.label,
                        ),
                        const SizedBox(height: 6),
                        OptionRow<String>(
                          options: [
                            OptionRowItem(
                              value: 'men',
                              label: l10n.genderMen,
                            ),
                            OptionRowItem(
                              value: 'women',
                              label: l10n.genderWomen,
                            ),
                            OptionRowItem(
                              value: 'any',
                              label: l10n.genderAny,
                            ),
                          ],
                          selectedValue: _genderPolicy,
                          onChanged: (val) => setState(() => _genderPolicy = val),
                        ),
                      ],
                    ),
                  ),
                  SectionHeader(title: l10n.addPgAddressSection),
                  LedgerSheet(
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.all(AppSpace.x16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTextField(
                          label: l10n.addPgAddress,
                          hint: l10n.addPgAddressHint,
                          controller: _addressController,
                          focusNode: _addressFocusNode,
                          errorText: addressError,
                          onChanged: (_) {
                            if (_submitted || _addressLostFocus) setState(() {});
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
                          errorText: cityError,
                          onTap: _pickCity,
                        ),
                        const SizedBox(height: AppSpace.x16),
                        AppTextField(
                          label: l10n.addPgPincode,
                          controller: _pincodeController,
                          focusNode: _pincodeFocusNode,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          errorText: pincodeError,
                          onChanged: (_) {
                            if (_submitted || _pincodeLostFocus) setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                  SectionHeader(title: l10n.addPgContactSection),
                  LedgerSheet(
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.all(AppSpace.x16),
                    child: PhoneField(
                      label: l10n.addPgContact,
                      helperText: l10n.addPgContactHelper,
                      controller: _contactController,
                      focusNode: _contactFocusNode,
                      errorText: contactError,
                      onChanged: (_) {
                        _contactEdited = true;
                        if (_submitted || _contactLostFocus) setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpace.x24),
                ],
              ),
            ),
          ),
          Container(
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
              label: l10n.addPgCreate,
              expand: true,
              loading: _isSubmitting,
              onPressed: _submit,
            ),
          ),
        ],
      ),
    );
  }
}
