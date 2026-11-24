import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/l10n/app_localizations.dart';
import 'package:app/core/theme/app_icons.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/app_button.dart';
import 'package:app/core/widgets/app_text_field.dart';
import 'package:app/core/widgets/error_state.dart';
import 'package:app/core/widgets/key_value_row.dart';
import 'package:app/core/widgets/phone_field.dart';
import 'package:app/core/widgets/skeleton.dart';
import 'package:app/features/auth/domain/auth_context.dart';
import 'package:app/features/auth/domain/auth_repository.dart';
import 'package:app/features/auth/presentation/providers/auth_provider.dart';
import 'package:app/features/owner/domain/city.dart';
import 'package:app/features/owner/domain/owner_repository.dart';
import 'package:app/features/owner/presentation/providers/owner_provider.dart';
import 'package:app/features/owner/presentation/screens/owner_settings_screen.dart';

class MockAuthRepo implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<AuthContext> getMyContext() async {
    return const AuthContext(
      person: AuthPerson(id: 'p-1', phone: '+919876543210'),
      pgs: [AuthPg(pgId: 'pg-1', name: 'Sunrise PG', role: 'owner')],
    );
  }
}

class MockOwnerRepo implements OwnerRepository {
  PgDetails? details;
  bool shouldThrow = false;
  String? updatedName;
  String? updatedGenderPolicy;
  String? updatedContactPhone;
  Map<String, dynamic>? updatedAddress;

  MockOwnerRepo({this.details});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<PgDetails?> getPgDetails(String pgId) async {
    if (shouldThrow) throw Exception('Network error');
    return details;
  }

  @override
  Future<void> updatePgName({
    required String pgId,
    required String name,
  }) async {
    if (shouldThrow) throw Exception('Update name failed');
    updatedName = name;
    if (details != null) {
      details = details!.copyWith(name: name);
    }
  }

  @override
  Future<void> updatePgGenderPolicy({
    required String pgId,
    required String genderPolicy,
  }) async {
    if (shouldThrow) throw Exception('Update gender failed');
    updatedGenderPolicy = genderPolicy;
    if (details != null) {
      details = details!.copyWith(genderPolicy: genderPolicy);
    }
  }

  @override
  Future<void> updatePgContactPhone({
    required String pgId,
    String? contactPhone,
  }) async {
    if (shouldThrow) throw Exception('Update contact failed');
    updatedContactPhone = contactPhone;
    if (details != null) {
      details = details!.copyWith(contactPhone: contactPhone);
    }
  }

  @override
  Future<void> updatePgAddress({
    required String pgId,
    required String addressId,
    required String line1,
    String? area,
    required int cityId,
    String? pincode,
  }) async {
    if (shouldThrow) throw Exception('Update address failed');
    updatedAddress = {
      'line1': line1,
      'area': area,
      'cityId': cityId,
      'pincode': pincode,
    };
    if (details != null) {
      details = details!.copyWith(
        line1: line1,
        area: area,
        cityId: cityId,
        pincode: pincode,
      );
    }
  }

  @override
  Future<List<City>> getCities() async {
    return const [
      City(id: 1, name: 'Bengaluru', stateName: 'Karnataka'),
      City(id: 2, name: 'Mumbai', stateName: 'Maharashtra'),
    ];
  }
}

