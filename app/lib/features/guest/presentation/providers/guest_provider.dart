import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/supabase_guest_repository.dart';
import '../../domain/guest_home_bundle.dart';
import '../../domain/guest_repository.dart';

final guestRepositoryProvider = Provider<GuestRepository>((ref) {
  return SupabaseGuestRepository();
});

final guestHomeBundleProvider =
    FutureProvider.autoDispose<GuestHomeBundle>((ref) async {
  final repo = ref.watch(guestRepositoryProvider);
  return repo.getGuestHomeData();
});

