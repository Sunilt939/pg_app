import 'package:flutter/foundation.dart';

@immutable
class PgSwitcherItem {
  final String pgId;
  final String name;
  final String role; // 'owner' | 'manager' | 'caretaker'
  final String? area;
  final String? cityName;

  const PgSwitcherItem({
    required this.pgId,
    required this.name,
    required this.role,
    this.area,
    this.cityName,
  });

  String get location {
    final parts = [
      if (area != null && area!.trim().isNotEmpty) area!.trim(),
      if (cityName != null && cityName!.trim().isNotEmpty) cityName!.trim(),
    ];
    return parts.join(', ');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PgSwitcherItem &&
          runtimeType == other.runtimeType &&
          pgId == other.pgId;

  @override
  int get hashCode => pgId.hashCode;
}