Widget createTestApp({
  required MockOwnerRepo mockOwnerRepo,
  MockAuthRepo? mockAuthRepo,
  bool provideActivePg = true,
}) {
  return ProviderScope(
    overrides: [
      ownerRepositoryProvider.overrideWithValue(mockOwnerRepo),
      authRepositoryProvider.overrideWithValue(mockAuthRepo ?? MockAuthRepo()),
      if (provideActivePg)
        activePgProvider.overrideWithValue(
          const AuthPg(pgId: 'pg-1', name: 'Sunrise PG', role: 'owner'),
        ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const OwnerSettingsScreen(),
    ),
  );
}

void main() {
  const sampleDetails = PgDetails(
    id: 'pg-1',
    name: 'Sunrise Living',
    genderPolicy: 'men',
    contactPhone: '+919876543210',
    addressId: 'addr-1',
    line1: '123 MG Road',
    area: 'Indiranagar',
    cityId: 1,
    cityName: 'Bengaluru',
    stateName: 'Karnataka',
    pincode: '560038',
  );

  group('PgDetails domain model', () {
    test('formattedAddress formats with all fields', () {
      expect(
        sampleDetails.formattedAddress,
        equals('123 MG Road\nIndiranagar\nBengaluru, Karnataka 560038'),
      );
    });

    test('formattedAddress formats without area or pincode', () {
      const minimal = PgDetails(
        id: 'pg-2',
        name: 'Cozy PG',
        genderPolicy: 'any',
        line1: '456 Main St',
        cityId: 1,
        cityName: 'Bengaluru',
        stateName: 'Karnataka',
      );
      expect(minimal.formattedAddress, equals('456 Main St\nBengaluru, Karnataka'));
    });

    test('copyWith updates properties', () {
      final updated = sampleDetails.copyWith(name: 'New PG Name', genderPolicy: 'women');
      expect(updated.name, equals('New PG Name'));
      expect(updated.genderPolicy, equals('women'));
      expect(updated.id, equals(sampleDetails.id));
    });

    test('fromJson parses correctly', () {
      final json = {
        'id': 'pg-10',
        'name': 'Test PG',
        'gender_policy': 'women',
        'contact_phone': '+919988776655',
        'address_id': 'addr-10',
        'addresses': {
          'line1': '789 Park St',
          'area': 'Koramangala',
          'city_id': 1,
          'pincode': '560034',
          'cities': {
            'id': 1,
            'name': 'Bengaluru',
            'states': {'name': 'Karnataka'},
          },
        },
      };

      final parsed = PgDetails.fromJson(json);
      expect(parsed.id, equals('pg-10'));
      expect(parsed.name, equals('Test PG'));
      expect(parsed.genderPolicy, equals('women'));
      expect(parsed.contactPhone, equals('+919988776655'));
      expect(parsed.addressId, equals('addr-10'));
      expect(parsed.line1, equals('789 Park St'));
      expect(parsed.area, equals('Koramangala'));
      expect(parsed.cityId, equals(1));
      expect(parsed.cityName, equals('Bengaluru'));
      expect(parsed.stateName, equals('Karnataka'));
      expect(parsed.pincode, equals('560034'));
    });
  });

  group('OwnerSettingsScreen Widget Tests', () {
    testWidgets('renders loading state with SkeletonList', (tester) async {
      final mockRepo = MockOwnerRepo();
      await tester.pumpWidget(createTestApp(mockOwnerRepo: mockRepo));

      expect(find.byType(SkeletonList), findsOneWidget);
    });

    testWidgets('renders error state with retry button on failure', (tester) async {
      final mockRepo = MockOwnerRepo()..shouldThrow = true;
      await tester.pumpWidget(createTestApp(mockOwnerRepo: mockRepo));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.textContaining('Something went wrong'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);

      // Verify retry
      mockRepo.shouldThrow = false;
      mockRepo.details = sampleDetails;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Sunrise Living'), findsOneWidget);
    });

    testWidgets('renders all 4 rows in data state with correct labels and values',
        (tester) async {
      final mockRepo = MockOwnerRepo(details: sampleDetails);
      await tester.pumpWidget(createTestApp(mockOwnerRepo: mockRepo));
      await tester.pumpAndSettle();

      // Row 1: PG name
      expect(find.text('PG name'), findsOneWidget);
      expect(find.text('Sunrise Living'), findsOneWidget);

      // Row 2: Who stays here (men)
      expect(find.text('Who stays here'), findsOneWidget);
      expect(find.text('Men'), findsOneWidget);

      // Row 3: Address
      expect(find.text('Address'), findsOneWidget);
      expect(
        find.text('123 MG Road\nIndiranagar\nBengaluru, Karnataka 560038'),
        findsOneWidget,
      );

      // Row 4: Contact number
      expect(find.text('Contact number (optional)'), findsOneWidget);
      expect(find.text('+91 98765 43210'), findsOneWidget);

      // Verify 4 chevrons
      expect(find.byIcon(AppIcons.chevronRight), findsNWidgets(4));
    });

    testWidgets('renders em dash when contact number is null', (tester) async {
      const detailsNoContact = PgDetails(
        id: 'pg-1',
        name: 'Sunrise Living',
        genderPolicy: 'men',
        contactPhone: null,
        addressId: 'addr-1',
        line1: '123 MG Road',
        area: 'Indiranagar',
        cityId: 1,
        cityName: 'Bengaluru',
        stateName: 'Karnataka',
        pincode: '560038',
      );
      final mockRepo = MockOwnerRepo(details: detailsNoContact);
      await tester.pumpWidget(createTestApp(mockOwnerRepo: mockRepo));
      await tester.pumpAndSettle();

      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('edit PG name validates required and saves changes', (tester) async {
      final mockRepo = MockOwnerRepo(details: sampleDetails);
      await tester.pumpWidget(createTestApp(mockOwnerRepo: mockRepo));
      await tester.pumpAndSettle();

      // Tap PG name row
      await tester.tap(find.byType(KeyValueRow).first);
      await tester.pumpAndSettle();

      // Bottom sheet should be open with title "PG name"
      expect(find.widgetWithText(AppButton, 'Save'), findsOneWidget);

      // Clear the text and tap Save to verify validation
      final textField = find.byType(AppTextField);
      await tester.enterText(textField, '   ');
      await tester.tap(find.widgetWithText(AppButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Enter the PG name.'), findsOneWidget);
      expect(mockRepo.updatedName, isNull);

      // Enter valid name and save
      await tester.enterText(textField, 'Golden Horizon PG');
      await tester.tap(find.widgetWithText(AppButton, 'Save'));
      await tester.pumpAndSettle();

      expect(mockRepo.updatedName, equals('Golden Horizon PG'));
      expect(find.text('Saved.'), findsOneWidget);
      expect(find.text('Golden Horizon PG'), findsOneWidget);
    });

    testWidgets('edit Who stays here selects option and saves changes', (tester) async {
      final mockRepo = MockOwnerRepo(details: sampleDetails);
      await tester.pumpWidget(createTestApp(mockOwnerRepo: mockRepo));
      await tester.pumpAndSettle();

      // Tap Who stays here row (second row)
      await tester.tap(find.byType(KeyValueRow).at(1));
      await tester.pumpAndSettle();

      // Options: Men, Women, Anyone
      expect(find.text('Men'), findsWidgets);
      expect(find.text('Women'), findsOneWidget);
      expect(find.text('Anyone'), findsOneWidget);

      // Select Women
      await tester.tap(find.text('Women'));
      await tester.pumpAndSettle();

      // Tap Save
      await tester.tap(find.widgetWithText(AppButton, 'Save'));
      await tester.pumpAndSettle();

      expect(mockRepo.updatedGenderPolicy, equals('women'));
      expect(find.text('Saved.'), findsOneWidget);
      expect(find.text('Women'), findsOneWidget);
    });

    testWidgets('edit Address validates required line1 and saves changes', (tester) async {
      final mockRepo = MockOwnerRepo(details: sampleDetails);
      await tester.pumpWidget(createTestApp(mockOwnerRepo: mockRepo));
      await tester.pumpAndSettle();

      // Tap Address row (third row)
      await tester.tap(find.byType(KeyValueRow).at(2));
      await tester.pumpAndSettle();

      // Clear line1 to test validation
      final addressFields = find.byType(AppTextField);
      await tester.enterText(addressFields.first, '');
      await tester.tap(find.widgetWithText(AppButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Enter the address.'), findsOneWidget);
      expect(mockRepo.updatedAddress, isNull);

      // Enter updated address
      await tester.enterText(addressFields.first, '789 Brigade Road');
      await tester.tap(find.widgetWithText(AppButton, 'Save'));
      await tester.pumpAndSettle();

      expect(mockRepo.updatedAddress, isNotNull);
      expect(mockRepo.updatedAddress!['line1'], equals('789 Brigade Road'));
      expect(find.text('Saved.'), findsOneWidget);
    });

    testWidgets('edit Contact number validates format and saves changes', (tester) async {
      final mockRepo = MockOwnerRepo(details: sampleDetails);
      await tester.pumpWidget(createTestApp(mockOwnerRepo: mockRepo));
      await tester.pumpAndSettle();

      // Tap Contact number row (fourth row)
      await tester.tap(find.byType(KeyValueRow).at(3));
      await tester.pumpAndSettle();

      // Enter invalid mobile number
      final phoneField = find.byType(PhoneField);
      await tester.enterText(phoneField, '12345');
      await tester.tap(find.widgetWithText(AppButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid 10-digit mobile number.'), findsOneWidget);
      expect(mockRepo.updatedContactPhone, isNull);

      // Enter valid mobile number
      await tester.enterText(phoneField, '9123456789');
      await tester.tap(find.widgetWithText(AppButton, 'Save'));
      await tester.pumpAndSettle();

      expect(mockRepo.updatedContactPhone, equals('+919123456789'));
      expect(find.text('Saved.'), findsOneWidget);
      expect(find.text('+91 91234 56789'), findsOneWidget);
    });
  });
}
