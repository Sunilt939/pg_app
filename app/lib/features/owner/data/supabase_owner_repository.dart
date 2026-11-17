import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/domain/auth_repository.dart';
import '../domain/city.dart';
import '../domain/owner_repository.dart';

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

