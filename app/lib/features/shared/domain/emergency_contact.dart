import 'package:flutter/foundation.dart';

@immutable
class RelationshipType {
  final int id;
  final String code;
  final String label;

  const RelationshipType({
    required this.id,
    required this.code,
    required this.label,
  });

  factory RelationshipType.fromJson(Map<String, dynamic> json) {
    return RelationshipType(
      id: (json['id'] as num).toInt(),
      code: json['code'] as String,
      label: json['label'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'label': label,
      };
}

@immutable
class EmergencyContact {
  final String id;
  final String personId;
  final String name;
  final String phone;
  final int? relationshipTypeId;
  final String? relationshipLabel;
  final bool isPrimary;
  final String? createdAt;

  const EmergencyContact({
    required this.id,
    required this.personId,
    required this.name,
    required this.phone,
    this.relationshipTypeId,
    this.relationshipLabel,
    this.isPrimary = false,
    this.createdAt,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    String? relLabel;
    if (json['relationship_types'] != null &&
        json['relationship_types'] is Map) {
      relLabel = (json['relationship_types'] as Map)['label'] as String?;
    }
    return EmergencyContact(
      id: json['id'] as String,
      personId: json['person_id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      relationshipTypeId: json['relationship_type_id'] != null
          ? (json['relationship_type_id'] as num).toInt()
          : null,
      relationshipLabel: relLabel ?? json['relationship_label'] as String?,
      isPrimary: json['is_primary'] as bool? ?? false,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'person_id': personId,
        'name': name,
        'phone': phone,
        if (relationshipTypeId != null)
          'relationship_type_id': relationshipTypeId,
        'is_primary': isPrimary,
        if (createdAt != null) 'created_at': createdAt,
      };
}

