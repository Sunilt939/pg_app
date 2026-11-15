import 'package:flutter/material.dart' show Scaffold;
import 'package:flutter/widgets.dart';
import '../core/theme/app_icons.dart';
import '../core/theme/tokens.dart';
import '../core/widgets/app_button.dart';
import '../core/widgets/empty_state.dart';
import '../core/widgets/error_state.dart';
import '../core/widgets/key_value_row.dart';
import '../core/widgets/ledger_row.dart';
import '../core/widgets/ledger_sheet.dart';
import '../core/widgets/money.dart';
import '../core/widgets/profile_avatar.dart';
import '../core/widgets/progress_bar_thin.dart';
import '../core/widgets/room_tile.dart';
import '../core/widgets/section_header.dart';
import '../core/widgets/skeleton.dart';
import '../core/widgets/status_chip.dart';

class ComponentGallery extends StatefulWidget {
  const ComponentGallery({super.key});

  @override
  State<ComponentGallery> createState() => _ComponentGalleryState();
}

class _ComponentGalleryState extends State<ComponentGallery> {
  int _counter = 0;

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
                'Component Gallery (Set 1)',
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
                runSpacing: AppSpace.x8,
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
                  _ColorSwatch(name: 'overdueBg', color: AppColors.overdueBg),
                  _ColorSwatch(name: 'disabledBg', color: AppColors.disabledBg),
                  _ColorSwatch(name: 'skeletonBase', color: AppColors.skeletonBase),
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
                      label: 'Record payment',
                      onPressed: () {},
                    ),
                    AppButton.text(
                      label: 'Remind',
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            borderRadius: AppRadius.chip,
            border: border ? Border.all(color: AppColors.hairline) : null,
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          width: 56,
          child: Text(
            name,
            style: AppText.caption,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

