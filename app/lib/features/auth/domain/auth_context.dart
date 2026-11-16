import 'package:flutter/foundation.dart';

@immutable
class AuthPerson {
  final String id;
  final String phone;
  final String? fullName;
  final String? email;

  const AuthPerson({
    required this.id,
    required this.phone,
    this.fullName,
    this.email,
  });

  factory AuthPerson.fromJson(Map<String, dynamic> json) {
    return AuthPerson(
      id: json['id'] as String,
      phone: json['phone'] as String,
      fullName: json['full_name'] as String?,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      if (fullName != null) 'full_name': fullName,
      if (email != null) 'email': email,
    };
  }
}

@immutable
class AuthPg {
  final String pgId;
  final String name;
  final String role; // 'owner' | 'manager' | 'caretaker'

  const AuthPg({
    required this.pgId,
    required this.name,
    required this.role,
  });

  factory AuthPg.fromJson(Map<String, dynamic> json) {
    return AuthPg(
      pgId: json['pg_id'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pg_id': pgId,
      'name': name,
      'role': role,
    };
  }
}

@immutable
class AuthStay {
  final String stayId;
  final String pgId;
  final String pgName;
  final String status;
  final String? joinDate;
  final String? leaveDate;

  const AuthStay({
    required this.stayId,
    required this.pgId,
    required this.pgName,
    required this.status,
    this.joinDate,
    this.leaveDate,
  });

  factory AuthStay.fromJson(Map<String, dynamic> json) {
    return AuthStay(
      stayId: json['stay_id'] as String,
      pgId: json['pg_id'] as String,
      pgName: json['pg_name'] as String,
      status: json['status'] as String,
      joinDate: json['join_date'] as String?,
      leaveDate: json['leave_date'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stay_id': stayId,
      'pg_id': pgId,
      'pg_name': pgName,
      'status': status,
      if (joinDate != null) 'join_date': joinDate,
      if (leaveDate != null) 'leave_date': leaveDate,
    };
  }
}

@immutable
class AuthContext {
  final AuthPerson? person;
  final List<AuthPg> pgs;
  final List<AuthStay> stays;

  const AuthContext({
    this.person,
    this.pgs = const [],
    this.stays = const [],
  });

  const AuthContext.empty()
      : person = null,
        pgs = const [],
        stays = const [];

  bool get isSignedIn => person != null;
  bool get isOwner => pgs.isNotEmpty;
  bool get isGuest => stays.isNotEmpty;
  bool get isNeither => isSignedIn && !isOwner && !isGuest;

  factory AuthContext.fromJson(Map<String, dynamic> json) {
    final personJson = json['person'] as Map<String, dynamic>?;
    final pgsJson = json['pgs'] as List<dynamic>? ?? [];
    final staysJson = json['stays'] as List<dynamic>? ?? [];

    return AuthContext(
      person: personJson != null ? AuthPerson.fromJson(personJson) : null,
      pgs: pgsJson
          .map((item) => AuthPg.fromJson(item as Map<String, dynamic>))
          .toList(),
      stays: staysJson
          .map((item) => AuthStay.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'person': person?.toJson(),
      'pgs': pgs.map((pg) => pg.toJson()).toList(),
      'stays': stays.map((stay) => stay.toJson()).toList(),
    };
  }
}

