import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snack.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/ledger_sheet.dart';
import '../../../../core/widgets/option_sheet.dart';
import '../../../../core/widgets/select_field.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/room_type.dart';
import '../providers/owner_provider.dart';

class AddRoomsScreen extends ConsumerStatefulWidget {
  const AddRoomsScreen({super.key});

  @override
  ConsumerState<AddRoomsScreen> createState() => _AddRoomsScreenState();
}

class _AddRoomsScreenState extends ConsumerState<AddRoomsScreen> {
  final _firstNumberController = TextEditingController();
  final _countController = TextEditingController(text: '1');
  final _floorController = TextEditingController();
  final _prefixController = TextEditingController();

  int _bedsPerRoom = 2;
  String? _selectedRoomTypeCode;
  String? _firstNumberError;
  String? _countError;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _firstNumberController.addListener(_onFieldChanged);
    _countController.addListener(_onFieldChanged);
    _prefixController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _firstNumberController.removeListener(_onFieldChanged);
    _countController.removeListener(_onFieldChanged);
    _prefixController.removeListener(_onFieldChanged);
    _firstNumberController.dispose();
    _countController.dispose();
    _floorController.dispose();
    _prefixController.dispose();
    super.dispose();
  }

  Future<void> _chooseBeds(BuildContext context, AppLocalizations l10n) async {
    final chosen = await OptionSheet.show<int>(
      context: context,
      title: l10n.roomBeds,
      selectedValue: _bedsPerRoom,
      options: List.generate(
        12,
        (i) => OptionSheetItem(
          value: i + 1,
          title: '${i + 1}',
        ),
      ),
    );
    if (chosen != null && mounted) {
      setState(() {
        _bedsPerRoom = chosen;
      });
    }
  }

  Future<void> _chooseRoomType(
    BuildContext context,
    AppLocalizations l10n,
    List<RoomType> roomTypes,
  ) async {
    final options = <OptionSheetItem<String>>[
      OptionSheetItem(
        value: '',
        title: l10n.roomTypeNone,
      ),
      ...roomTypes.map(
        (rt) => OptionSheetItem(
          value: rt.code,
          title: rt.label,
        ),
      ),
    ];

    final chosen = await OptionSheet.show<String>(
      context: context,
      title: l10n.roomType,
      selectedValue: _selectedRoomTypeCode ?? '',
      options: options,
    );

    if (chosen != null && mounted) {
      setState(() {
        _selectedRoomTypeCode = chosen.isEmpty ? null : chosen;
      });
    }
  }

  Widget? _buildLivePreview(AppLocalizations l10n) {
    final firstNum = int.tryParse(_firstNumberController.text.trim());
    final count = int.tryParse(_countController.text.trim());
    if (firstNum == null || firstNum < 0 || count == null || count < 1 || count > 100) {
      return null;
    }
    final prefix = _prefixController.text.trim();
    final first = '$prefix$firstNum';
    final last = '$prefix${firstNum + count - 1}';
    final beds = _bedsPerRoom;
    final labels = List.generate(beds, (i) => String.fromCharCode(65 + i)).join(', ');
    final preview = l10n.roomsPreview(count, first, last, beds, labels);

    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpace.x16,
        right: AppSpace.x16,
        top: AppSpace.x12,
        bottom: AppSpace.x24,
      ),
      child: Text(
        preview,
        style: AppText.secondary,
      ),
    );
  }

  Future<void> _submit(AppLocalizations l10n) async {
    setState(() {
      _firstNumberError = null;
      _countError = null;
    });

    final firstText = _firstNumberController.text.trim();
    final countText = _countController.text.trim();

    final firstNum = int.tryParse(firstText);
    final count = int.tryParse(countText);

    bool hasError = false;
    if (firstText.isEmpty || firstNum == null || firstNum < 0) {
      _firstNumberError = l10n.errRoomNumber;
      hasError = true;
    }

    if (countText.isEmpty || count == null || count < 1 || count > 100) {
      _countError = l10n.errRoomCount;
      hasError = true;
    }

    if (hasError) {
      setState(() {});
      return;
    }

    final activePg = ref.read(activePgProvider);
    final pgId = activePg?.pgId;
    if (pgId == null) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final prefixText = _prefixController.text.trim();
      final floorText = _floorController.text.trim();
      final floorNum = floorText.isNotEmpty ? int.tryParse(floorText) : null;

      await ref.read(ownerRepositoryProvider).addRooms(
        pgId: pgId,
        firstRoomNumber: firstNum!,
        roomCount: count!,
        bedsPerRoom: _bedsPerRoom,
        roomTypeCode: _selectedRoomTypeCode,
        floor: floorNum,
        prefix: prefixText.isNotEmpty ? prefixText : null,
      );

      if (mounted) {
        AppSnack.show(context, message: l10n.roomsAdded(count));
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(RoutePaths.ownerMore);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          final msg = e.toString().replaceFirst('Exception: ', '');
          _firstNumberError = msg;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ref.watch(activePgProvider);
    final roomTypesAsync = ref.watch(roomTypesProvider);
    final roomTypes = roomTypesAsync.valueOrNull ?? [];

    String roomTypeLabel = l10n.roomTypeNone;
    if (_selectedRoomTypeCode != null) {
      final match = roomTypes.where((rt) => rt.code == _selectedRoomTypeCode);
      if (match.isNotEmpty) {
        roomTypeLabel = match.first.label;
      }
    }

    final livePreview = _buildLivePreview(l10n);

    return Scaffold(
      backgroundColor: AppColors.ground,
      appBar: AppTopBar.back(
        title: l10n.addRoomsTitle,
        onLeadingPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(RoutePaths.ownerMore);
          }
        },
      ),
      body: ListView(
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
                AppTextField(
                  key: const Key('first_room_number_field'),
                  label: l10n.roomFirstNumber,
                  controller: _firstNumberController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  errorText: _firstNumberError,
                  onChanged: (_) {
                    setState(() {
                      if (_firstNumberError != null) _firstNumberError = null;
                    });
                  },
                ),
                const SizedBox(height: AppSpace.x16),
                AppTextField(
                  key: const Key('room_count_field'),
                  label: l10n.roomCount,
                  controller: _countController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  errorText: _countError,
                  onChanged: (_) {
                    setState(() {
                      if (_countError != null) _countError = null;
                    });
                  },
                ),
                const SizedBox(height: AppSpace.x16),
                SelectField(
                  key: const Key('room_beds_field'),
                  label: l10n.roomBeds,
                  value: _bedsPerRoom.toString(),
                  onTap: () => _chooseBeds(context, l10n),
                ),
                const SizedBox(height: AppSpace.x16),
                SelectField(
                  key: const Key('room_type_field'),
                  label: l10n.roomType,
                  value: roomTypeLabel,
                  onTap: () => _chooseRoomType(context, l10n, roomTypes),
                ),
                const SizedBox(height: AppSpace.x16),
                AppTextField(
                  key: const Key('room_floor_field'),
                  label: l10n.roomFloor,
                  controller: _floorController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: AppSpace.x16),
                AppTextField(
                  key: const Key('room_prefix_field'),
                  label: l10n.roomPrefix,
                  controller: _prefixController,
                  hint: l10n.roomPrefixHint,
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          if (livePreview != null) livePreview,
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
          label: l10n.roomsAddAction,
          expand: true,
          loading: _isSubmitting,
          onPressed: () => _submit(l10n),
        ),
      ),
    );
  }
}
