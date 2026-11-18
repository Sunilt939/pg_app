abstract class ProfileRepository {
  Future<void> updateName(String fullName);
  Future<void> updateEmail(String? email);
  Future<String?> getProfilePhotoPath();
  Future<String?> getPresetAvatarId();
  Future<void> updateProfilePhoto(String filePath);
  Future<void> updatePresetAvatar(String presetId);
  Future<void> removeProfilePhoto();
}
