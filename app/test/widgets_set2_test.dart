import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/theme/app_icons.dart';
import 'package:app/core/widgets/app_bottom_nav.dart';
import 'package:app/core/widgets/app_bottom_sheet.dart';
import 'package:app/core/widgets/app_text_field.dart';
import 'package:app/core/widgets/app_top_bar.dart';
import 'package:app/core/widgets/date_field.dart';
import 'package:app/core/widgets/money_field.dart';
import 'package:app/core/widgets/option_row.dart';
import 'package:app/core/widgets/option_sheet.dart';
import 'package:app/core/widgets/otp_field.dart';
import 'package:app/core/widgets/pg_switcher_title.dart';
import 'package:app/core/widgets/phone_field.dart';
import 'package:app/core/widgets/receipt_paper.dart';
import 'package:app/core/widgets/select_field.dart';
import 'package:app/core/widgets/stamp.dart';
import 'package:app/core/widgets/switch_row.dart';
import 'package:app/core/widgets/tick_badge.dart';
import 'package:app/core/widgets/underline_tabs.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Directionality(
        textDirection: TextDirection.ltr,
        child: child,
      ),
    ),
  );
}

void main() {
  testWidgets('AppTextField renders label, hint, helper and error', (tester) async {
    await tester.pumpWidget(_wrap(
      const AppTextField(
        label: 'Field Label',
        hint: 'Field Hint',
        helperText: 'Helper info',
        errorText: 'Error info',
      ),
    ));

    expect(find.text('Field Label'), findsOneWidget);
    expect(find.text('Field Hint'), findsOneWidget);
    expect(find.text('Error info'), findsOneWidget);
  });

  testWidgets('PhoneField enforces formatting and handles input', (tester) async {
    String? captured;
    final controller = TextEditingController();
    await tester.pumpWidget(_wrap(
      PhoneField(
        label: 'Mobile',
        controller: controller,
        onChanged: (val) => captured = val,
      ),
    ));

    expect(find.text('+91'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '9876543210');
    await tester.pumpAndSettle();

    expect(captured, '+919876543210');
    expect(controller.text, '98765 43210');
  });

  testWidgets('MoneyField formats Indian grouping and calculates paise', (tester) async {
    int? capturedPaise;
    await tester.pumpWidget(_wrap(
      MoneyField(
        label: 'Amount',
        onChanged: (val) => capturedPaise = val,
      ),
    ));

    expect(find.text('₹'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '125000');
    await tester.pump();

    expect(find.text('1,25,000'), findsOneWidget);
    expect(capturedPaise, 12500000);
  });

  testWidgets('SelectField renders value and chevronDown icon', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_wrap(
      SelectField(
        label: 'Select Plan',
        value: 'Monthly',
        onTap: () => tapped = true,
      ),
    ));

    expect(find.text('Select Plan'), findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget);
    expect(find.byIcon(AppIcons.chevronDown), findsOneWidget);

    await tester.tap(find.byType(SelectField));
    expect(tapped, isTrue);
  });

  testWidgets('OptionSheet renders items and checks selected value', (tester) async {
    await tester.pumpWidget(_wrap(
      const OptionSheet<String>(
        title: 'Choose Option',
        selectedValue: '2',
        options: [
          OptionSheetItem(value: '1', title: 'First Item'),
          OptionSheetItem(value: '2', title: 'Second Item', subtitle: 'Detail'),
        ],
      ),
    ));

    expect(find.text('Choose Option'), findsOneWidget);
    expect(find.text('First Item'), findsOneWidget);
    expect(find.text('Second Item'), findsOneWidget);
    expect(find.text('Detail'), findsOneWidget);
    expect(find.byIcon(AppIcons.check), findsOneWidget);
  });

  testWidgets('DateField renders formatted date and calendar icon', (tester) async {
    await tester.pumpWidget(_wrap(
      DateField(
        label: 'Due Date',
        value: DateTime(2026, 11, 12),
      ),
    ));

    expect(find.text('Due Date'), findsOneWidget);
    expect(find.text('12 Nov 2026'), findsOneWidget);
    expect(find.byIcon(AppIcons.calendar), findsOneWidget);
  });

  testWidgets('OtpField renders boxes and triggers onCompleted', (tester) async {
    String? completedCode;
    await tester.pumpWidget(_wrap(
      OtpField(
        length: 6,
        onCompleted: (code) => completedCode = code,
      ),
    ));

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pumpAndSettle();

    expect(completedCode, '123456');
  });

  testWidgets('OptionRow renders 3 options in row and handles selection', (tester) async {
    String? selected = 'A';
    await tester.pumpWidget(_wrap(
      StatefulBuilder(
        builder: (context, setState) => OptionRow<String>(
          selectedValue: selected,
          onChanged: (val) => setState(() => selected = val),
          options: const [
            OptionRowItem(value: 'A', label: 'Option A'),
            OptionRowItem(value: 'B', label: 'Option B'),
            OptionRowItem(value: 'C', label: 'Option C'),
          ],
        ),
      ),
    ));

    expect(find.text('Option A'), findsOneWidget);
    expect(find.text('Option B'), findsOneWidget);
    expect(find.text('Option C'), findsOneWidget);

    await tester.tap(find.text('Option B'));
    await tester.pumpAndSettle();
    expect(selected, 'B');
  });

  testWidgets('UnderlineTabs renders tabs and switches on tap', (tester) async {
    var selectedIndex = 0;
    await tester.pumpWidget(_wrap(
      StatefulBuilder(
        builder: (context, setState) => UnderlineTabs(
          selectedIndex: selectedIndex,
          onTabSelected: (index) => setState(() => selectedIndex = index),
          tabs: const [
            UnderlineTabItem(label: 'All', count: 5),
            UnderlineTabItem(label: 'Paid'),
          ],
        ),
      ),
    ));

    expect(find.text('All'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('Paid'), findsOneWidget);

    await tester.tap(find.text('Paid'));
    await tester.pumpAndSettle();
    expect(selectedIndex, 1);
  });

  testWidgets('SwitchRow toggles value on tap', (tester) async {
    var toggled = false;
    await tester.pumpWidget(_wrap(
      StatefulBuilder(
        builder: (context, setState) => SwitchRow(
          label: 'Enable notifications',
          value: toggled,
          onChanged: (v) => setState(() => toggled = v),
        ),
      ),
    ));

    expect(find.text('Enable notifications'), findsOneWidget);
    await tester.tap(find.byType(SwitchRow));
    await tester.pumpAndSettle();
    expect(toggled, isTrue);
  });

  testWidgets('AppTopBar renders back and close variants', (tester) async {
    await tester.pumpWidget(_wrap(
      const Column(
        children: [
          AppTopBar.back(title: 'Back Top Bar'),
          AppTopBar.close(title: 'Close Top Bar'),
        ],
      ),
    ));

    expect(find.text('Back Top Bar'), findsOneWidget);
    expect(find.text('Close Top Bar'), findsOneWidget);
    expect(find.byIcon(AppIcons.back), findsOneWidget);
    expect(find.byIcon(AppIcons.close), findsOneWidget);
  });

  testWidgets('PgSwitcherTitle renders title and chevronDown', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_wrap(
      PgSwitcherTitle(
        pgName: 'Sri Sai PG',
        onTap: () => tapped = true,
      ),
    ));

    expect(find.text('Sri Sai PG'), findsOneWidget);
    expect(find.byIcon(AppIcons.chevronDown), findsOneWidget);

    await tester.tap(find.byType(PgSwitcherTitle));
    expect(tapped, isTrue);
  });

  testWidgets('AppBottomNav renders items and badge count', (tester) async {
    await tester.pumpWidget(_wrap(
      AppBottomNav(
        currentIndex: 0,
        onTap: (_) {},
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
            badgeCount: 105,
          ),
        ],
      ),
    ));

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Guests'), findsOneWidget);
    expect(find.text('99+'), findsOneWidget);
  });

  testWidgets('TickBadge and Stamp render properly', (tester) async {
    await tester.pumpWidget(_wrap(
      const Column(
        children: [
          TickBadge(),
          Stamp.paid(),
          Stamp.pending(),
          Stamp.overdue(),
        ],
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(TickBadge), findsOneWidget);
    expect(find.text('Paid'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Overdue'), findsOneWidget);
  });

  testWidgets('ReceiptPaper renders header and body', (tester) async {
    await tester.pumpWidget(_wrap(
      const ReceiptPaper(
        header: Text('Receipt Header'),
        body: Text('Receipt Body'),
      ),
    ));

    expect(find.text('Receipt Header'), findsOneWidget);
    expect(find.text('Receipt Body'), findsOneWidget);
  });

  testWidgets('ConfirmSheet renders message and buttons', (tester) async {
    await tester.pumpWidget(_wrap(
      const ConfirmSheet(
        title: 'Delete PG',
        body: 'Are you sure you want to delete?',
        confirmLabel: 'Delete',
        isDestructive: true,
      ),
    ));

    expect(find.text('Delete PG'), findsOneWidget);
    expect(find.text('Are you sure you want to delete?'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });
}

