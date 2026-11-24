import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../owner/domain/guest_list_item.dart';
import '../../data/supabase_profile_repository.dart';
import '../../domain/emergency_contact.dart';
import '../../domain/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return SupabaseProfileRepository();
});

class ProfilePhotoState {
  final String? localPhotoPath;
  final String? presetAvatarId;

  const ProfilePhotoState({
    this.localPhotoPath,
    this.presetAvatarId,
  });

  bool get hasCustomPhoto => localPhotoPath != null || presetAvatarId != null;
}

class ProfilePhotoNotifier extends AsyncNotifier<ProfilePhotoState> {
  @override
  Future<ProfilePhotoState> build() async {
    final repo = ref.watch(profileRepositoryProvider);
    final photoPath = await repo.getProfilePhotoPath();
    final presetId = await repo.getPresetAvatarId();
    return ProfilePhotoState(
      localPhotoPath: photoPath,
      presetAvatarId: presetId,
    );
  }

  Future<void> setPhoto(String filePath) async {
    final repo = ref.read(profileRepositoryProvider);
    await repo.updateProfilePhoto(filePath);
    state = AsyncData(ProfilePhotoState(localPhotoPath: filePath));
  }

  Future<void> setPreset(String presetId) async {
    final repo = ref.read(profileRepositoryProvider);
    await repo.updatePresetAvatar(presetId);
    state = AsyncData(ProfilePhotoState(presetAvatarId: presetId));
  }

  Future<void> removePhoto() async {
    final repo = ref.read(profileRepositoryProvider);
    await repo.removeProfilePhoto();
    state = const AsyncData(ProfilePhotoState());
  }
}

final profilePhotoProvider =
    AsyncNotifierProvider<ProfilePhotoNotifier, ProfilePhotoState>(() {
  return ProfilePhotoNotifier();
});

final emergencyContactsProvider =
    FutureProvider.autoDispose<List<EmergencyContact>>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getEmergencyContacts();
});

final relationshipTypesProvider =
    FutureProvider.autoDispose<List<RelationshipType>>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getRelationshipTypes();
});

final guestOpenStayProvider =
    FutureProvider.autoDispose<GuestListItem?>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getGuestOpenStay();
});
