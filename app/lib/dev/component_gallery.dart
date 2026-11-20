import 'package:flutter/material.dart';
import '../core/theme/app_icons.dart';
import '../core/theme/tokens.dart';
import '../core/widgets/app_bottom_nav.dart';
import '../core/widgets/app_bottom_sheet.dart';
import '../core/widgets/app_button.dart';
import '../core/widgets/app_snack.dart';
import '../core/widgets/app_text_field.dart';
import '../core/widgets/app_top_bar.dart';
import '../core/widgets/beds_stepper.dart';
import '../core/widgets/date_field.dart';
import '../core/widgets/empty_state.dart';
import '../core/widgets/error_state.dart';
import '../core/widgets/key_value_row.dart';
import '../core/widgets/ledger_row.dart';
import '../core/widgets/ledger_sheet.dart';
import '../core/widgets/money.dart';
import '../core/widgets/money_field.dart';
import '../core/widgets/option_row.dart';
import '../core/widgets/option_sheet.dart';
import '../core/widgets/otp_field.dart';
import '../core/widgets/pg_switcher_title.dart';
import '../core/widgets/phone_field.dart';
import '../core/widgets/profile_avatar.dart';
import '../core/widgets/progress_bar_thin.dart';
import '../core/widgets/receipt_paper.dart';
import '../core/widgets/room_tile.dart';
import '../core/widgets/section_header.dart';
import '../core/widgets/select_field.dart';
import '../core/widgets/skeleton.dart';
import '../core/widgets/stamp.dart';
import '../core/widgets/status_chip.dart';
import '../core/widgets/switch_row.dart';
import '../core/widgets/tick_badge.dart';
import '../core/widgets/underline_tabs.dart';

class ComponentGallery extends StatefulWidget {
  const ComponentGallery({super.key});

  @override
  State<ComponentGallery> createState() => _ComponentGalleryState();
}

