import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/domain/auth_repository.dart';
import '../domain/bed_occupancy.dart';
import '../domain/city.dart';
import '../domain/owner_repository.dart';
import '../domain/payment_account.dart';
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
  Future<List<PaymentAccount>> getPaymentAccounts(String pgId) async {
    final client = _client;
    if (client == null) return [];
    try {
      final response = await client
          .from('pg_payment_accounts')
          .select()
          .eq('pg_id', pgId)
          .order('created_at', ascending: true);
      return (response as List<dynamic>)
          .map((json) => PaymentAccount.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<PaymentAccount?> getPaymentAccount(String id) async {
    final client = _client;
    if (client == null) return null;
    try {
      final response = await client
          .from('pg_payment_accounts')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return PaymentAccount.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<PaymentAccount> createPaymentAccount(PaymentAccount account) async {
    final client = _client;
    if (client == null) throw const AuthNetworkException();

    final data = <String, dynamic>{
      'pg_id': account.pgId,
      'nickname': account.nickname,
      'kind': account.kind,
      'upi_vpa': account.kind == 'upi' ? account.upiVpa : null,
      'bank_name': account.kind == 'bank' ? account.bankName : null,
      'account_last4': account.kind == 'bank' &&
              account.accountLast4 != null &&
              account.accountLast4!.isNotEmpty
          ? account.accountLast4
          : null,
      'holder_name': account.holderName != null && account.holderName!.isNotEmpty
          ? account.holderName
          : null,
      'linked_phone':
          account.linkedPhone != null && account.linkedPhone!.isNotEmpty
              ? account.linkedPhone
              : null,
      'is_default': account.isDefault,
      'is_active': account.isActive,
    };

    try {
      if (account.isDefault) {
        await client
            .from('pg_payment_accounts')
            .update({'is_default': false})
            .eq('pg_id', account.pgId);
      }
      final response = await client
          .from('pg_payment_accounts')
          .insert(data)
          .select()
          .single();
      return PaymentAccount.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw const DuplicateNicknameException();
      }
      throw Exception(e.message);
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<PaymentAccount> updatePaymentAccount(PaymentAccount account) async {
    final client = _client;
    if (client == null) throw const AuthNetworkException();

    bool wasDefault = false;
    try {
      final existing = await client
          .from('pg_payment_accounts')
          .select('is_default')
          .eq('id', account.id)
          .maybeSingle();
      if (existing != null) {
        wasDefault = existing['is_default'] as bool? ?? false;
      }
    } catch (_) {}

    final effectiveIsDefault = account.isActive && account.isDefault;

    final data = <String, dynamic>{
      'nickname': account.nickname,
      'kind': account.kind,
      'upi_vpa': account.kind == 'upi' ? account.upiVpa : null,
      'bank_name': account.kind == 'bank' ? account.bankName : null,
      'account_last4': account.kind == 'bank' &&
              account.accountLast4 != null &&
              account.accountLast4!.isNotEmpty
          ? account.accountLast4
          : null,
      'holder_name': account.holderName != null && account.holderName!.isNotEmpty
          ? account.holderName
          : null,
      'linked_phone':
          account.linkedPhone != null && account.linkedPhone!.isNotEmpty
              ? account.linkedPhone
              : null,
      'is_default': effectiveIsDefault,
      'is_active': account.isActive,
    };

    try {
      if (effectiveIsDefault) {
        await client
            .from('pg_payment_accounts')
            .update({'is_default': false})
            .eq('pg_id', account.pgId);
      }
      final response = await client
          .from('pg_payment_accounts')
          .update(data)
          .eq('id', account.id)
          .select()
          .single();

      if (wasDefault && !effectiveIsDefault) {
        final otherActive = await client
            .from('pg_payment_accounts')
            .select('id')
            .eq('pg_id', account.pgId)
            .eq('is_active', true)
            .neq('id', account.id)
            .order('created_at', ascending: true)
            .limit(1);
        final otherList = otherActive as List<dynamic>? ?? [];
        if (otherList.isNotEmpty) {
          final nextDefaultId =
              (otherList.first as Map<String, dynamic>)['id'] as String;
          await client
              .from('pg_payment_accounts')
              .update({'is_default': true})
              .eq('id', nextDefaultId);
        }
      }

      return PaymentAccount.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw const DuplicateNicknameException();
      }
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

  @override
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
  }) async {
    final client = _client;
    if (client == null) throw const AuthNetworkException();
    try {
      final formattedJoinDate =
          '${joinDate.year.toString().padLeft(4, '0')}-${joinDate.month.toString().padLeft(2, '0')}-${joinDate.day.toString().padLeft(2, '0')}';
      final formattedBillingStartsOn = billingStartsOn != null
          ? '${billingStartsOn.year.toString().padLeft(4, '0')}-${billingStartsOn.month.toString().padLeft(2, '0')}-${billingStartsOn.day.toString().padLeft(2, '0')}'
          : null;

      final response = await client.rpc(
        'rpc_create_stay',
        params: {
          'p_pg_id': pgId,
          'p_phone': phone,
          'p_full_name': fullName,
          'p_bed_id': bedId,
          'p_join_date': formattedJoinDate,
          'p_monthly_rent_paise': monthlyRentPaise,
          'p_deposit_paise': depositPaise,
          'p_billing_day': billingDay,
          'p_billing_starts_on': formattedBillingStartsOn,
          'p_deposit_already_paid': depositAlreadyPaid,
        },
      );
      return response.toString();
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        final fullMsg = '${e.message} ${e.details ?? ''}'.toLowerCase();
        if (fullMsg.contains('bed_has_one_current_occupant') || fullMsg.contains('bed')) {
          throw const BedAlreadyTakenException();
        } else {
          throw const DuplicateGuestStayException();
        }
      }
      throw Exception(e.message);
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<List<GuestListItem>> getGuests({
    required String pgId,
    int limit = 50,
    int offset = 0,
  }) async {
    final client = _client;
    if (client == null) return [];
    try {
      final response = await client
          .from('v_guest_list')
          .select()
          .eq('pg_id', pgId)
          .range(offset, offset + limit - 1);
      return (response as List<dynamic>)
          .map((json) => GuestListItem.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<PgOverview?> getPgOverview(String pgId) async {
    final client = _client;
    if (client == null) return null;
    try {
      final response = await client
          .from('v_pg_overview')
          .select()
          .eq('pg_id', pgId)
          .maybeSingle();
      if (response == null) return null;
      return PgOverview.fromJson(response);
    } catch (_) {
      return null;
    }
  }
}

