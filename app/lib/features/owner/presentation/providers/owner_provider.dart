import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/supabase_owner_repository.dart';
import '../../domain/city.dart';
import '../../domain/owner_repository.dart';
import '../../domain/pg_switcher_item.dart';
import '../../domain/room_type.dart';

final ownerRepositoryProvider = Provider<OwnerRepository>((ref) {
  return SupabaseOwnerRepository();
});

final roomTypesProvider = FutureProvider<List<RoomType>>((ref) async {
  final repo = ref.watch(ownerRepositoryProvider);
  return repo.getRoomTypes();
});

final citiesProvider = FutureProvider<List<City>>((ref) async {
  final repo = ref.watch(ownerRepositoryProvider);
  return repo.getCities();
});

final ownerPgsProvider = FutureProvider<List<PgSwitcherItem>>((ref) async {
  final repo = ref.watch(ownerRepositoryProvider);
  final items = await repo.getOwnerPgs();
  if (items.isNotEmpty) return items;

  // Fallback to authContext if address query was empty or offline
  final authContext = ref.watch(authContextProvider).valueOrNull;
  final pgs = authContext?.pgs ?? [];
  return pgs
      .map(
        (p) => PgSwitcherItem(
          pgId: p.pgId,
          name: p.name,
          role: p.role,
        ),
      )
      .toList();
});

