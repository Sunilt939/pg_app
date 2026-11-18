import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
}