class _ComponentGalleryState extends State<ComponentGallery> {
  int _counter = 0;
  int _tabIndex = 0;
  int _navIndex = 0;
  String _selectedOption = '1';
  String _selectedGridOption = 'A';
  bool _switchVal1 = true;
  bool _switchVal2 = false;
  DateTime? _selectedDate = DateTime(2026, 11, 12);
  bool _otpError = false;
  String _selectValue = 'Option 1';
  int _stepperBeds = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ground,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.x16),
          children: [
            // Page title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpace.x16),
              child: Text(
                'Component Gallery',
                style: AppText.display,
              ),
            ),
            const SizedBox(height: AppSpace.x16),

            // 1. Type specimen
            const SectionHeader(title: 'Type Specimen'),
            const LedgerSheet(
              padding: EdgeInsets.all(AppSpace.x16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('display: Aa 0123456789 ₹1,23,456', style: AppText.display),
                  SizedBox(height: AppSpace.x8),
                  Text('title: Aa 0123456789 ₹1,23,456', style: AppText.title),
                  SizedBox(height: AppSpace.x8),
                  Text('heading: Aa 0123456789 ₹1,23,456', style: AppText.heading),
                  SizedBox(height: AppSpace.x8),
                  Text('bodyMedium: Aa 0123456789 ₹1,23,456', style: AppText.bodyMedium),
                  SizedBox(height: AppSpace.x8),
                  Text('body: Aa 0123456789 ₹1,23,456', style: AppText.body),
                  SizedBox(height: AppSpace.x8),
                  Text('secondary: Aa 0123456789 ₹1,23,456', style: AppText.secondary),
                  SizedBox(height: AppSpace.x8),
                  Text('label: Aa 0123456789 ₹1,23,456', style: AppText.label),
                  SizedBox(height: AppSpace.x8),
                  Text('caption: Aa 0123456789 ₹1,23,456', style: AppText.caption),
                  SizedBox(height: AppSpace.x8),
                  Text('captionBold: Aa 0123456789 ₹1,23,456', style: AppText.captionBold),
                  SizedBox(height: AppSpace.x8),
                  Text('button: Aa 0123456789 ₹1,23,456', style: AppText.button),
                  SizedBox(height: AppSpace.x8),
                  Text('buttonSmall: Aa 0123456789 ₹1,23,456', style: AppText.buttonSmall),
                ],
              ),
            ),

            // 2. Colours
            const SectionHeader(title: 'Colour Swatches'),
            const LedgerSheet(
              padding: EdgeInsets.all(AppSpace.x16),
              child: Wrap(
                spacing: AppSpace.x8,
                runSpacing: AppSpace.x12,
                children: [
                  _ColorSwatch(name: 'petrol', color: AppColors.petrol),
                  _ColorSwatch(name: 'petrolPressed', color: AppColors.petrolPressed),
                  _ColorSwatch(name: 'petrolTint', color: AppColors.petrolTint),
                  _ColorSwatch(name: 'ground', color: AppColors.ground, border: true),
                  _ColorSwatch(name: 'surface', color: AppColors.surface, border: true),
                  _ColorSwatch(name: 'ink', color: AppColors.ink),
                  _ColorSwatch(name: 'muted', color: AppColors.muted),
                  _ColorSwatch(name: 'hairline', color: AppColors.hairline),
                  _ColorSwatch(name: 'paidFg', color: AppColors.paidFg),
                  _ColorSwatch(name: 'paidBg', color: AppColors.paidBg),
                  _ColorSwatch(name: 'pendingFg', color: AppColors.pendingFg),
                  _ColorSwatch(name: 'pendingBg', color: AppColors.pendingBg),
                  _ColorSwatch(name: 'overdueFg', color: AppColors.overdueFg),
                  _ColorSwatch(name: 'overduePressed', color: AppColors.overduePressed),
                  _ColorSwatch(name: 'overdueBg', color: AppColors.overdueBg),
                  _ColorSwatch(name: 'disabledBg', color: AppColors.disabledBg),
                  _ColorSwatch(name: 'skeletonBase', color: AppColors.skeletonBase),
                  _ColorSwatch(name: 'snackAction', color: AppColors.snackAction),
                  _ColorSwatch(name: 'handle', color: AppColors.handle),
                  _ColorSwatch(name: 'outline', color: AppColors.outline),
                  _ColorSwatch(name: 'transparent', color: AppColors.transparent, border: true),
                ],
              ),
            ),

            // 3. Money
            const SectionHeader(title: 'Money Component'),
            const LedgerSheet(
              padding: EdgeInsets.all(AppSpace.x16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Money(paise: 650000, style: AppText.display),
                  SizedBox(height: AppSpace.x8),
                  Money(paise: 12500000, style: AppText.title),
                  SizedBox(height: AppSpace.x8),
                  Money(paise: 650050, style: AppText.heading),
                  SizedBox(height: AppSpace.x8),
                  Money(paise: 0, style: AppText.body),
                  SizedBox(height: AppSpace.x8),
                  Money(paise: -650000, style: AppText.heading, color: AppColors.overdueFg),
                  SizedBox(height: AppSpace.x8),
                  Money(paise: -650050, style: AppText.bodyMedium, color: AppColors.overdueFg),
                ],
              ),
            ),

            // 4. StatusChip
            const SectionHeader(title: 'StatusChip'),
            const LedgerSheet(
              padding: EdgeInsets.all(AppSpace.x16),
              child: Row(
                children: [
                  StatusChip.paid(),
                  SizedBox(width: AppSpace.x8),
                  StatusChip.pending(),
                  SizedBox(width: AppSpace.x8),
                  StatusChip.overdue(),
                  SizedBox(width: AppSpace.x8),
                  StatusChip.due(),
                ],
              ),
            ),

            // 5. AppButton
            const SectionHeader(title: 'AppButton'),
            LedgerSheet(
              padding: const EdgeInsets.all(AppSpace.x16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppButton.primary(
                    label: 'Primary Button',
                    icon: AppIcons.check,
                    onPressed: () => setState(() => _counter++),
                  ),
                  const SizedBox(height: AppSpace.x12),
                  const AppButton.primary(
                    label: 'Primary Loading',
                    loading: true,
                  ),
                  const SizedBox(height: AppSpace.x12),
                  const AppButton.primary(
                    label: 'Primary Disabled',
                    onPressed: null,
                  ),
                  const SizedBox(height: AppSpace.x16),
                  AppButton.secondary(
                    label: 'Secondary Button',
                    icon: AppIcons.add,
                    onPressed: () {},
                  ),
                  const SizedBox(height: AppSpace.x12),
                  const AppButton.secondary(
                    label: 'Secondary Loading',
                    loading: true,
                  ),
                  const SizedBox(height: AppSpace.x12),
                  const AppButton.secondary(
                    label: 'Secondary Disabled',
                    onPressed: null,
                  ),
                  const SizedBox(height: AppSpace.x16),
                  AppButton.destructive(
                    label: 'Destructive Button',
                    icon: AppIcons.trash,
                    onPressed: () {},
                  ),
                  const SizedBox(height: AppSpace.x16),
                  Row(
                    children: [
                      AppButton.text(
                        label: 'Text Button',
                        onPressed: () {},
                      ),
                      const SizedBox(width: AppSpace.x12),
                      const AppButton.text(
                        label: 'Text Loading',
                        loading: true,
                      ),
                      const SizedBox(width: AppSpace.x12),
                      const AppButton.text(
                        label: 'Text Disabled',
                        onPressed: null,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 6. RoomTile
            const SectionHeader(title: 'RoomTile'),
            const LedgerSheet(
              padding: EdgeInsets.all(AppSpace.x16),
              child: Row(
                children: [
                  RoomTile(label: '101'),
                  SizedBox(width: AppSpace.x12),
                  RoomTile(label: '204B'),
                  SizedBox(width: AppSpace.x12),
                  RoomTile(),
                ],
              ),
            ),

            // 7. LedgerRow
            const SectionHeader(title: 'LedgerRow'),
            LedgerSheet(
              children: [
                LedgerRow(
                  leading: const RoomTile(label: '101'),
                  title: 'Primary text',
                  subtitle: 'Secondary text',
                  paise: 650000,
                  statusKind: StatusChipKind.paid,
                  onTap: () {},
                ),
                LedgerRow(
                  leading: const RoomTile(label: '102'),
                  title: 'Primary text',
                  subtitle: 'Secondary text',
                  paise: 650000,
                  statusKind: StatusChipKind.overdue,
                  inlineActions: [
                    AppButton.text(
                      label: 'Action 1',
                      onPressed: () {},
                    ),
                    AppButton.text(
                      label: 'Action 2',
                      onPressed: () {},
                    ),
                  ],
                  onTap: () {},
                ),
                LedgerRow(
                  leading: const RoomTile(),
                  title: 'Primary text',
                  subtitle: 'Secondary text',
                  statusKind: StatusChipKind.due,
                  showDivider: false,
                  onTap: () {},
                ),
              ],
            ),

            // 8. KeyValueRow
            const SectionHeader(title: 'KeyValueRow'),
            const LedgerSheet(
              children: [
                KeyValueRow(
                  label: 'Label',
                  value: 'Primary text',
                ),
                KeyValueRow(
                  label: 'Label (read-only)',
                  value: 'Primary text',
                  isReadOnly: true,
                ),
                KeyValueRow(
                  label: 'Label',
                  value: 'Primary text',
                  showDivider: false,
                ),
              ],
            ),

            // 9. ProgressBarThin
            const SectionHeader(title: 'ProgressBarThin'),
            const LedgerSheet(
              padding: EdgeInsets.all(AppSpace.x16),
              child: Column(
                children: [
                  ProgressBarThin(progress: 0.25),
                  SizedBox(height: AppSpace.x12),
                  ProgressBarThin(progress: 0.65),
                  SizedBox(height: AppSpace.x12),
                  ProgressBarThin(progress: 1.0),
                ],
              ),
            ),

            // 10. ProfileAvatar
            const SectionHeader(title: 'ProfileAvatar'),
            const LedgerSheet(
              padding: EdgeInsets.all(AppSpace.x16),
              child: Row(
                children: [
                  ProfileAvatar(size: 72, name: 'Rahul'),
                  SizedBox(width: AppSpace.x16),
                  ProfileAvatar(size: 48, name: 'Sunil'),
                  SizedBox(width: AppSpace.x16),
                  ProfileAvatar(size: 48),
                ],
              ),
            ),

            // 11. Skeleton
            const SectionHeader(title: 'Skeleton Placeholder'),
            const LedgerSheet(
              padding: EdgeInsets.all(AppSpace.x16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBlock(width: 200, height: 24),
                  SizedBox(height: AppSpace.x12),
                  SkeletonBlock(width: 140, height: 16),
                  SizedBox(height: AppSpace.x16),
                  SkeletonList(itemCount: 2),
                ],
              ),
            ),

            // 12. EmptyState
            const SectionHeader(title: 'EmptyState'),
            LedgerSheet(
              padding: const EdgeInsets.all(AppSpace.x16),
              child: EmptyState(
                icon: AppIcons.guests,
                title: 'Primary text',
                body: 'Secondary text explaining what is empty and how to proceed.',
                actionLabel: 'Primary action',
                onAction: () {},
              ),
            ),

            // 13. ErrorState
            const SectionHeader(title: 'ErrorState'),
            LedgerSheet(
              padding: const EdgeInsets.all(AppSpace.x16),
              child: ErrorState(
                title: 'Primary text',
                message: 'Secondary text explaining the error reason.',
                onRetry: () {},
              ),
            ),

            // 14. AppTopBar and PgSwitcherTitle
            const SectionHeader(title: 'AppTopBar & PgSwitcherTitle'),
            LedgerSheet(
              padding: const EdgeInsets.all(AppSpace.x16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppTopBar.back(
                    title: 'Primary text',
                    actions: [
                      Icon(AppIcons.search, size: 24, color: AppColors.ink),
                    ],
                  ),
                  const SizedBox(height: AppSpace.x12),
                  const AppTopBar.close(
                    title: 'Modal title',
                  ),
                  const SizedBox(height: AppSpace.x12),
                  AppTopBar(
                    titleWidget: PgSwitcherTitle(
                      pgName: 'Primary text',
                      onTap: () {},
                    ),
                    actions: const [
                      Icon(AppIcons.bell, size: 24, color: AppColors.ink),
                    ],
                  ),
                ],
              ),
            ),

            // 15. AppBottomNav
            const SectionHeader(title: 'AppBottomNav'),
            LedgerSheet(
              padding: EdgeInsets.zero,
              child: AppBottomNav(
                currentIndex: _navIndex,
                onTap: (index) => setState(() => _navIndex = index),
                items: const [
                  AppBottomNavItem(
                    icon: AppIcons.home,
                    activeIcon: AppIcons.homeFill,
                    label: 'Home',
                  ),
                  AppBottomNavItem(
                    icon: AppIcons.guests,
                    activeIcon: AppIcons.guestsFill,
                    label: 'Guests',
                    badgeCount: 100,
                  ),
                  AppBottomNavItem(
                    icon: AppIcons.payments,
                    activeIcon: AppIcons.paymentsFill,
                    label: 'Payments',
                    badgeCount: 3,
                  ),
                  AppBottomNavItem(
                    icon: AppIcons.more,
                    activeIcon: AppIcons.moreFill,
                    label: 'More',
                  ),
                ],
              ),
            ),

            // 16. UnderlineTabs
            const SectionHeader(title: 'UnderlineTabs'),
            LedgerSheet(
              padding: EdgeInsets.zero,
              child: UnderlineTabs(
                selectedIndex: _tabIndex,
                onTabSelected: (index) => setState(() => _tabIndex = index),
                tabs: const [
                  UnderlineTabItem(label: 'All', count: 12),
                  UnderlineTabItem(label: 'Paid', count: 8),
                  UnderlineTabItem(label: 'Pending', count: 4),
                  UnderlineTabItem(label: 'Overdue'),
                ],
              ),
            ),

            // 17. AppTextField
            const SectionHeader(title: 'AppTextField'),
            const LedgerSheet(
              padding: EdgeInsets.all(AppSpace.x16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    label: 'Label',
                    hint: 'Primary text',
                    helperText: 'Secondary text explaining input format.',
                  ),
                  SizedBox(height: AppSpace.x16),
                  AppTextField(
                    label: 'Label with error',
                    hint: 'Primary text',
                    errorText: 'Secondary text explaining the error.',
                  ),
                  SizedBox(height: AppSpace.x16),
                  AppTextField(
                    label: 'Label (disabled)',
                    hint: 'Primary text',
                    enabled: false,
                  ),
                  SizedBox(height: AppSpace.x16),
                  AppTextField(
                    label: 'Label (notes)',
                    hint: 'Primary text',
                    maxLines: 3,
                  ),
                ],
              ),
            ),

            // 18. PhoneField
            const SectionHeader(title: 'PhoneField'),
            const LedgerSheet(
              padding: EdgeInsets.all(AppSpace.x16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PhoneField(
                    label: 'Phone number',
                    helperText: 'Enter 10-digit mobile number.',
                  ),
                  SizedBox(height: AppSpace.x16),
                  PhoneField(
                    label: 'Phone number with error',
                    errorText: 'Enter a valid 10-digit mobile number.',
                  ),
                ],
              ),
            ),

            // 19. MoneyField
            const SectionHeader(title: 'MoneyField'),
            const LedgerSheet(
              padding: EdgeInsets.all(AppSpace.x16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MoneyField(
                    label: 'Rent amount',
                    initialPaise: 650000,
                    helperText: 'Monthly rent in rupees.',
                  ),
                  SizedBox(height: AppSpace.x16),
                  MoneyField(
                    label: 'Amount received (Large)',
                    initialPaise: 12500000,
                    isLarge: true,
                  ),
                ],
              ),
            ),

            // 20. SelectField & OptionSheet
            const SectionHeader(title: 'SelectField & OptionSheet'),
            LedgerSheet(
              padding: const EdgeInsets.all(AppSpace.x16),
              child: SelectField(
                label: 'Payment cycle',
                value: _selectValue,
                onTap: () async {
                  final picked = await OptionSheet.show<String>(
                    context: context,
                    title: 'Select option',
                    selectedValue: _selectValue,
                    showSearch: true,
                    options: const [
                      OptionSheetItem(
                        value: 'Option 1',
                        title: 'Option 1',
                        subtitle: 'Secondary text 1',
                      ),
                      OptionSheetItem(
                        value: 'Option 2',
                        title: 'Option 2',
                        subtitle: 'Secondary text 2',
                      ),
                      OptionSheetItem(
                        value: 'Option 3',
                        title: 'Option 3',
                      ),
                    ],
                  );
                  if (picked != null) {
                    setState(() => _selectValue = picked);
                  }
                },
              ),
            ),

            // 21. DateField
            const SectionHeader(title: 'DateField'),
            LedgerSheet(
              padding: const EdgeInsets.all(AppSpace.x16),
              child: DateField(
                label: 'Due date',
                value: _selectedDate,
                onChanged: (d) => setState(() => _selectedDate = d),
              ),
            ),

            // 22. OtpField
            const SectionHeader(title: 'OtpField'),
            LedgerSheet(
              padding: const EdgeInsets.all(AppSpace.x16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OtpField(
                    hasError: _otpError,
                    onCompleted: (code) {},
                  ),
                  const SizedBox(height: AppSpace.x16),
                  AppButton.secondary(
                    label: _otpError ? 'Clear error' : 'Trigger error shake',
                    onPressed: () => setState(() => _otpError = !_otpError),
                  ),
                ],
              ),
            ),

            // 23. OptionRow
            const SectionHeader(title: 'OptionRow'),
            LedgerSheet(
              padding: const EdgeInsets.all(AppSpace.x16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OptionRow<String>(
                    selectedValue: _selectedOption,
                    onChanged: (val) => setState(() => _selectedOption = val),
                    options: const [
                      OptionRowItem(value: '1', label: 'Option 1'),
                      OptionRowItem(value: '2', label: 'Option 2'),
                      OptionRowItem(value: '3', label: 'Option 3'),
                    ],
                  ),
                  const SizedBox(height: AppSpace.x16),
                  OptionRow<String>(
                    selectedValue: _selectedGridOption,
                    onChanged: (val) => setState(() => _selectedGridOption = val),
                    options: const [
                      OptionRowItem(value: 'A', label: 'Option A'),
                      OptionRowItem(value: 'B', label: 'Option B'),
                      OptionRowItem(value: 'C', label: 'Option C'),
                      OptionRowItem(value: 'D', label: 'Option D'),
                    ],
                  ),
                ],
              ),
            ),

            // 24. SwitchRow
            const SectionHeader(title: 'SwitchRow'),
            LedgerSheet(
              children: [
                SwitchRow(
                  label: 'Primary text',
                  helper: 'Secondary text explaining toggle effect.',
                  value: _switchVal1,
                  onChanged: (v) => setState(() => _switchVal1 = v),
                ),
                SwitchRow(
                  label: 'Primary text',
                  value: _switchVal2,
                  showDivider: false,
                  onChanged: (v) => setState(() => _switchVal2 = v),
                ),
              ],
            ),

            // 24b. BedsStepper
            const SectionHeader(title: 'BedsStepper'),
            LedgerSheet(
              padding: const EdgeInsets.all(AppSpace.x16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Beds in room', style: AppText.body),
                  BedsStepper(
                    value: _stepperBeds,
                    onChanged: (v) => setState(() => _stepperBeds = v),
                  ),
                ],
              ),
            ),

            // 25. AppBottomSheet & ConfirmSheet
            const SectionHeader(title: 'AppBottomSheet & ConfirmSheet'),
            LedgerSheet(
              padding: const EdgeInsets.all(AppSpace.x16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppButton.secondary(
                    label: 'Open AppBottomSheet',
                    onPressed: () {
                      AppBottomSheet.show(
                        context: context,
                        builder: (ctx) => const AppBottomSheet(
                          title: 'Primary text',
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSpace.x16),
                            child: Text(
                              'Secondary text inside bottom sheet.',
                              style: AppText.body,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpace.x12),
                  AppButton.destructive(
                    label: 'Open ConfirmSheet (Destructive)',
                    onPressed: () {
                      ConfirmSheet.show(
                        context: context,
                        title: 'Primary text',
                        body: 'Secondary text explaining destructive consequences.',
                        confirmLabel: 'Confirm action',
                        isDestructive: true,
                        showReasonField: true,
                        reasonLabel: 'Reason (optional)',
                      );
                    },
                  ),
                ],
              ),
            ),

            // 26. AppSnack
            const SectionHeader(title: 'AppSnack'),
            LedgerSheet(
              padding: const EdgeInsets.all(AppSpace.x16),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton.secondary(
                      label: 'Simple Snack',
                      onPressed: () {
                        AppSnack.show(
                          context,
                          message: 'Primary notification text.',
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpace.x12),
                  Expanded(
                    child: AppButton.secondary(
                      label: 'Action Snack',
                      onPressed: () {
                        AppSnack.show(
                          context,
                          message: 'Primary notification text.',
                          actionLabel: 'Action',
                          onAction: () {},
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // 27. TickBadge
            const SectionHeader(title: 'TickBadge'),
            const LedgerSheet(
              padding: EdgeInsets.all(AppSpace.x16),
              child: Center(
                child: TickBadge(),
              ),
            ),

            // 28. Stamp
            const SectionHeader(title: 'Stamp'),
            const LedgerSheet(
              padding: EdgeInsets.all(AppSpace.x16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Stamp.paid(),
                  Stamp.pending(),
                  Stamp.overdue(),
                ],
              ),
            ),

            // 29. ReceiptPaper
            const SectionHeader(title: 'ReceiptPaper'),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpace.x16),
              child: ReceiptPaper(
                header: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Receipt', style: AppText.title),
                        Stamp.paid(),
                      ],
                    ),
                    SizedBox(height: AppSpace.x8),
                    Text('12 Nov 2026', style: AppText.secondary),
                  ],
                ),
                body: Column(
                  children: [
                    KeyValueRow(
                      label: 'Guest',
                      value: 'Primary text',
                    ),
                    KeyValueRow(
                      label: 'Room',
                      value: '101',
                    ),
                    KeyValueRow(
                      label: 'Amount',
                      value: '₹6,500',
                      showDivider: false,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpace.x32),
          ],
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final String name;
  final Color color;
  final bool border;

  const _ColorSwatch({
    required this.name,
    required this.color,
    this.border = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: AppRadius.chip,
              border: border ||
                      color == AppColors.surface ||
                      color == AppColors.ground ||
                      color == AppColors.transparent
                  ? Border.all(color: AppColors.hairline)
                  : null,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 32,
            child: Text(
              name,
              style: AppText.caption,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
