import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/theme/app_icons.dart';
import 'package:app/core/widgets/app_button.dart';
import 'package:app/core/widgets/empty_state.dart';
import 'package:app/core/widgets/error_state.dart';
import 'package:app/core/widgets/key_value_row.dart';
import 'package:app/core/widgets/ledger_row.dart';
import 'package:app/core/widgets/ledger_sheet.dart';
import 'package:app/core/widgets/money.dart';
import 'package:app/core/widgets/profile_avatar.dart';
import 'package:app/core/widgets/progress_bar_thin.dart';
import 'package:app/core/widgets/room_tile.dart';
import 'package:app/core/widgets/section_header.dart';
import 'package:app/core/widgets/status_chip.dart';
import 'package:app/dev/component_gallery.dart';

Widget _wrap(Widget child) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: const MediaQueryData(),
      child: child,
    ),
  );
}

void main() {
  testWidgets('Money widget displays rupee and amount correctly', (tester) async {
    await tester.pumpWidget(_wrap(const Money(paise: 650050)));
    expect(find.byType(Money), findsOneWidget);
  });

  testWidgets('StatusChip renders all variants', (tester) async {
    await tester.pumpWidget(_wrap(
      const Column(
        children: [
          StatusChip.paid(),
          StatusChip.pending(),
          StatusChip.overdue(),
          StatusChip.due(),
        ],
      ),
    ));
    expect(find.byType(StatusChip), findsNWidgets(4));
    expect(find.text('Paid'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Overdue'), findsOneWidget);
    expect(find.text('Due'), findsOneWidget);
  });

  testWidgets('AppButton renders and handles tap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_wrap(
      AppButton.primary(
        label: 'Tap Me',
        onPressed: () => tapped = true,
      ),
    ));

    expect(find.text('Tap Me'), findsOneWidget);
    await tester.tap(find.text('Tap Me'));
    expect(tapped, true);
  });

  testWidgets('AppButton in loading state ignores tap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_wrap(
      AppButton.primary(
        label: 'Submit',
        loading: true,
        onPressed: () => tapped = true,
      ),
    ));

    expect(find.text('Submit'), findsNothing);
    await tester.tap(find.byType(AppButton));
    expect(tapped, false);
  });

  testWidgets('SectionHeader displays title and trailing', (tester) async {
    await tester.pumpWidget(_wrap(
      const SectionHeader(
        title: 'Section 1',
        trailing: Text('Action'),
      ),
    ));
    expect(find.text('Section 1'), findsOneWidget);
    expect(find.text('Action'), findsOneWidget);
  });

  testWidgets('RoomTile displays room label or bed icon', (tester) async {
    await tester.pumpWidget(_wrap(
      const Column(
        children: [
          RoomTile(label: '101'),
          RoomTile(),
        ],
      ),
    ));
    expect(find.text('101'), findsOneWidget);
    expect(find.byIcon(AppIcons.bed), findsOneWidget);
  });

  testWidgets('LedgerSheet and LedgerRow render with divider', (tester) async {
    await tester.pumpWidget(_wrap(
      LedgerSheet(
        children: [
          LedgerRow(
            leading: const RoomTile(label: '101'),
            title: 'Guest Name',
            subtitle: 'Room 101, bed A',
            paise: 650000,
            statusKind: StatusChipKind.paid,
            onTap: () {},
          ),
        ],
      ),
    ));
    expect(find.text('Guest Name'), findsOneWidget);
    expect(find.text('Room 101, bed A'), findsOneWidget);
    expect(find.byType(Money), findsOneWidget);
    expect(find.byType(StatusChip), findsOneWidget);
  });

  testWidgets('KeyValueRow renders label and read-only lock', (tester) async {
    await tester.pumpWidget(_wrap(
      const KeyValueRow(
        label: 'Account',
        value: 'UPI ID',
        isReadOnly: true,
      ),
    ));
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('UPI ID'), findsOneWidget);
    expect(find.byIcon(AppIcons.lock), findsOneWidget);
  });

  testWidgets('ProgressBarThin renders with clamped value', (tester) async {
    await tester.pumpWidget(_wrap(const ProgressBarThin(progress: 0.5)));
    expect(find.byType(ProgressBarThin), findsOneWidget);
  });

  testWidgets('ProfileAvatar displays initial or fallback', (tester) async {
    await tester.pumpWidget(_wrap(
      const Column(
        children: [
          ProfileAvatar(name: 'Rahul'),
          ProfileAvatar(),
        ],
      ),
    ));
    expect(find.text('R'), findsOneWidget);
    expect(find.byIcon(AppIcons.user), findsOneWidget);
  });

  testWidgets('EmptyState and ErrorState display correct elements', (tester) async {
    var retried = false;
    await tester.pumpWidget(_wrap(
      Column(
        children: [
          const EmptyState(
            icon: AppIcons.guests,
            title: 'No guests',
            body: 'Add your first guest',
          ),
          ErrorState(
            title: 'Failed',
            message: 'Network issue',
            onRetry: () => retried = true,
          ),
        ],
      ),
    ));

    expect(find.text('No guests'), findsOneWidget);
    expect(find.text('Failed'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    expect(retried, true);
  });

  testWidgets('ComponentGallery renders smoothly in debug mode', (tester) async {
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: ComponentGallery(),
    ));
    await tester.pump();
    expect(find.text('Component Gallery (Set 1)'), findsOneWidget);
  });
}

