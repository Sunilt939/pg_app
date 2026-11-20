import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snack.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/beds_stepper.dart';
import '../../../../core/widgets/ledger_row.dart';
import '../../../../core/widgets/ledger_sheet.dart';
import '../../../../core/widgets/progress_bar_thin.dart';
import '../../../../core/widgets/room_tile.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/room_setup_item.dart';
import '../providers/owner_provider.dart';

int _naturalCompare(String a, String b) {
  final regex = RegExp(r'(\d+|\D+)');
  final matchesA = regex.allMatches(a).map((m) => m.group(0)!).toList();
  final matchesB = regex.allMatches(b).map((m) => m.group(0)!).toList();
  for (int i = 0; i < matchesA.length && i < matchesB.length; i++) {
    final partA = matchesA[i];
    final partB = matchesB[i];
    final numA = int.tryParse(partA);
    final numB = int.tryParse(partB);
    if (numA != null && numB != null) {
      final cmp = numA.compareTo(numB);
      if (cmp != 0) return cmp;
    } else {
      final cmp = partA.toLowerCase().compareTo(partB.toLowerCase());
      if (cmp != 0) return cmp;
    }
  }
  return matchesA.length.compareTo(matchesB.length);
}

class SetUpRoomsScreen extends ConsumerStatefulWidget {
  const SetUpRoomsScreen({super.key});

  @override
  ConsumerState<SetUpRoomsScreen> createState() => _SetUpRoomsScreenState();
}

class _SetUpRoomsScreenState extends ConsumerState<SetUpRoomsScreen> {
  final ScrollController _scrollController = ScrollController();

  int _currentStep = 1;

  // Step 1 Controllers & State
  final TextEditingController _floorNumberController = TextEditingController(text: '1');
  final TextEditingController _roomCountController = TextEditingController();
  String? _floorNumberError;
  String? _roomCountError;

  // Step 2 State
  // Custom bed count per room position (1-based index)
  final Map<int, int> _firstFloorBeds = {};
  int _allRoomsBeds = 2;

  // Step 3 Controller & State
  final TextEditingController _floorCountController = TextEditingController(text: '1');
  String? _floorCountError;

