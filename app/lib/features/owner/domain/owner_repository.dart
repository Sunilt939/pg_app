import 'bed_occupancy.dart';
import 'charge_type.dart';
import 'city.dart';
import 'guest_detail_bundle.dart';
import 'guest_list_item.dart';
import 'payment_account.dart';
import 'pg_overview.dart';
import 'pg_switcher_item.dart';
import 'room_type.dart';

export 'charge_balance.dart';
export 'charge_type.dart';
export 'emergency_contact.dart';
export 'guest_detail_bundle.dart';
export 'guest_list_item.dart';
export 'payment_feed_item.dart';
export 'pg_overview.dart';

class DuplicateNicknameException implements Exception {
  final String message;
  const DuplicateNicknameException([this.message = 'Duplicate nickname']);

  @override
  String toString() => message;
}

class DuplicateGuestStayException implements Exception {
  final String message;
  const DuplicateGuestStayException([this.message = 'This guest is already staying in this PG.']);

  @override
  String toString() => message;
}

class BedAlreadyTakenException implements Exception {
  final String message;
  const BedAlreadyTakenException([this.message = 'That bed was just taken. Choose another.']);

  @override
  String toString() => message;
}

class DuplicateRentDateException implements Exception {
  final String message;
  const DuplicateRentDateException([this.message = 'A rent change already exists from that date. Pick another date.']);

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
  Future<String> createStay({
    required String pgId,
    required String phone,
    required String fullName,
    String? bedId,
    required DateTime joinDate,
    required int monthlyRentPaise,
    int depositPaise = 0,
    int? billingDay,
    DateTime? billingStartsOn,
    bool depositAlreadyPaid = false,
  });
  Future<List<GuestListItem>> getGuests({
    required String pgId,
    int limit = 50,
    int offset = 0,
  });
  Future<PgOverview?> getPgOverview(String pgId);
  Future<GuestDetailBundle?> getGuestDetailBundle(String stayId);
  Future<List<ChargeType>> getChargeTypes();
  Future<void> setStayRent({
    required String stayId,
    required int monthlyRentPaise,
    required DateTime effectiveFrom,
  });
  Future<void> addCharge({
    required String stayId,
    required String chargeTypeCode,
    required int amountPaise,
    required DateTime dueDate,
    String? description,
    DateTime? periodMonth,
  });
}

