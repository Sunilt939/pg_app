import 'bed_occupancy.dart';
import 'city.dart';
import 'payment_account.dart';
import 'pg_switcher_item.dart';
import 'room_type.dart';

class DuplicateNicknameException implements Exception {
  final String message;
  const DuplicateNicknameException([this.message = 'Duplicate nickname']);

  @override
  String toString() => message;
}

abstract class OwnerRepository {
  Future<List<City>> getCities();
  Future<List<PgSwitcherItem>> getOwnerPgs();
  Future<List<RoomType>> getRoomTypes();
  Future<List<BedOccupancy>> getBedOccupancy(String pgId);
  Future<List<PaymentAccount>> getPaymentAccounts(String pgId);
  Future<PaymentAccount?> getPaymentAccount(String id);
  Future<PaymentAccount> createPaymentAccount(PaymentAccount account);
  Future<PaymentAccount> updatePaymentAccount(PaymentAccount account);
  Future<int> addRooms({
    required String pgId,
    required int firstRoomNumber,
    required int roomCount,
    required int bedsPerRoom,
    String? roomTypeCode,
    int? floor,
    String? prefix,
  });
  Future<int> addRoomLayout({
    required String pgId,
    required List<Map<String, dynamic>> rooms,
  });
  Future<String> createPg({
    required String name,
    required String line1,
    required int cityId,
    String? pincode,
    String? area,
    String? contactPhone,
    String genderPolicy = 'any',
  });
}