  // Step 4 State
  List<RoomSetupItem> _allRooms = [];
  String? _dbError;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _floorNumberController.addListener(_onFormUpdated);
    _roomCountController.addListener(_onFormUpdated);
    _floorCountController.addListener(_onFormUpdated);
  }

  @override
  void dispose() {
    _floorNumberController.removeListener(_onFormUpdated);
    _roomCountController.removeListener(_onFormUpdated);
    _floorCountController.removeListener(_onFormUpdated);
    _floorNumberController.dispose();
    _roomCountController.dispose();
    _floorCountController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onFormUpdated() {
    setState(() {});
  }

  String _generateRoomNumber(int floor, int position) {
    if (floor == 0) {
      return 'G$position';
    }
    return '${floor * 100 + position}';
  }

  int get _step1FloorNumber => int.tryParse(_floorNumberController.text.trim()) ?? 1;
  int? get _step1RoomCount => int.tryParse(_roomCountController.text.trim());

  bool get _isStep1FloorValid {
    final f = int.tryParse(_floorNumberController.text.trim());
    return f != null && f >= 0 && f <= 30;
  }

  bool get _isStep1RoomsValid {
    final r = int.tryParse(_roomCountController.text.trim());
    return r != null && r >= 1 && r <= 99;
  }

  bool get _isStep1Valid => _isStep1FloorValid && _isStep1RoomsValid;

  bool get _isStep3FloorCountValid {
    final c = int.tryParse(_floorCountController.text.trim());
    return c != null && c >= 1 && c <= 30;
  }

  int get _step3FloorCount => int.tryParse(_floorCountController.text.trim()) ?? 1;

  int _getBedsForPosition(int pos) {
    return _firstFloorBeds[pos] ?? 2;
  }

  int get _firstFloorTotalBeds {
    final count = _step1RoomCount ?? 0;
    int total = 0;
    for (int i = 1; i <= count; i++) {
      total += _getBedsForPosition(i);
    }
    return total;
  }

  bool get _isDirty {
    if (_currentStep > 1) return true;
    if (_floorNumberController.text.trim() != '1') return true;
    if (_roomCountController.text.trim().isNotEmpty) return true;
    return false;
  }

  Future<void> _handleBack() async {
    if (_currentStep > 1) {
      setState(() {
        _currentStep -= 1;
        _dbError = null;
      });
      return;
    }

    if (_isDirty) {
      final l10n = AppLocalizations.of(context)!;
      final leave = await ConfirmSheet.show(
        context: context,
        title: l10n.layoutLeaveTitle,
        body: l10n.layoutLeaveBody,
        confirmLabel: l10n.layoutLeaveAction,
        cancelLabel: l10n.actionCancel,
        isDestructive: true,
      );
      if (leave == true && mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(RoutePaths.ownerMore);
        }
      }
    } else {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(RoutePaths.ownerMore);
      }
    }
  }

  void _onStep1Next() {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _floorNumberError = null;
      _roomCountError = null;
    });

    if (!_isStep1FloorValid) {
      setState(() => _floorNumberError = l10n.errLayoutFloor);
      return;
    }
    if (!_isStep1RoomsValid) {
      setState(() => _roomCountError = l10n.errLayoutRooms);
      return;
    }

    // Advance to Step 2
    setState(() {
      _currentStep = 2;
    });
  }

  void _setAllRoomsBeds(int beds) {
    setState(() {
      _allRoomsBeds = beds;
      final count = _step1RoomCount ?? 0;
      for (int i = 1; i <= count; i++) {
        _firstFloorBeds[i] = beds;
      }
    });
  }

  void _setRoomBeds(int position, int beds) {
    setState(() {
      _firstFloorBeds[position] = beds;
    });
  }

  void _onStep2Next() {
    setState(() {
      _currentStep = 3;
    });
  }

  void _onStep3Next() {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _floorCountError = null;
    });

    if (!_isStep3FloorCountValid) {
      setState(() => _floorCountError = l10n.errLayoutFloors);
      return;
    }

    final floorCount = _step3FloorCount;
    final roomsPerFloor = _step1RoomCount ?? 0;
    final totalRooms = floorCount * roomsPerFloor;

    if (totalRooms > 500) {
      setState(() => _floorCountError = l10n.errLayoutTooMany);
      return;
    }

    // Build the full room layout
    final startFloor = _step1FloorNumber;
    final List<RoomSetupItem> built = [];

    for (int f = 0; f < floorCount; f++) {
      final currentFloor = startFloor + f;
      for (int p = 1; p <= roomsPerFloor; p++) {
        built.add(RoomSetupItem(
          number: _generateRoomNumber(currentFloor, p),
          floor: currentFloor,
          beds: _getBedsForPosition(p),
        ));
      }
    }

    setState(() {
      _allRooms = built;
      _currentStep = 4;
      _dbError = null;
    });
  }

  Future<void> _openEditRoomSheet(RoomSetupItem room) async {
    final l10n = AppLocalizations.of(context)!;
    final numberController = TextEditingController(text: room.number);
    int beds = room.beds;
    String? errorText;

    await AppBottomSheet.show<void>(
      context: context,
      builder: (sheetContext) {
        return AppBottomSheet(
          title: l10n.layoutEditTitle,
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    label: l10n.layoutRoomNumber,
                    controller: numberController,
                    maxLength: 20,
                    errorText: errorText,
                    onChanged: (_) {
                      if (errorText != null) {
                        setSheetState(() => errorText = null);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpace.x16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.layoutBedsLabel, style: AppText.label),
                      BedsStepper(
                        value: beds,
                        onChanged: (v) => setSheetState(() => beds = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.x24),
                  AppButton.primary(
                    label: l10n.actionDone,
                    onPressed: () {
                      final newNum = numberController.text.trim();
                      if (newNum.isEmpty) {
                        setSheetState(() => errorText = l10n.errLayoutNumber);
                        return;
                      }
                      // Check duplicate against all other rooms (case-insensitive)
                      final duplicate = _allRooms.any(
                        (r) => r != room && r.number.toLowerCase() == newNum.toLowerCase(),
                      );
                      if (duplicate) {
                        setSheetState(() => errorText = l10n.errLayoutDuplicate);
                        return;
                      }

                      // Update room
                      final index = _allRooms.indexOf(room);
                      if (index != -1) {
                        setState(() {
                          _allRooms[index] = room.copyWith(number: newNum, beds: beds);
                        });
                      }
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(height: AppSpace.x8),
                  AppButton.destructive(
                    label: l10n.layoutRemoveRoom,
                    onPressed: () {
                      setState(() {
                        _allRooms.remove(room);
                      });
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _openAddRoomSheet(int floor) async {
    final l10n = AppLocalizations.of(context)!;

    // Start with highest numeric room number on that floor plus 1
    final floorRooms = _allRooms.where((r) => r.floor == floor).toList();
    int? maxNumeric;
    for (final r in floorRooms) {
      final digits = RegExp(r'\d+').allMatches(r.number).map((m) => int.tryParse(m.group(0)!)).whereType<int>();
      for (final d in digits) {
        if (maxNumeric == null || d > maxNumeric) {
          maxNumeric = d;
        }
      }
    }

    String initialNumber = '';
    if (floor == 0) {
      initialNumber = maxNumeric != null ? 'G${maxNumeric + 1}' : 'G1';
    } else if (maxNumeric != null) {
      initialNumber = '${maxNumeric + 1}';
    } else {
      initialNumber = '${floor * 100 + 1}';
    }

    final numberController = TextEditingController(text: initialNumber);
    int beds = 2;
    String? errorText;

    await AppBottomSheet.show<void>(
      context: context,
      builder: (sheetContext) {
        return AppBottomSheet(
          title: l10n.layoutNewTitle,
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    label: l10n.layoutRoomNumber,
                    controller: numberController,
                    maxLength: 20,
                    errorText: errorText,
                    onChanged: (_) {
                      if (errorText != null) {
                        setSheetState(() => errorText = null);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpace.x16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.layoutBedsLabel, style: AppText.label),
                      BedsStepper(
                        value: beds,
                        onChanged: (v) => setSheetState(() => beds = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.x24),
                  AppButton.primary(
                    label: l10n.actionDone,
                    onPressed: () {
                      final newNum = numberController.text.trim();
                      if (newNum.isEmpty) {
                        setSheetState(() => errorText = l10n.errLayoutNumber);
                        return;
                      }
                      final duplicate = _allRooms.any(
                        (r) => r.number.toLowerCase() == newNum.toLowerCase(),
                      );
                      if (duplicate) {
                        setSheetState(() => errorText = l10n.errLayoutDuplicate);
                        return;
                      }

                      setState(() {
                        _allRooms.add(RoomSetupItem(
                          number: newNum,
                          floor: floor,
                          beds: beds,
                        ));
                      });
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _saveRooms() async {
    final l10n = AppLocalizations.of(context)!;
    if (_allRooms.isEmpty || _allRooms.length > 500) {
      return;
    }

    final activePg = ref.read(activePgProvider);
    final pgId = activePg?.pgId;
    if (pgId == null) return;

    setState(() {
      _isSaving = true;
      _dbError = null;
    });

    try {
      final roomsPayload = _allRooms.map((r) => r.toJson()).toList();
      final count = await ref.read(ownerRepositoryProvider).addRoomLayout(
            pgId: pgId,
            rooms: roomsPayload,
          );

      if (mounted) {
        AppSnack.show(context, message: l10n.roomsAdded(count));
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(RoutePaths.ownerMore);
        }
      }
    } on SocketException {
      if (mounted) {
        setState(() => _isSaving = false);
        AppSnack.show(context, message: l10n.errorNetwork);
      }
    } on AuthNetworkException {
      if (mounted) {
        setState(() => _isSaving = false);
        AppSnack.show(context, message: l10n.errorNetwork);
      }
    } catch (e) {
      if (mounted) {
        final rawMsg = e.toString().replaceFirst('Exception: ', '');
        setState(() {
          _isSaving = false;
          _dbError = rawMsg;
        });
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0.0,
            duration: AppMotion.base,
            curve: Curves.easeOut,
          );
        }
      }
    }
  }

  Widget _buildStep1(AppLocalizations l10n) {
    String? previewText;
    if (_isStep1Valid) {
      final floor = _step1FloorNumber;
      final count = _step1RoomCount!;
      final first = _generateRoomNumber(floor, 1);
      final last = _generateRoomNumber(floor, count);
      previewText = l10n.layoutS1Preview(count, first, last);
    }

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.only(
        top: AppSpace.x16,
        bottom: AppSpace.x32,
      ),
      children: [
        LedgerSheet(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(AppSpace.x16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.layoutS1Title, style: AppText.heading),
              const SizedBox(height: 4),
              Text(l10n.layoutS1Body, style: AppText.secondary),
              const SizedBox(height: AppSpace.x16),
              AppTextField(
                key: const Key('layout_floor_number_field'),
                label: l10n.layoutFloorNumber,
                helperText: l10n.layoutFloorHelper,
                controller: _floorNumberController,
                keyboardType: TextInputType.number,
                maxLength: 2,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                errorText: _floorNumberError,
              ),
              const SizedBox(height: AppSpace.x16),
              AppTextField(
                key: const Key('layout_room_count_field'),
                label: l10n.layoutRoomCount,
                controller: _roomCountController,
                keyboardType: TextInputType.number,
                maxLength: 2,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                errorText: _roomCountError,
              ),
            ],
          ),
        ),
        if (previewText != null)
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpace.x16,
              right: AppSpace.x16,
              top: AppSpace.x12,
            ),
            child: Text(
              previewText,
              style: AppText.secondary,
            ),
          ),
      ],
    );
  }

  Widget _buildStep2(AppLocalizations l10n) {
    final floor = _step1FloorNumber;
    final count = _step1RoomCount ?? 0;
    final totalBeds = _firstFloorTotalBeds;
    final totalsText = l10n.layoutFloorTotals(count, totalBeds);

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.only(
        top: AppSpace.x16,
        bottom: AppSpace.x32,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.layoutS2Title, style: AppText.heading),
              const SizedBox(height: 4),
              Text(l10n.layoutS2Body, style: AppText.secondary),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.x16),
        LedgerSheet(
          children: [
            LedgerRow(
              title: l10n.layoutAllRooms,
              titleStyle: AppText.bodyMedium,
              minHeight: 56,
              trailing: BedsStepper(
                key: const Key('all_rooms_stepper'),
                value: _allRoomsBeds,
                onChanged: _setAllRoomsBeds,
              ),
            ),
            for (int p = 1; p <= count; p++) ...[
              LedgerRow(
                leading: RoomTile(label: _generateRoomNumber(floor, p)),
                leadingGap: AppSpace.x16,
                title: l10n.roomPageTitle(_generateRoomNumber(floor, p)),
                titleStyle: AppText.body,
                minHeight: 56,
                showDivider: p < count,
                trailing: BedsStepper(
                  key: Key('room_stepper_$p'),
                  value: _getBedsForPosition(p),
                  onChanged: (v) => _setRoomBeds(p, v),
                ),
              ),
            ],
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpace.x16,
            right: AppSpace.x16,
            top: AppSpace.x12,
          ),
          child: Text(
            totalsText,
            style: AppText.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStep3(AppLocalizations l10n) {
    final floorCount = _step3FloorCount;
    final roomsPerFloor = _step1RoomCount ?? 0;
    final totalRooms = floorCount * roomsPerFloor;
    final totalBeds = floorCount * _firstFloorTotalBeds;
    final isTooMany = totalRooms > 500;

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.only(
        top: AppSpace.x16,
        bottom: AppSpace.x32,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.layoutS3Title, style: AppText.heading),
              const SizedBox(height: 4),
              Text(l10n.layoutS3Body, style: AppText.secondary),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.x16),
        LedgerSheet(
          padding: const EdgeInsets.all(AppSpace.x16),
          child: AppTextField(
            key: const Key('layout_floor_count_field'),
            label: l10n.layoutFloorCount,
            helperText: l10n.layoutFloorCountHelper,
            controller: _floorCountController,
            keyboardType: TextInputType.number,
            maxLength: 2,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            errorText: _floorCountError,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpace.x16,
            right: AppSpace.x16,
            top: AppSpace.x12,
          ),
          child: Text(
            isTooMany
                ? l10n.errLayoutTooMany
                : l10n.layoutTotals(floorCount, totalRooms, totalBeds),
            style: AppText.secondary.copyWith(
              color: isTooMany ? AppColors.overdueFg : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep4(AppLocalizations l10n) {
    // Unique floors in ascending order
    final floors = _allRooms.map((r) => r.floor ?? 0).toSet().toList()..sort();
    final totalRooms = _allRooms.length;
    final totalBeds = _allRooms.fold<int>(0, (sum, r) => sum + r.beds);
    final totalFloors = floors.length;

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.only(
        top: AppSpace.x16,
        bottom: AppSpace.x32,
      ),
      children: [
        LedgerSheet(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(AppSpace.x16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.layoutS4Title, style: AppText.heading),
              const SizedBox(height: 4),
              Text(l10n.layoutS4Body, style: AppText.secondary),
              const SizedBox(height: AppSpace.x8),
              Text(
                l10n.layoutTotals(totalFloors, totalRooms, totalBeds),
                style: AppText.bodyMedium,
              ),
              if (_dbError != null) ...[
                const SizedBox(height: AppSpace.x8),
                Text(
                  _dbError!,
                  style: AppText.secondary.copyWith(color: AppColors.overdueFg),
                ),
              ],
            ],
          ),
        ),
        for (final floor in floors) ...[
          _buildFloorSection(l10n, floor),
        ],
      ],
    );
  }

  Widget _buildFloorSection(AppLocalizations l10n, int floor) {
    final floorRooms = _allRooms.where((r) => r.floor == floor).toList()
      ..sort((a, b) => _naturalCompare(a.number, b.number));

    if (floorRooms.isEmpty) return const SizedBox.shrink();

    final floorHeader = floor == 0 ? l10n.layoutGroundFloor : l10n.roomsFloor(floor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: floorHeader,
          trailing: GestureDetector(
            onTap: () => _openAddRoomSheet(floor),
            child: Text(
              l10n.layoutAddRoom,
              style: AppText.buttonSmall.copyWith(color: AppColors.petrol),
            ),
          ),
        ),
        LedgerSheet(
          children: [
            for (int i = 0; i < floorRooms.length; i++) ...[
              LedgerRow(
                leading: RoomTile(label: floorRooms[i].number),
                leadingGap: AppSpace.x16,
                title: l10n.layoutBedsCount(floorRooms[i].beds),
                trailing: const Icon(
                  AppIcons.chevronRight,
                  size: 20,
                  color: AppColors.muted,
                ),
                minHeight: 56,
                showDivider: i < floorRooms.length - 1,
                onTap: () => _openEditRoomSheet(floorRooms[i]),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildStickyBottom(AppLocalizations l10n) {
    Widget button;

    if (_currentStep == 1) {
      button = AppButton.primary(
        label: l10n.layoutNext,
        expand: true,
        onPressed: _isStep1Valid ? _onStep1Next : null,
      );
    } else if (_currentStep == 2) {
      button = AppButton.primary(
        label: l10n.layoutNext,
        expand: true,
        onPressed: _onStep2Next,
      );
    } else if (_currentStep == 3) {
      final floorCount = _step3FloorCount;
      final roomsPerFloor = _step1RoomCount ?? 0;
      final totalRooms = floorCount * roomsPerFloor;
      final canProceed = _isStep3FloorCountValid && totalRooms <= 500;

      button = AppButton.primary(
        label: l10n.layoutNext,
        expand: true,
        onPressed: canProceed ? _onStep3Next : null,
      );
    } else {
      final canSave = _allRooms.isNotEmpty && _allRooms.length <= 500 && !_isSaving;

      button = AppButton.primary(
        label: l10n.layoutSave,
        expand: true,
        loading: _isSaving,
        onPressed: canSave ? _saveRooms : null,
      );
    }

    return Container(
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
      child: button,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ref.watch(activePgProvider);

    Widget stepBody;
    switch (_currentStep) {
      case 1:
        stepBody = _buildStep1(l10n);
        break;
      case 2:
        stepBody = _buildStep2(l10n);
        break;
      case 3:
        stepBody = _buildStep3(l10n);
        break;
      case 4:
      default:
        stepBody = _buildStep4(l10n);
        break;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.ground,
        appBar: AppTopBar.back(
          title: l10n.layoutTitle,
          onLeadingPressed: _handleBack,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.x16,
                AppSpace.x16,
                AppSpace.x16,
                AppSpace.x8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.layoutStepLabel(_currentStep, 4),
                    style: AppText.secondary,
                  ),
                  const SizedBox(height: 8),
                  ProgressBarThin(progress: _currentStep / 4.0),
                ],
              ),
            ),
            Expanded(child: stepBody),
          ],
        ),
        bottomNavigationBar: _buildStickyBottom(l10n),
      ),
    );
  }
}

