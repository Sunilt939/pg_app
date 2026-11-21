import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/domain/auth_repository.dart';
import '../domain/bed_occupancy.dart';
import '../domain/city.dart';
import '../domain/owner_repository.dart';
import '../domain/pg_switcher_item.dart';
import '../domain/room_type.dart';

class SupabaseOwnerRepository implements OwnerRepository {
  final SupabaseClient? _client;

  SupabaseOwnerRepository([SupabaseClient? client])
      : _client = client ??
            (Supabase.instance.isInitialized ? Supabase.instance.client : null);

  @override
  Future<List<City>> getCities() async {
    final client = _client;
    if (client == null) return [];
    try {
      final response = await client
          .from('cities')
          .select('id, name, states(name)')
          .order('name');
      return (response as List<dynamic>)
          .map((json) => City.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<PgSwitcherItem>> getOwnerPgs() async {
    final client = _client;
    if (client == null) return [];

    try {
      final contextResp = await client.rpc('rpc_my_context');
      final pgsList = (contextResp?['pgs'] as List<dynamic>?) ?? [];
      if (pgsList.isEmpty) return [];

      final pgIds = pgsList
          .map((p) => (p as Map<String, dynamic>)['pg_id'] as String)
          .toList();

      final pgsDetailsResp = await client
          .from('pgs')
          .select('id, name, addresses(area, cities(name))')
          .inFilter('id', pgIds);

      final detailsMap = <String, Map<String, dynamic>>{};
      for (final item in (pgsDetailsResp as List<dynamic>)) {
        final map = item as Map<String, dynamic>;
        detailsMap[map['id'] as String] = map;
      }

      final items = <PgSwitcherItem>[];
      for (final p in pgsList) {
        final pgMap = p as Map<String, dynamic>;
        final id = pgMap['pg_id'] as String;
        final name = pgMap['name'] as String;
        final role = pgMap['role'] as String;

        final detail = detailsMap[id];
        final addr = detail?['addresses'] as Map<String, dynamic>?;
        final area = addr?['area'] as String?;
        final cityMap = addr?['cities'] as Map<String, dynamic>?;
        final cityName = cityMap?['name'] as String?;

        items.add(PgSwitcherItem(
          pgId: id,
          name: name,
          role: role,
          area: area,
          cityName: cityName,
        ));
      }
      return items;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<RoomType>> getRoomTypes() async {
    final client = _client;
    if (client == null) return [];
    try {
      final response = await client
          .from('room_types')
          .select('id, code, label')
          .order('id');
      return (response as List<dynamic>)
          .map((json) => RoomType.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<BedOccupancy>> getBedOccupancy(String pgId) async {
    final client = _client;
    if (client == null) throw const AuthNetworkException();
    try {
      final response = await client
          .from('v_bed_occupancy')
          .select()
          .eq('pg_id', pgId)
          .order('room_number')
          .order('bed_label');
      return (response as List<dynamic>)
          .map((json) => BedOccupancy.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<int> addRooms({
    required String pgId,
    required int firstRoomNumber,
    required int roomCount,
    required int bedsPerRoom,
    String? roomTypeCode,
    int? floor,
    String? prefix,
  }) async {
    final client = _client;
    if (client == null) throw const AuthNetworkException();
    try {
      final response = await client.rpc(
        'rpc_add_rooms',
        params: {
          'p_pg_id': pgId,
          'p_first_room_number': firstRoomNumber,
          'p_room_count': roomCount,
          'p_beds_per_room': bedsPerRoom,
          if (roomTypeCode != null) 'p_room_type_code': roomTypeCode,
          if (floor != null) 'p_floor': floor,
          'p_prefix': prefix ?? '',
        },
      );
      return (response as num?)?.toInt() ?? roomCount;
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<int> addRoomLayout({
    required String pgId,
    required List<Map<String, dynamic>> rooms,
  }) async {
    final client = _client;
    if (client == null) throw const AuthNetworkException();
    try {
      final response = await client.rpc(
        'rpc_add_room_layout',
        params: {
          'p_pg_id': pgId,
          'p_rooms': rooms,
        },
      );
      return (response as num?)?.toInt() ?? rooms.length;
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      rethrow;
    }
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
  }) async {
    final client = _client;
    if (client == null) throw const AuthNetworkException();
    try {
      final response = await client.rpc(
        'rpc_create_pg',
        params: {
          'p_name': name,
          'p_line1': line1,
          'p_city_id': cityId,
          if (pincode != null) 'p_pincode': pincode,
          if (area != null) 'p_area': area,
          if (contactPhone != null) 'p_contact_phone': contactPhone,
          'p_gender_policy': genderPolicy,
        },
      );
      return response.toString();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      throw const AuthNetworkException();
    }
  }
}

