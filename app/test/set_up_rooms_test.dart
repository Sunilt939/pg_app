import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/l10n/app_localizations.dart';
import 'package:app/core/router/route_paths.dart';
import 'package:app/core/theme/app_icons.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/app_button.dart';
import 'package:app/core/widgets/app_text_field.dart';
import 'package:app/features/auth/domain/auth_context.dart';
import 'package:app/features/auth/domain/auth_repository.dart';
import 'package:app/features/auth/presentation/providers/auth_provider.dart';
import 'package:app/features/owner/domain/city.dart';
import 'package:app/features/owner/domain/owner_repository.dart';
import 'package:app/features/owner/domain/pg_switcher_item.dart';
import 'package:app/features/owner/domain/room_type.dart';
import 'package:app/features/owner/presentation/providers/owner_provider.dart';
import 'package:app/features/owner/presentation/screens/set_up_rooms_screen.dart';

class MockOwnerRepo implements OwnerRepository {
  List<Map<String, dynamic>>? savedRooms;
  String? savedPgId;
  bool shouldThrowClash = false;

  @override
  Future<List<City>> getCities() async => const [];

  @override
  Future<List<PgSwitcherItem>> getOwnerPgs() async => const [
        PgSwitcherItem(pgId: 'pg-123', name: 'Sunrise PG', role: 'owner'),
      ];

  @override
  Future<List<RoomType>> getRoomTypes() async => const [];

  @override
  Future<int> addRooms({
    required String pgId,
    required int firstRoomNumber,
    required int roomCount,
    required int bedsPerRoom,
    String? roomTypeCode,
    int? floor,
    String? prefix,
  }) async =>
      roomCount;

  @override
  Future<int> addRoomLayout({
    required String pgId,
    required List<Map<String, dynamic>> rooms,
  }) async {
    if (shouldThrowClash) {
      throw Exception('Room 101 already exists in this PG');
    }
    savedPgId = pgId;
    savedRooms = rooms;
    return rooms.length;
  }

  @override
  Future<String> createPg({
    required String name,
    required String line1,
    required int cityId,
    String? pincode,
    String? area,
    String? contactPhone,
    String genderPolicy = 'any',
  }) async =>
      'new-pg';
}

class MockAuthRepo implements AuthRepository {
  @override
  Stream<bool> authStateChanges() => const Stream.empty();

  @override
  bool get isAuthenticated => true;

  @override
  Future<AuthContext> getMyContext() async => const AuthContext(
        person: AuthPerson(id: 'p1', phone: '+919876543210'),
        pgs: [AuthPg(pgId: 'pg-123', name: 'Sunrise PG', role: 'owner')],
      );

  @override
  Future<void> sendOtp(String phone) async {}

  @override
  Future<void> verifyOtp({required String phone, required String token}) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<String?> getSelectedPgId() async => 'pg-123';

  @override
  Future<void> setSelectedPgId(String pgId) async {}

  @override
  Future<String?> getLastView() async => 'owner';

  @override
  Future<void> setLastView(String view) async {}
}

