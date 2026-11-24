import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/supabase_owner_repository.dart';
import '../../domain/bed_occupancy.dart';
import '../../domain/city.dart';
import '../../domain/owner_repository.dart';
import '../../domain/payment_account.dart';
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

final bedOccupancyProvider = FutureProvider.autoDispose<List<BedOccupancy>>((ref) async {
  final activePg = ref.watch(activePgProvider);
  if (activePg == null) return [];
  final repo = ref.watch(ownerRepositoryProvider);
  return repo.getBedOccupancy(activePg.pgId);
});

final paymentAccountsProvider =
    FutureProvider.autoDispose<List<PaymentAccount>>((ref) async {
  final activePg = ref.watch(activePgProvider);
  if (activePg == null) return [];
  final repo = ref.watch(ownerRepositoryProvider);
  return repo.getPaymentAccounts(activePg.pgId);
});

final paymentAccountDetailProvider =
    FutureProvider.autoDispose.family<PaymentAccount?, String>((ref, id) async {
  final repo = ref.watch(ownerRepositoryProvider);
  return repo.getPaymentAccount(id);
});

final pgOverviewProvider = FutureProvider.autoDispose<PgOverview?>((ref) async {
  final activePg = ref.watch(activePgProvider);
  if (activePg == null) return null;
  final repo = ref.watch(ownerRepositoryProvider);
  return repo.getPgOverview(activePg.pgId);
});

final pgPaymentsProvider =
    FutureProvider.autoDispose<List<PaymentFeedItem>>((ref) async {
  final activePg = ref.watch(activePgProvider);
  if (activePg == null) return [];
  final repo = ref.watch(ownerRepositoryProvider);
  return repo.getPgPayments(activePg.pgId);
});

final monthCollectionsProvider =
    FutureProvider.autoDispose.family<MonthCollections, String>((ref, month) async {
  final activePg = ref.watch(activePgProvider);
  if (activePg == null) return MonthCollections.empty('', month);
  final repo = ref.watch(ownerRepositoryProvider);
  return repo.getMonthCollections(pgId: activePg.pgId, month: month);
});

final ownerHomeBundleProvider =
    FutureProvider.autoDispose.family<OwnerHomeBundle?, String>((ref, month) async {
  final activePg = ref.watch(activePgProvider);
  if (activePg == null) return null;
  final repo = ref.watch(ownerRepositoryProvider);
  return repo.getOwnerHomeBundle(pgId: activePg.pgId, month: month);
});

class GuestListNotifier extends AutoDisposeAsyncNotifier<List<GuestListItem>> {
  int _offset = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  static const int _pageSize = 50;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  @override
  Future<List<GuestListItem>> build() async {
    _offset = 0;
    _hasMore = true;
    _isLoadingMore = false;
    final activePg = ref.watch(activePgProvider);
    if (activePg == null) return [];
    final repo = ref.watch(ownerRepositoryProvider);
    final guests = await repo.getGuests(
      pgId: activePg.pgId,
      limit: _pageSize,
      offset: 0,
    );
    _offset = guests.length;
    _hasMore = guests.length >= _pageSize;
    return guests;
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore || state.isLoading || state.hasError) return;
    final activePg = ref.read(activePgProvider);
    if (activePg == null) return;
    _isLoadingMore = true;
    try {
      final repo = ref.read(ownerRepositoryProvider);
      final nextGuests = await repo.getGuests(
        pgId: activePg.pgId,
        limit: _pageSize,
        offset: _offset,
      );
      _offset += nextGuests.length;
      _hasMore = nextGuests.length >= _pageSize;
      final current = state.value ?? [];
      state = AsyncData([...current, ...nextGuests]);
    } catch (_) {
      // Don't overwrite existing list on load more failure
    } finally {
      _isLoadingMore = false;
    }
  }
}

final guestListProvider =
    AutoDisposeAsyncNotifierProvider<GuestListNotifier, List<GuestListItem>>(
  GuestListNotifier.new,
);

final guestDetailBundleProvider =
    FutureProvider.autoDispose.family<GuestDetailBundle?, String>((ref, stayId) async {
  final repo = ref.watch(ownerRepositoryProvider);
  return repo.getGuestDetailBundle(stayId);
});

final chargeTypesProvider =
    FutureProvider.autoDispose<List<ChargeType>>((ref) async {
  final repo = ref.watch(ownerRepositoryProvider);
  return repo.getChargeTypes();
});

final paymentMethodsProvider =
    FutureProvider.autoDispose<List<PaymentMethod>>((ref) async {
  final repo = ref.watch(ownerRepositoryProvider);
  return repo.getPaymentMethods();
});

final upiAppsProvider =
    FutureProvider.autoDispose<List<UpiApp>>((ref) async {
  final repo = ref.watch(ownerRepositoryProvider);
  return repo.getUpiApps();
});

final paymentDetailProvider =
    FutureProvider.autoDispose.family<PaymentFeedItem?, String>((ref, paymentId) async {
  final repo = ref.watch(ownerRepositoryProvider);
  return repo.getPaymentDetail(paymentId);
});

final signedFileUrlProvider =
    FutureProvider.autoDispose.family<String?, String>((ref, fileId) async {
  final repo = ref.watch(ownerRepositoryProvider);
  return repo.getSignedFileUrl(fileId);
});

final reminderRulesProvider =
    FutureProvider.autoDispose<List<ReminderRule>>((ref) async {
  final activePg = ref.watch(activePgProvider);
  if (activePg == null) return [];
  final repo = ref.watch(ownerRepositoryProvider);
  return repo.getReminderRules(activePg.pgId);
});





