import 'package:flutter/foundation.dart';

@immutable
class EmergencyContact {
  final String id;
  final String personId;
  final String name;
  final String phone;
  final String? relationship;
  final bool isPrimary;

  const EmergencyContact({
    required this.id,
    required this.personId,
    required this.name,
    required this.phone,
    this.relationship,
    this.isPrimary = false,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    String? rel;
    final relObj = json['relationship_types'];
    if (relObj is Map<String, dynamic>) {
      rel = relObj['label'] as String?;
    } else if (json['relationship'] is String) {
      rel = json['relationship'] as String;
    }

    return EmergencyContact(
      id: json['id'] as String? ?? '',
      personId: json['person_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      relationship: rel,
      isPrimary: json['is_primary'] as bool? ?? false,
    );
  }
}

