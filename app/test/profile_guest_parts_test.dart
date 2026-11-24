import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/l10n/app_localizations.dart';
import 'package:app/core/widgets/select_field.dart';
import 'package:app/features/auth/domain/auth_context.dart';
import 'package:app/features/auth/domain/auth_repository.dart';
import 'package:app/features/auth/presentation/providers/auth_provider.dart';
import 'package:app/features/owner/domain/guest_list_item.dart';
import 'package:app/features/shared/domain/emergency_contact.dart';
import 'package:app/features/shared/domain/profile_repository.dart';
import 'package:app/features/shared/presentation/providers/profile_provider.dart';
import 'package:app/features/shared/presentation/screens/profile_screen.dart';

class MockProfileGuestRepo implements ProfileRepository {
  List<EmergencyContact> emergencyContacts;
  List<RelationshipType> relationshipTypes;
  GuestListItem? guestOpenStay;

  MockProfileGuestRepo({
    List<EmergencyContact>? emergencyContacts,
    List<RelationshipType>? relationshipTypes,
    this.guestOpenStay,
  })  : emergencyContacts = emergencyContacts ?? [],
        relationshipTypes = relationshipTypes ??
            [
              const RelationshipType(id: 1, code: 'father', label: 'Father'),
              const RelationshipType(id: 2, code: 'mother', label: 'Mother'),
              const RelationshipType(id: 3, code: 'friend', label: 'Friend'),
            ];

  @override
  Future<void> updateName(String fullName) async {}

  @override
  Future<void> updateEmail(String? email) async {}

  @override
  Future<String?> getProfilePhotoPath() async => null;

  @override
  Future<String?> getPresetAvatarId() async => null;

  @override
  Future<void> updateProfilePhoto(String filePath) async {}

  @override
  Future<void> updatePresetAvatar(String presetId) async {}

  @override
  Future<void> removeProfilePhoto() async {}

  @override
  Future<List<EmergencyContact>> getEmergencyContacts() async =>
      emergencyContacts;

  @override
  Future<List<RelationshipType>> getRelationshipTypes() async =>
      relationshipTypes;

  @override
  Future<void> addEmergencyContact({
    required String name,
    required String phone,
    int? relationshipTypeId,
    bool isPrimary = false,
  }) async {
    final relLabel = relationshipTypes
        .where((r) => r.id == relationshipTypeId)
        .firstOrNull
        ?.label;

    emergencyContacts.add(EmergencyContact(
      id: 'ec-${emergencyContacts.length + 1}',
      personId: 'person-1',
      name: name,
      phone: phone,
      relationshipTypeId: relationshipTypeId,
      relationshipLabel: relLabel,
      isPrimary: isPrimary,
    ));
  }

  @override
  Future<void> updateEmergencyContact({
    required String id,
    required String name,
    required String phone,
    int? relationshipTypeId,
    bool isPrimary = false,
  }) async {
    final idx = emergencyContacts.indexWhere((c) => c.id == id);
    if (idx != -1) {
      final relLabel = relationshipTypes
          .where((r) => r.id == relationshipTypeId)
          .firstOrNull
          ?.label;

      emergencyContacts[idx] = EmergencyContact(
        id: id,
        personId: emergencyContacts[idx].personId,
        name: name,
        phone: phone,
        relationshipTypeId: relationshipTypeId,
        relationshipLabel: relLabel,
        isPrimary: isPrimary,
      );
    }
  }

  @override
  Future<void> deleteEmergencyContact(String id) async {
    emergencyContacts.removeWhere((c) => c.id == id);
  }

  @override
  Future<GuestListItem?> getGuestOpenStay() async => guestOpenStay;
}

class MockAuthRepoForProfile implements AuthRepository {
  AuthContext authContext;
  String? lastViewSet;
  bool signOutCalled = false;

  MockAuthRepoForProfile({required this.authContext});

  @override
  Stream<bool> authStateChanges() => const Stream.empty();

  @override
  bool get isAuthenticated => authContext.isSignedIn;

  @override
  Future<AuthContext> getMyContext() async => authContext;

  @override
  Future<void> sendOtp(String phone) async {}

  @override
  Future<void> verifyOtp({
    required String phone,
    required String token,
  }) async {}

  @override
  Future<void> signOut() async {
    signOutCalled = true;
  }

  @override
  Future<String?> getSelectedPgId() async => 'pg-1';

  @override
  Future<void> setSelectedPgId(String pgId) async {}

  @override
  Future<String?> getLastView() async => null;

  @override
  Future<void> setLastView(String view) async {
    lastViewSet = view;
  }
}

