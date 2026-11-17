import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/supabase_owner_repository.dart';
import '../../domain/city.dart';
import '../../domain/owner_repository.dart';

final ownerRepositoryProvider = Provider<OwnerRepository>((ref) {
  return SupabaseOwnerRepository();
});

final citiesProvider = FutureProvider<List<City>>((ref) async {
  final repo = ref.watch(ownerRepositoryProvider);
  return repo.getCities();
});

