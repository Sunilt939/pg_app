import 'city.dart';
import 'pg_switcher_item.dart';
import 'room_type.dart';

abstract class OwnerRepository {
  Future<List<City>> getCities();
  Future<List<PgSwitcherItem>> getOwnerPgs();
  Future<List<RoomType>> getRoomTypes();
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

