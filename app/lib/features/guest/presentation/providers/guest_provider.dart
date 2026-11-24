import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../owner/domain/guest_list_item.dart';
import '../../../owner/domain/payment_account.dart';
import '../../../owner/domain/payment_method.dart';
import '../../../owner/domain/upi_app.dart';
import '../../data/supabase_guest_repository.dart';
import '../../domain/guest_home_bundle.dart';
import '../../domain/guest_repository.dart';
import '../../domain/guest_stay_bundle.dart';

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

final guestStayDetailsProvider =
    FutureProvider.autoDispose.family<GuestStayBundle, String>((ref, stayId) async {
  final repo = ref.watch(guestRepositoryProvider);
  return repo.getStayDetails(stayId);
});

final guestUpiAccountsProvider =
    FutureProvider.autoDispose.family<List<PaymentAccount>, String>((ref, pgId) async {
  final repo = ref.watch(guestRepositoryProvider);
  return repo.getActiveUpiAccounts(pgId);
});

final guestBankAccountsProvider =
    FutureProvider.autoDispose.family<List<PaymentAccount>, String>((ref, pgId) async {
  final repo = ref.watch(guestRepositoryProvider);
  return repo.getActiveBankAccounts(pgId);
});

final guestPaymentMethodsProvider =
    FutureProvider.autoDispose<List<PaymentMethod>>((ref) async {
  final repo = ref.watch(guestRepositoryProvider);
  return repo.getPaymentMethods();
});

final guestUpiAppsProvider =
    FutureProvider.autoDispose<List<UpiApp>>((ref) async {
  final repo = ref.watch(guestRepositoryProvider);
  return repo.getUpiApps();
});


