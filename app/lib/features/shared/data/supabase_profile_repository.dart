import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../owner/domain/guest_list_item.dart';
import '../domain/emergency_contact.dart';
import '../domain/profile_repository.dart';

class SupabaseProfileRepository implements ProfileRepository {
  final SupabaseClient? _client;
  final FlutterSecureStorage _storage;

  static const _photoPathKey = 'profile_photo_path';
  static const _avatarPresetKey = 'profile_avatar_preset';

  SupabaseProfileRepository({
    SupabaseClient? client,
    FlutterSecureStorage? storage,
  })  : _client = client ??
            (Supabase.instance.isInitialized ? Supabase.instance.client : null),
        _storage = storage ?? const FlutterSecureStorage();

  Future<String?> _getCurrentPersonId() async {
    final client = _client;
    if (client == null) return null;
    final user = client.auth.currentUser;
    if (user == null) return null;
    final res = await client
        .from('persons')
        .select('id')
        .eq('auth_user_id', user.id)
        .maybeSingle();
    return res?['id'] as String?;
  }

  @override
  Future<void> updateName(String fullName) async {
    final client = _client;
    if (client == null) return;
    final user = client.auth.currentUser;
    if (user == null) throw StateError('Not authenticated');

    final res = await client.from('persons').update({
      'full_name': fullName.trim(),
    }).eq('auth_user_id', user.id).select();

    if ((res as List).isEmpty) {
      throw Exception('Failed to update name: profile not found.');
    }
  }

  @override
  Future<void> updateEmail(String? email) async {
    final client = _client;
    if (client == null) return;
    final user = client.auth.currentUser;
    if (user == null) throw StateError('Not authenticated');

    final trimmed = email?.trim();
    final res = await client.from('persons').update({
      'email': (trimmed == null || trimmed.isEmpty) ? null : trimmed,
    }).eq('auth_user_id', user.id).select();

    if ((res as List).isEmpty) {
      throw Exception('Failed to update email: profile not found.');
    }
  }

  @override
  Future<String?> getProfilePhotoPath() async {
    try {
      return await _storage.read(key: _photoPathKey);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> getPresetAvatarId() async {
    try {
      return await _storage.read(key: _avatarPresetKey);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> updateProfilePhoto(String filePath) async {
    try {
      await _storage.write(key: _photoPathKey, value: filePath);
      await _storage.delete(key: _avatarPresetKey);
    } catch (_) {}
  }

  @override
  Future<void> updatePresetAvatar(String presetId) async {
    try {
      await _storage.write(key: _avatarPresetKey, value: presetId);
      await _storage.delete(key: _photoPathKey);
    } catch (_) {}
  }

  @override
  Future<void> removeProfilePhoto() async {
    try {
      await _storage.delete(key: _photoPathKey);
      await _storage.delete(key: _avatarPresetKey);
    } catch (_) {}
  }

  @override
  Future<List<EmergencyContact>> getEmergencyContacts() async {
    final client = _client;
    if (client == null) return [];
    final personId = await _getCurrentPersonId();
    if (personId == null) return [];

    final res = await client
        .from('emergency_contacts')
        .select('*, relationship_types(id, code, label)')
        .eq('person_id', personId)
        .order('is_primary', ascending: false)
        .order('created_at');

    return (res as List)
        .map((e) => EmergencyContact.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<RelationshipType>> getRelationshipTypes() async {
    final client = _client;
    if (client == null) return [];

    final res = await client
        .from('relationship_types')
        .select()
        .order('id');

    return (res as List)
        .map((e) => RelationshipType.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> addEmergencyContact({
    required String name,
    required String phone,
    int? relationshipTypeId,
    bool isPrimary = false,
  }) async {
    final client = _client;
    if (client == null) return;
    final personId = await _getCurrentPersonId();
    if (personId == null) throw StateError('Not authenticated');

    if (isPrimary) {
      await client
          .from('emergency_contacts')
          .update({'is_primary': false})
          .eq('person_id', personId)
          .eq('is_primary', true);
    }

    await client.from('emergency_contacts').insert({
      'person_id': personId,
      'name': name.trim(),
      'phone': phone.trim(),
      if (relationshipTypeId != null)
        'relationship_type_id': relationshipTypeId,
      'is_primary': isPrimary,
    });
  }

  @override
  Future<void> updateEmergencyContact({
    required String id,
    required String name,
    required String phone,
    int? relationshipTypeId,
    bool isPrimary = false,
  }) async {
    final client = _client;
    if (client == null) return;
    final personId = await _getCurrentPersonId();
    if (personId == null) throw StateError('Not authenticated');

    if (isPrimary) {
      await client
          .from('emergency_contacts')
          .update({'is_primary': false})
          .eq('person_id', personId)
          .eq('is_primary', true)
          .neq('id', id);
    }

    await client.from('emergency_contacts').update({
      'name': name.trim(),
      'phone': phone.trim(),
      'relationship_type_id': relationshipTypeId,
      'is_primary': isPrimary,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  @override
  Future<void> deleteEmergencyContact(String id) async {
    final client = _client;
    if (client == null) return;
    await client.from('emergency_contacts').delete().eq('id', id);
  }

  @override
  Future<GuestListItem?> getGuestOpenStay() async {
    final client = _client;
    if (client == null) return null;
    final personId = await _getCurrentPersonId();
    if (personId == null) return null;

    final res = await client
        .from('v_guest_list')
        .select()
        .eq('person_id', personId)
        .neq('stay_status', 'vacated')
        .order('join_date', ascending: false)
        .limit(1);

    final list = res as List;
    if (list.isEmpty) return null;
    return GuestListItem.fromJson(list.first as Map<String, dynamic>);
  }
}
