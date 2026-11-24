import '../../owner/domain/guest_list_item.dart';
import 'emergency_contact.dart';

abstract class ProfileRepository {
  Future<void> updateName(String fullName);
  Future<void> updateEmail(String? email);
  Future<String?> getProfilePhotoPath();
  Future<String?> getPresetAvatarId();
  Future<void> updateProfilePhoto(String filePath);
  Future<void> updatePresetAvatar(String presetId);
  Future<void> removeProfilePhoto();

  Future<List<EmergencyContact>> getEmergencyContacts();
  Future<List<RelationshipType>> getRelationshipTypes();
  Future<void> addEmergencyContact({
    required String name,
    required String phone,
    int? relationshipTypeId,
    bool isPrimary = false,
  });
  Future<void> updateEmergencyContact({
    required String id,
    required String name,
    required String phone,
    int? relationshipTypeId,
    bool isPrimary = false,
  });
  Future<void> deleteEmergencyContact(String id);
  Future<GuestListItem?> getGuestOpenStay();
}