Widget _wrapProfileScreen({
  required MockProfileGuestRepo profileRepo,
  required MockAuthRepoForProfile authRepo,
  String initialLocation = '/guest/profile',
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/guest/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/owner/home',
        builder: (context, state) =>
            const Scaffold(body: Text('Owner home page')),
      ),
      GoRoute(
        path: '/guest/home',
        builder: (context, state) =>
            const Scaffold(body: Text('Guest home page')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      profileRepositoryProvider.overrideWithValue(profileRepo),
      authRepositoryProvider.overrideWithValue(authRepo),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const guestAuthContext = AuthContext(
    person: AuthPerson(
      id: 'person-1',
      phone: '+919876543210',
      fullName: 'Aarav Sharma',
      email: 'aarav@example.com',
    ),
    pgs: [],
    stays: [
      AuthStay(
        stayId: 'stay-1',
        pgId: 'pg-1',
        pgName: 'Serene PG',
        status: 'active',
      ),
    ],
  );

  const sampleOpenStay = GuestListItem(
    stayId: 'stay-1',
    pgId: 'pg-1',
    pgName: 'Serene PG',
    personId: 'person-1',
    phone: '+919876543210',
    stayStatus: 'active',
    attentionState: 'paid',
    monthlyRentPaise: 650000,
    billingDay: 12,
    joinDate: '2026-06-03',
    roomNumber: '101',
    bedLabel: 'A',
  );

  group('ProfileScreen - S2b Guest Parts', () {
    testWidgets('Guest sees emergency contacts, add contact, and your stay',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final profileRepo = MockProfileGuestRepo(
        emergencyContacts: [
          const EmergencyContact(
            id: 'c1',
            personId: 'person-1',
            name: 'Sunita Sharma',
            phone: '+919876543211',
            relationshipTypeId: 2,
            relationshipLabel: 'Mother',
            isPrimary: true,
          ),
        ],
        guestOpenStay: sampleOpenStay,
      );
      final authRepo =
          MockAuthRepoForProfile(authContext: guestAuthContext);

      await tester.pumpWidget(_wrapProfileScreen(
        profileRepo: profileRepo,
        authRepo: authRepo,
      ));
      await tester.pumpAndSettle();

      // Emergency contacts section
      expect(find.text('Emergency contacts'), findsOneWidget);
      expect(find.text('Sunita Sharma'), findsOneWidget);
      expect(find.text('Mother, +91 98765 43211'), findsOneWidget);
      expect(find.text('Add a contact'), findsOneWidget);

      // Your stay section
      expect(find.text('Your stay'), findsOneWidget);
      expect(find.text('Room 101, bed A'), findsOneWidget);
      expect(find.text('₹6,500'), findsOneWidget);
      expect(find.text('Day 12 of every month'), findsOneWidget);
      expect(find.text('3 Jun 2026'), findsOneWidget);
      expect(find.text('Set by your PG owner.'), findsOneWidget);

      // Not an owner, so no switch view button
      expect(find.text('Switch to owner view'), findsNothing);
      expect(find.text('Switch to guest view'), findsNothing);
    });

    testWidgets('Add emergency contact validates and submits', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final profileRepo = MockProfileGuestRepo();
      final authRepo =
          MockAuthRepoForProfile(authContext: guestAuthContext);

      await tester.pumpWidget(_wrapProfileScreen(
        profileRepo: profileRepo,
        authRepo: authRepo,
      ));
      await tester.pumpAndSettle();

      // Tap Add a contact
      await tester.tap(find.text('Add a contact'));
      await tester.pumpAndSettle();

      // Bottom sheet opens
      expect(find.text('Save'), findsOneWidget);

      // Tap save without input -> validation errors
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Enter your name.'), findsOneWidget);
      expect(
          find.text('Enter a valid 10-digit mobile number.'), findsOneWidget);

      // Enter name
      await tester.enterText(
          find.widgetWithText(TextField, '').first, 'Ramesh Sharma');

      // Enter phone
      await tester.enterText(
          find.widgetWithText(TextField, '').last, '9876543212');

      // Select relationship
      await tester.tap(find.byType(SelectField));
      await tester.pumpAndSettle();

      // Pick Father
      await tester.tap(find.text('Father'));
      await tester.pumpAndSettle();

      // Toggle primary contact
      await tester.tap(find.text('Primary contact'));
      await tester.pumpAndSettle();

      // Tap save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Contact should now appear in the list
      expect(find.text('Ramesh Sharma'), findsOneWidget);
      expect(find.text('Father, +91 98765 43212'), findsOneWidget);
    });

    testWidgets('Edit and remove emergency contact', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final profileRepo = MockProfileGuestRepo(
        emergencyContacts: [
          const EmergencyContact(
            id: 'c1',
            personId: 'person-1',
            name: 'Sunita Sharma',
            phone: '+919876543211',
            relationshipTypeId: 2,
            relationshipLabel: 'Mother',
            isPrimary: true,
          ),
        ],
      );
      final authRepo =
          MockAuthRepoForProfile(authContext: guestAuthContext);

      await tester.pumpWidget(_wrapProfileScreen(
        profileRepo: profileRepo,
        authRepo: authRepo,
      ));
      await tester.pumpAndSettle();

      // Tap Sunita Sharma row to open edit sheet
      await tester.tap(find.text('Sunita Sharma'));
      await tester.pumpAndSettle();

      // Remove button should be visible in edit mode
      expect(find.text('Remove contact'), findsOneWidget);

      // Tap Remove contact
      await tester.tap(find.text('Remove contact'));
      await tester.pumpAndSettle();

      // Sunita Sharma should be removed
      expect(find.text('Sunita Sharma'), findsNothing);
    });

    testWidgets('Owner without stay does NOT see emergency contacts or your stay',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const ownerAuthContext = AuthContext(
        person: AuthPerson(
          id: 'person-1',
          phone: '+919876543210',
          fullName: 'Owner Ji',
        ),
        pgs: [
          AuthPg(pgId: 'pg-1', name: 'Grand PG', role: 'owner'),
        ],
        stays: [],
      );

      final profileRepo = MockProfileGuestRepo();
      final authRepo =
          MockAuthRepoForProfile(authContext: ownerAuthContext);

      await tester.pumpWidget(_wrapProfileScreen(
        profileRepo: profileRepo,
        authRepo: authRepo,
        initialLocation: '/profile',
      ));
      await tester.pumpAndSettle();

      // Should not see emergency contacts or your stay
      expect(find.text('Emergency contacts'), findsNothing);
      expect(find.text('Your stay'), findsNothing);
      expect(find.text('Switch to guest view'), findsNothing);
    });

    testWidgets(
        'Dual-role person sees switch to owner view in guest shell and navigates',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const dualRoleContext = AuthContext(
        person: AuthPerson(
          id: 'person-1',
          phone: '+919876543210',
          fullName: 'Dual User',
        ),
        pgs: [
          AuthPg(pgId: 'pg-1', name: 'Grand PG', role: 'owner'),
        ],
        stays: [
          AuthStay(
            stayId: 'stay-1',
            pgId: 'pg-2',
            pgName: 'Other PG',
            status: 'active',
          ),
        ],
      );

      final profileRepo = MockProfileGuestRepo();
      final authRepo =
          MockAuthRepoForProfile(authContext: dualRoleContext);

      await tester.pumpWidget(_wrapProfileScreen(
        profileRepo: profileRepo,
        authRepo: authRepo,
        initialLocation: '/guest/profile',
      ));
      await tester.pumpAndSettle();

      // In guest profile, button says Switch to owner view
      expect(find.text('Switch to owner view'), findsOneWidget);

      await tester.tap(find.text('Switch to owner view'));
      await tester.pumpAndSettle();

      // Stores owner view and navigates
      expect(authRepo.lastViewSet, equals('owner'));
      expect(find.text('Owner home page'), findsOneWidget);
    });

    testWidgets('Dual-role person sees switch to guest view in owner profile',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const dualRoleContext = AuthContext(
        person: AuthPerson(
          id: 'person-1',
          phone: '+919876543210',
          fullName: 'Dual User',
        ),
        pgs: [
          AuthPg(pgId: 'pg-1', name: 'Grand PG', role: 'owner'),
        ],
        stays: [
          AuthStay(
            stayId: 'stay-1',
            pgId: 'pg-2',
            pgName: 'Other PG',
            status: 'active',
          ),
        ],
      );

      final profileRepo = MockProfileGuestRepo();
      final authRepo =
          MockAuthRepoForProfile(authContext: dualRoleContext);

      await tester.pumpWidget(_wrapProfileScreen(
        profileRepo: profileRepo,
        authRepo: authRepo,
        initialLocation: '/profile',
      ));
      await tester.pumpAndSettle();

      // In owner profile, button says Switch to guest view
      expect(find.text('Switch to guest view'), findsOneWidget);

      await tester.tap(find.text('Switch to guest view'));
      await tester.pumpAndSettle();

      // Stores guest view and navigates
      expect(authRepo.lastViewSet, equals('guest'));
      expect(find.text('Guest home page'), findsOneWidget);
    });

    testWidgets('Your stay hides Room row when roomNumber is null',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const stayWithoutRoom = GuestListItem(
        stayId: 'stay-1',
        pgId: 'pg-1',
        pgName: 'Serene PG',
        personId: 'person-1',
        phone: '+919876543210',
        stayStatus: 'active',
        attentionState: 'paid',
        monthlyRentPaise: 650000,
        billingDay: 12,
        joinDate: '2026-06-03',
        roomNumber: null,
        bedLabel: null,
      );

      final profileRepo = MockProfileGuestRepo(
        guestOpenStay: stayWithoutRoom,
      );
      final authRepo =
          MockAuthRepoForProfile(authContext: guestAuthContext);

      await tester.pumpWidget(_wrapProfileScreen(
        profileRepo: profileRepo,
        authRepo: authRepo,
      ));
      await tester.pumpAndSettle();

      // Room row should not be shown
      expect(find.text('Room'), findsNothing);
      // Other stay rows are shown
      expect(find.text('Monthly rent'), findsOneWidget);
      expect(find.text('Rent due on'), findsOneWidget);
      expect(find.text('Joined'), findsOneWidget);
    });
  });
}
