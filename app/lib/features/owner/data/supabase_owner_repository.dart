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

  @override
  Future<GuestDetailBundle?> getGuestDetailBundle(String stayId) async {
    final client = _client;
    if (client == null) return null;
    try {
      final guestResp = await client
          .from('v_guest_list')
          .select()
          .eq('stay_id', stayId)
          .maybeSingle();
      if (guestResp == null) return null;
      final guest = GuestListItem.fromJson(guestResp);

      final chargesFuture = client
          .from('v_charge_balances')
          .select()
          .eq('stay_id', stayId)
          .order('due_date', ascending: false);

      final paymentsFuture = client
          .from('v_payment_feed')
          .select()
          .eq('stay_id', stayId)
          .order('paid_on', ascending: false);

      Future<dynamic>? emergencyFuture;
      Future<dynamic>? docsFuture;

      if (guest.stayStatus != 'vacated') {
        emergencyFuture = client
            .from('emergency_contacts')
            .select('id, person_id, name, phone, is_primary, relationship_types(label)')
            .eq('person_id', guest.personId)
            .eq('is_primary', true)
            .maybeSingle();

        docsFuture = client
            .from('person_documents')
            .select('id')
            .eq('person_id', guest.personId);
      }

      final results = await Future.wait([
        chargesFuture,
        paymentsFuture,
        if (emergencyFuture != null) emergencyFuture else Future.value(null),
        if (docsFuture != null) docsFuture else Future.value(null),
      ]);

      final chargesList = (results[0] as List<dynamic>?)
              ?.map((json) => ChargeBalance.fromJson(json as Map<String, dynamic>))
              .toList() ??
          [];

      final paymentsList = (results[1] as List<dynamic>?)
              ?.map((json) => PaymentFeedItem.fromJson(json as Map<String, dynamic>))
              .toList() ??
          [];

      EmergencyContact? emergencyContact;
      if (results[2] != null && results[2] is Map<String, dynamic>) {
        emergencyContact =
            EmergencyContact.fromJson(results[2] as Map<String, dynamic>);
      }

      int documentsCount = 0;
      if (results.length > 3 && results[3] is List<dynamic>) {
        documentsCount = (results[3] as List<dynamic>).length;
      }

      return GuestDetailBundle(
        guest: guest,
        charges: chargesList,
        payments: paymentsList,
        emergencyContact: emergencyContact,
        documentsCount: documentsCount,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> setStayRent({
    required String stayId,
    required int monthlyRentPaise,
    required DateTime effectiveFrom,
  }) async {
    final client = _client;
    if (client == null) throw const AuthNetworkException();

    try {
      final formattedEffectiveFrom =
          '${effectiveFrom.year.toString().padLeft(4, '0')}-${effectiveFrom.month.toString().padLeft(2, '0')}-${effectiveFrom.day.toString().padLeft(2, '0')}';
      await client.rpc(
        'rpc_set_stay_rent',
        params: {
          'p_stay_id': stayId,
          'p_monthly_rent_paise': monthlyRentPaise,
          'p_effective_from': formattedEffectiveFrom,
        },
      );
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw const DuplicateRentDateException();
      }
      throw Exception(e.message);
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<List<ChargeType>> getChargeTypes() async {
    final client = _client;
    if (client == null) throw const AuthNetworkException();

    try {
      final response = await client
          .from('charge_types')
          .select('id, code, label, is_refundable, is_recurring, is_active')
          .eq('is_active', true)
          .neq('code', 'rent')
          .order('id');

      final list = response as List<dynamic>;
      return list
          .map((json) => ChargeType.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      throw const AuthNetworkException();
    }
  }

  @override
  Future<void> addCharge({
    required String stayId,
    required String chargeTypeCode,
    required int amountPaise,
    required DateTime dueDate,
    String? description,
    DateTime? periodMonth,
  }) async {
    final client = _client;
    if (client == null) throw const AuthNetworkException();

    try {
      final formattedDueDate =
          '${dueDate.year.toString().padLeft(4, '0')}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}';
      final formattedPeriodMonth = periodMonth != null
          ? '${periodMonth.year.toString().padLeft(4, '0')}-${periodMonth.month.toString().padLeft(2, '0')}-${periodMonth.day.toString().padLeft(2, '0')}'
          : null;

      await client.rpc(
        'rpc_add_charge',
        params: {
          'p_stay_id': stayId,
          'p_charge_type_code': chargeTypeCode,
          'p_amount_paise': amountPaise,
          'p_due_date': formattedDueDate,
          'p_description': description,
          'p_period_month': formattedPeriodMonth,
        },
      );
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> voidCharge({
    required String chargeId,
    required String reason,
  }) async {
    final client = _client;
    if (client == null) throw const AuthNetworkException();

    try {
      await client.rpc(
        'rpc_void_charge',
        params: {
          'p_charge_id': chargeId,
          'p_reason': reason,
        },
      );
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> correctGuestName({
    required String personId,
    required String fullName,
  }) async {
    final client = _client;
    if (client == null) throw const AuthNetworkException();

    try {
      await client.rpc(
        'rpc_correct_guest_name',
        params: {
          'p_person_id': personId,
          'p_full_name': fullName,
        },
      );
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> vacateStay({
    required String stayId,
    DateTime? leaveDate,
  }) async {
    final client = _client;
    if (client == null) throw const AuthNetworkException();

    try {
      await client.rpc(
        'rpc_vacate_stay',
        params: {
          'p_stay_id': stayId,
          if (leaveDate != null)
            'p_leave_date':
                '${leaveDate.year}-${leaveDate.month.toString().padLeft(2, '0')}-${leaveDate.day.toString().padLeft(2, '0')}',
        },
      );
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<List<PaymentMethod>> getPaymentMethods() async {
    final client = _client;
    if (client == null) throw const AuthNetworkException();

    final response = await client
        .from('payment_methods')
        .select()
        .eq('is_active', true)
        .order('id');

    return (response as List)
        .map((e) => PaymentMethod.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<UpiApp>> getUpiApps() async {
    final client = _client;
    if (client == null) throw const AuthNetworkException();

    final response =
        await client.from('upi_apps').select().order('id');

    return (response as List)
        .map((e) => UpiApp.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<String> recordPayment({
    required String stayId,
    required int amountPaise,
    required String methodCode,
    DateTime? paidOn,
    String? accountId,
    String? note,
    String? payerAppCode,
    String? utr,
  }) async {
    final client = _client;
    if (client == null) throw const AuthNetworkException();

    try {
      final formattedPaidOn = paidOn != null
          ? '${paidOn.year.toString().padLeft(4, '0')}-${paidOn.month.toString().padLeft(2, '0')}-${paidOn.day.toString().padLeft(2, '0')}'
          : null;

      final res = await client.rpc(
        'rpc_record_payment',
        params: {
          'p_stay_id': stayId,
          'p_amount_paise': amountPaise,
          'p_method_code': methodCode,
          if (formattedPaidOn != null) 'p_paid_on': formattedPaidOn,
          if (accountId != null) 'p_account_id': accountId,
          if (note != null && note.trim().isNotEmpty) 'p_note': note.trim(),
          if (payerAppCode != null && payerAppCode.isNotEmpty)
            'p_payer_app_code': payerAppCode,
          if (utr != null && utr.trim().isNotEmpty) 'p_utr': utr.trim(),
        },
      );
      return res as String;
    } on PostgrestException catch (e) {
      if (e.code == '23505' || e.message.contains('UTR is already recorded')) {
        throw DuplicateUtrException(e.message);
      }
      throw Exception(e.message);
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<PaymentFeedItem?> getPaymentDetail(String paymentId) async {
    final client = _client;
    if (client == null) throw const AuthNetworkException();

    final response = await client
        .from('v_payment_feed')
        .select()
        .eq('payment_id', paymentId)
        .maybeSingle();

    if (response == null) return null;
    return PaymentFeedItem.fromJson(response);
  }

  @override
  Future<List<PaymentFeedItem>> getPgPayments(String pgId) async {
    final client = _client;
    if (client == null) throw const AuthNetworkException();

    final response = await client
        .from('v_payment_feed')
        .select()
        .eq('pg_id', pgId)
        .order('paid_on', ascending: false)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((row) => PaymentFeedItem.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> confirmPayment({
    required String paymentId,
    String? accountId,
  }) async {
    final client = _client;
    if (client == null) throw const AuthNetworkException();

    await client.rpc(
      'rpc_confirm_payment',
      params: {
        'p_payment_id': paymentId,
        if (accountId != null) 'p_account_id': accountId,
      },
    );
  }

  @override
  Future<void> rejectPayment({
    required String paymentId,
    required String reason,
  }) async {
    final client = _client;
    if (client == null) throw const AuthNetworkException();

    await client.rpc(
      'rpc_reject_payment',
      params: {
        'p_payment_id': paymentId,
        'p_reason': reason.trim(),
      },
    );
  }

  @override
  Future<void> reversePayment({
    required String paymentId,
    required String reason,
  }) async {
    final client = _client;
    if (client == null) throw const AuthNetworkException();

    await client.rpc(
      'rpc_reverse_payment',
      params: {
        'p_payment_id': paymentId,
        'p_reason': reason.trim(),
      },
    );
  }

  @override
  Future<String?> getSignedFileUrl(String fileId) async {
    final client = _client;
    if (client == null) throw const AuthNetworkException();

    try {
      final fileRow = await client
          .from('files')
          .select('bucket, object_path')
          .eq('id', fileId)
          .maybeSingle();

      if (fileRow == null) return null;
      final bucket = fileRow['bucket'] as String;
      final objectPath = fileRow['object_path'] as String;

      final signedUrl = await client.storage
          .from(bucket)
          .createSignedUrl(objectPath, 300);
      return signedUrl;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<MonthCollections> getMonthCollections({
    required String pgId,
    required String month,
  }) async {
    final client = _client;
    if (client == null) throw const AuthNetworkException();

    final totalResp = await client
        .from('v_collections_month_total')
        .select()
        .eq('pg_id', pgId)
        .eq('month', month)
        .maybeSingle();

    final accountsResp = await client
        .from('v_collections_by_account')
        .select()
        .eq('pg_id', pgId)
        .eq('month', month)
        .order('total_paise', ascending: false);

    final byAccount = (accountsResp as List<dynamic>)
        .map((row) => AccountCollection.fromJson(row as Map<String, dynamic>))
        .toList();

    return MonthCollections(
      pgId: pgId,
      month: month,
      totalPaise: (totalResp?['total_paise'] as num?)?.toInt() ?? 0,
      paymentCount: (totalResp?['payment_count'] as num?)?.toInt() ?? 0,
      byAccount: byAccount,
    );
  }

  @override
  Future<OwnerHomeBundle> getOwnerHomeBundle({
    required String pgId,
    required String month,
  }) async {
    final client = _client;
    if (client == null) throw const AuthNetworkException();

    final setupFuture = client
        .from('v_pg_setup_status')
        .select()
        .eq('pg_id', pgId)
        .maybeSingle();

    final overviewFuture = client
        .from('v_pg_overview')
        .select()
        .eq('pg_id', pgId)
        .maybeSingle();

    final summaryFuture = client
        .from('v_pg_monthly_summary')
        .select()
        .eq('pg_id', pgId)
        .eq('period_month', month)
        .maybeSingle();

    final pendingPaymentsFuture = client
        .from('v_payment_feed')
        .select()
        .eq('pg_id', pgId)
        .eq('status', 'pending')
        .order('paid_on', ascending: true)
        .order('created_at', ascending: true);

    final overdueGuestsFuture = client
        .from('v_guest_list')
        .select()
        .eq('pg_id', pgId)
        .gt('overdue_paise', 0)
        .neq('stay_status', 'vacated')
        .order('oldest_unpaid_due_date', ascending: true);

    final openGuestsFuture = client
        .from('v_guest_list')
        .select()
        .eq('pg_id', pgId)
        .neq('stay_status', 'vacated')
        .order('full_name', ascending: true);

    final results = await Future.wait([
      setupFuture,
      overviewFuture,
      summaryFuture,
      pendingPaymentsFuture,
      overdueGuestsFuture,
      openGuestsFuture,
    ]);

    final setupMap = results[0] as Map<String, dynamic>?;
    final overviewMap = results[1] as Map<String, dynamic>?;
    final summaryMap = results[2] as Map<String, dynamic>?;
    final pendingList = results[3] as List<dynamic>;
    final overdueList = results[4] as List<dynamic>;
    final openList = results[5] as List<dynamic>;

    return OwnerHomeBundle(
      setupStatus: setupMap != null
          ? PgSetupStatus.fromJson(setupMap)
          : PgSetupStatus(pgId: pgId),
      overview:
          overviewMap != null ? PgOverview.fromJson(overviewMap) : null,
      monthlySummary: summaryMap != null
          ? PgMonthlySummary.fromJson(summaryMap)
          : null,
      pendingPayments: pendingList
          .map((r) => PaymentFeedItem.fromJson(r as Map<String, dynamic>))
          .toList(),
      overdueGuests: overdueList
          .map((r) => GuestListItem.fromJson(r as Map<String, dynamic>))
          .toList(),
      openGuests: openList
          .map((r) => GuestListItem.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Future<List<ReminderRule>> getReminderRules(String pgId) async {
    final client = _client;
    if (client == null) return const [];

    final response = await client
        .from('reminder_rules')
        .select()
        .eq('pg_id', pgId)
        .order('days_from_due');

    return (response as List<dynamic>)
        .map((row) => ReminderRule.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveReminderRule({
    String? id,
    required String pgId,
    required int daysFromDue,
    required String channel,
  }) async {
    final client = _client;
    if (client == null) return;

    try {
      if (id == null) {
        await client.from('reminder_rules').insert({
          'pg_id': pgId,
          'days_from_due': daysFromDue,
          'channel': channel,
          'is_active': true,
        });
      } else {
        await client.from('reminder_rules').update({
          'days_from_due': daysFromDue,
          'channel': channel,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', id);
      }
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw const DuplicateReminderRuleException();
      }
      rethrow;
    }
  }

  @override
  Future<void> toggleReminderRule({
    required String id,
    required bool isActive,
  }) async {
    final client = _client;
    if (client == null) return;

    await client.from('reminder_rules').update({
      'is_active': isActive,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  @override
  Future<void> deleteReminderRule(String id) async {
    final client = _client;
    if (client == null) return;

    await client.from('reminder_rules').delete().eq('id', id);
  }

  @override
  Future<PgDetails?> getPgDetails(String pgId) async {
    final client = _client;
    if (client == null) return null;

    final response = await client
        .from('pgs')
        .select('id, name, gender_policy, contact_phone, address_id, addresses(id, line1, area, city_id, pincode, cities(id, name, states(name)))')
        .eq('id', pgId)
        .maybeSingle();

    if (response == null) return null;
    return PgDetails.fromJson(response);
  }

  @override
  Future<void> updatePgName({
    required String pgId,
    required String name,
  }) async {
    final client = _client;
    if (client == null) throw const AuthNetworkException();

    await client.from('pgs').update({
      'name': name.trim(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', pgId);
  }

  @override
  Future<void> updatePgGenderPolicy({
    required String pgId,
    required String genderPolicy,
  }) async {
    final client = _client;
    if (client == null) throw const AuthNetworkException();

    await client.from('pgs').update({
      'gender_policy': genderPolicy,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', pgId);
  }

  @override
  Future<void> updatePgContactPhone({
    required String pgId,
    String? contactPhone,
  }) async {
    final client = _client;
    if (client == null) throw const AuthNetworkException();

    await client.from('pgs').update({
      'contact_phone': contactPhone != null && contactPhone.trim().isNotEmpty
          ? contactPhone.trim()
          : null,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', pgId);
  }

  @override
  Future<void> updatePgAddress({
    required String pgId,
    required String addressId,
    required String line1,
    String? area,
    required int cityId,
    String? pincode,
  }) async {
    final client = _client;
    if (client == null) throw const AuthNetworkException();

    if (addressId.trim().isNotEmpty) {
      await client.from('addresses').update({
        'line1': line1.trim(),
        'area': area != null && area.trim().isNotEmpty ? area.trim() : null,
        'city_id': cityId,
        'pincode': pincode != null && pincode.trim().isNotEmpty ? pincode.trim() : null,
      }).eq('id', addressId);
    } else {
      final res = await client.from('addresses').insert({
        'line1': line1.trim(),
        'area': area != null && area.trim().isNotEmpty ? area.trim() : null,
        'city_id': cityId,
        'pincode': pincode != null && pincode.trim().isNotEmpty ? pincode.trim() : null,
      }).select('id').single();
      final newAddressId = res['id'] as String;
      await client.from('pgs').update({
        'address_id': newAddressId,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', pgId);
    }
  }
}

