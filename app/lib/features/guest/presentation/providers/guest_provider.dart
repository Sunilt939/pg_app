import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../owner/domain/guest_list_item.dart';
import '../../../owner/domain/payment_account.dart';
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

final guestStayProvider =
    FutureProvider.autoDispose.family<GuestListItem?, String>((ref, stayId) async {
  final repo = ref.watch(guestRepositoryProvider);
  return repo.getStay(stayId);
});

final guestUpiAccountsProvider =
    FutureProvider.autoDispose.family<List<PaymentAccount>, String>((ref, pgId) async {
  final repo = ref.watch(guestRepositoryProvider);
  return repo.getActiveUpiAccounts(pgId);
});

