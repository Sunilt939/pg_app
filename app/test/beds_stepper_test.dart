import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/l10n/app_localizations.dart';
import 'package:app/core/theme/app_icons.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/beds_stepper.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Center(child: child),
    ),
  );
}

void main() {
  testWidgets('BedsStepper renders value and has exact dimensions 136x44', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const BedsStepper(value: 2),
      ),
    );
    await tester.pumpAndSettle();

    final finder = find.byType(BedsStepper);
    expect(finder, findsOneWidget);
    final size = tester.getSize(finder);
    expect(size.width, 136.0);
    expect(size.height, 44.0);

    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('BedsStepper disables minus at min and plus at max', (tester) async {
    int? changedVal;

    // Test at min (1)
    await tester.pumpWidget(
      _wrap(
        BedsStepper(
          value: 1,
          min: 1,
          max: 12,
          onChanged: (v) => changedVal = v,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Minus button tap does nothing
    await tester.tap(find.byIcon(AppIcons.minus));
    await tester.pumpAndSettle();
    expect(changedVal, isNull);

    // Plus button tap increments
    await tester.tap(find.byIcon(AppIcons.add));
    await tester.pumpAndSettle();
    expect(changedVal, 2);

    // Test at max (12)
    changedVal = null;
    await tester.pumpWidget(
      _wrap(
        BedsStepper(
          value: 12,
          min: 1,
          max: 12,
          onChanged: (v) => changedVal = v,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Plus button tap does nothing
    await tester.tap(find.byIcon(AppIcons.add));
    await tester.pumpAndSettle();
    expect(changedVal, isNull);

    // Minus button tap decrements
    await tester.tap(find.byIcon(AppIcons.minus));
    await tester.pumpAndSettle();
    expect(changedVal, 11);
  });

  testWidgets('BedsStepper accessibility labels and semantics', (tester) async {
    await tester.pumpWidget(
      _wrap(
        BedsStepper(
          value: 3,
          onChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Fewer beds'), findsOneWidget);
    expect(find.bySemanticsLabel('More beds'), findsOneWidget);
    expect(find.bySemanticsLabel('3 beds'), findsOneWidget);
  });
}