Widget _wrapScreen({required MockOwnerRepo repo}) {
  final router = GoRouter(
    initialLocation: RoutePaths.ownerRoomsSetup,
    routes: [
      GoRoute(
        path: RoutePaths.ownerRoomsSetup,
        builder: (context, state) => const SetUpRoomsScreen(),
      ),
      GoRoute(
        path: RoutePaths.ownerMore,
        builder: (context, state) => const Scaffold(body: Text('More Screen')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      ownerRepositoryProvider.overrideWithValue(repo),
      authRepositoryProvider.overrideWithValue(MockAuthRepo()),
      activePgProvider.overrideWithValue(
        const AuthPg(pgId: 'pg-123', name: 'Sunrise PG', role: 'owner'),
      ),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  Finder inputByKey(String key) =>
      find.descendant(of: find.byKey(Key(key)), matching: find.byType(TextField));

  testWidgets('Full 4-step wizard walkthrough and save rooms', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    addTearDown(tester.view.resetPhysicalSize);

    final repo = MockOwnerRepo();
    await tester.pumpWidget(_wrapScreen(repo: repo));
    await tester.pumpAndSettle();

    // ----------------- Step 1 -----------------
    expect(find.text('Step 1 of 4'), findsOneWidget);
    expect(find.text('Start with one floor'), findsOneWidget);

    // Initial state: floor number is 1, rooms is empty
    expect(find.text('1'), findsWidgets);
    expect(find.textContaining('Rooms 101'), findsNothing);

    // Enter rooms count: 3
    await tester.enterText(inputByKey('layout_room_count_field'), '3');
    await tester.pumpAndSettle();

    // Live preview should show Rooms 101 to 103.
    expect(find.text('Rooms 101 to 103.'), findsOneWidget);

    // Tap Next
    await tester.tap(find.widgetWithText(AppButton, 'Next'));
    await tester.pumpAndSettle();

    // ----------------- Step 2 -----------------
    expect(find.text('Step 2 of 4'), findsOneWidget);
    expect(find.text('Beds in each room'), findsOneWidget);
    expect(find.text('All rooms'), findsOneWidget);
    expect(find.text('Room 101'), findsOneWidget);
    expect(find.text('Room 102'), findsOneWidget);
    expect(find.text('Room 103'), findsOneWidget);

    // Change bed count for Room 102 to 3
    final room2StepperPlus = find.descendant(
      of: find.byKey(const Key('room_stepper_2')),
      matching: find.byIcon(AppIcons.add),
    );
    await tester.tap(room2StepperPlus);
    await tester.pumpAndSettle();

    // Floor totals: 3 rooms, 7 beds on this floor.
    expect(find.text('3 rooms, 7 beds on this floor.'), findsOneWidget);

    // Tap Next to go to Step 3
    await tester.tap(find.widgetWithText(AppButton, 'Next'));
    await tester.pumpAndSettle();

    // ----------------- Step 3 -----------------
    expect(find.text('Step 3 of 4'), findsOneWidget);
    expect(find.text('How many floors does your PG have?'), findsOneWidget);

    // Default floor count is 1
    expect(find.text('1 floor, 3 rooms, 7 beds'), findsOneWidget);

    // Change floor count to 2
    await tester.enterText(inputByKey('layout_floor_count_field'), '2');
    await tester.pumpAndSettle();

    expect(find.text('2 floors, 6 rooms, 14 beds'), findsOneWidget);

    // Tap Next to build layout and move to Step 4
    await tester.tap(find.widgetWithText(AppButton, 'Next'));
    await tester.pumpAndSettle();

    // ----------------- Step 4 -----------------
    expect(find.text('Step 4 of 4'), findsOneWidget);
    expect(find.text('Check your rooms'), findsOneWidget);
    expect(find.text('Floor 1'), findsOneWidget);
    expect(find.text('Floor 2'), findsOneWidget);

    // Verify rooms on floor 1 & 2
    expect(find.text('101'), findsOneWidget);
    expect(find.text('102'), findsOneWidget);
    expect(find.text('103'), findsOneWidget);
    expect(find.text('201'), findsOneWidget);
    expect(find.text('202'), findsOneWidget);
    expect(find.text('203'), findsOneWidget);

    // Tap Save rooms
    await tester.tap(find.widgetWithText(AppButton, 'Save rooms'));
    await tester.pumpAndSettle();

    // Repository called with 6 rooms
    expect(repo.savedPgId, 'pg-123');
    expect(repo.savedRooms?.length, 6);
    expect(repo.savedRooms?[0], {'number': '101', 'floor': 1, 'beds': 2});
    expect(repo.savedRooms?[1], {'number': '102', 'floor': 1, 'beds': 3});
    expect(repo.savedRooms?[3], {'number': '201', 'floor': 2, 'beds': 2});
    expect(repo.savedRooms?[4], {'number': '202', 'floor': 2, 'beds': 3});

    // Success snackbar
    expect(find.text('6 rooms added.'), findsOneWidget);
  });

  testWidgets('Step 4 edit room, duplicate validation, and remove room', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    addTearDown(tester.view.resetPhysicalSize);

    final repo = MockOwnerRepo();
    await tester.pumpWidget(_wrapScreen(repo: repo));
    await tester.pumpAndSettle();

    // Step 1: 1 room on Floor 1
    await tester.enterText(inputByKey('layout_room_count_field'), '2');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, 'Next'));
    await tester.pumpAndSettle();

    // Step 2: Next
    await tester.tap(find.widgetWithText(AppButton, 'Next'));
    await tester.pumpAndSettle();

    // Step 3: Next
    await tester.tap(find.widgetWithText(AppButton, 'Next'));
    await tester.pumpAndSettle();

    // Step 4: Tap Room 101 to edit
    await tester.tap(find.text('101'));
    await tester.pumpAndSettle();

    expect(find.text('Change room'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Remove room'), findsOneWidget);

    // Change number to 102 (duplicate)
    final editInput = find.descendant(of: find.byType(AppTextField), matching: find.byType(TextField));
    await tester.enterText(editInput, '102');
    await tester.tap(find.widgetWithText(AppButton, 'Done'));
    await tester.pumpAndSettle();

    expect(find.text('This room number is already in the list.'), findsOneWidget);

    // Change to 105 and Done
    await tester.enterText(editInput, '105');
    await tester.tap(find.widgetWithText(AppButton, 'Done'));
    await tester.pumpAndSettle();

    expect(find.text('105'), findsOneWidget);

    // Tap 102 and remove it
    await tester.tap(find.text('102'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(AppButton, 'Remove room'));
    await tester.pumpAndSettle();

    expect(find.text('102'), findsNothing);
  });

  testWidgets('Step 4 database clash displays error at top', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    addTearDown(tester.view.resetPhysicalSize);

    final repo = MockOwnerRepo();
    repo.shouldThrowClash = true;

    await tester.pumpWidget(_wrapScreen(repo: repo));
    await tester.pumpAndSettle();

    await tester.enterText(inputByKey('layout_room_count_field'), '1');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, 'Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, 'Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, 'Next'));
    await tester.pumpAndSettle();

    // Step 4 Save
    await tester.tap(find.widgetWithText(AppButton, 'Save rooms'));
    await tester.pumpAndSettle();

    expect(find.text('Room 101 already exists in this PG'), findsOneWidget);
  });

  testWidgets('Back button shows ConfirmSheet on step 1 when dirty', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    addTearDown(tester.view.resetPhysicalSize);

    final repo = MockOwnerRepo();
    await tester.pumpWidget(_wrapScreen(repo: repo));
    await tester.pumpAndSettle();

    // Type something in step 1
    await tester.enterText(inputByKey('layout_room_count_field'), '5');
    await tester.pumpAndSettle();

    // Tap top bar back
    await tester.tap(find.byIcon(AppIcons.back));
    await tester.pumpAndSettle();

    expect(find.text('Leave without saving?'), findsOneWidget);
    expect(find.text('The rooms you entered will not be saved.'), findsOneWidget);

    // Tap Cancel
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Leave without saving?'), findsNothing);
  });
}

