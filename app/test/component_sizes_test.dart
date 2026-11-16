import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/theme/app_icons.dart';
import 'package:app/core/theme/tokens.dart';
import 'package:app/core/widgets/app_bottom_nav.dart';
import 'package:app/core/widgets/app_button.dart';
import 'package:app/core/widgets/app_text_field.dart';
import 'package:app/core/widgets/date_field.dart';
import 'package:app/core/widgets/money_field.dart';
import 'package:app/core/widgets/otp_field.dart';
import 'package:app/core/widgets/phone_field.dart';
import 'package:app/core/widgets/room_tile.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: MediaQuery(
        data: const MediaQueryData(padding: EdgeInsets.zero),
        child: Center(
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('AppButton has exact height 48', (tester) async {
    await tester.pumpWidget(_wrap(
      const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppButton.primary(label: 'Primary Button'),
          AppButton.secondary(label: 'Secondary Button'),
          AppButton.destructive(label: 'Destructive Button'),
        ],
      ),
    ));

    final buttons = find.byType(AppButton);
    expect(buttons, findsNWidgets(3));

    for (var i = 0; i < 3; i++) {
      final size = tester.getSize(buttons.at(i));
      expect(size.height, AppSize.button);
      expect(size.height, 48.0);
    }
  });

  testWidgets('Fields have exact container height 52', (tester) async {
    await tester.pumpWidget(_wrap(
      const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(),
          PhoneField(),
          MoneyField(),
          DateField(),
        ],
      ),
    ));

    // Each field contains an internal Container with border and height 52
    final textFields = find.byType(TextField);
    expect(textFields, findsNWidgets(4));

    // Check AppTextField size directly
    final appTextFields = find.byType(AppTextField);
    expect(appTextFields, findsNWidgets(4));

    for (var i = 0; i < 4; i++) {
      final size = tester.getSize(appTextFields.at(i));
      expect(size.height, AppSize.field);
      expect(size.height, 52.0);
    }
  });

  testWidgets('RoomTile has exact dimensions 44x44', (tester) async {
    await tester.pumpWidget(_wrap(
      const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RoomTile(label: '101'),
          RoomTile(),
        ],
      ),
    ));

    final tiles = find.byType(RoomTile);
    expect(tiles, findsNWidgets(2));

    for (var i = 0; i < 2; i++) {
      final size = tester.getSize(tiles.at(i));
      expect(size.width, AppSize.tile);
      expect(size.height, AppSize.tile);
      expect(size.width, 44.0);
      expect(size.height, 44.0);
    }
  });

  testWidgets('AppBottomNav has exact height 64', (tester) async {
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
          ),
        ],
      ),
    ));

    final navSize = tester.getSize(find.byType(AppBottomNav));
    expect(navSize.height, AppSize.bottomNav);
    expect(navSize.height, 64.0);
  });

  testWidgets('OtpField boxes have exact height 56', (tester) async {
    await tester.pumpWidget(_wrap(
      const OtpField(length: 6),
    ));

    final otpBoxes = find.descendant(
      of: find.byType(OtpField),
      matching: find.byType(Container),
    );

    // Filter boxes that have height 56
    var foundBoxes = 0;
    for (final element in otpBoxes.evaluate()) {
      final renderBox = element.renderObject as RenderBox?;
      if (renderBox != null && renderBox.hasSize && renderBox.size.height == 56.0) {
        foundBoxes++;
      }
    }
    expect(foundBoxes, greaterThanOrEqualTo(6));
  });
}

