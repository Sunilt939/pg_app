import 'package:flutter/foundation.dart';

@immutable
class ReminderRule {
  final String id;
  final String pgId;
  final int daysFromDue;
  final String channel;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReminderRule({
    required this.id,
    required this.pgId,
    required this.daysFromDue,
    required this.channel,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  ReminderRule copyWith({
    String? id,
    String? pgId,
    int? daysFromDue,
    String? channel,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReminderRule(
      id: id ?? this.id,
      pgId: pgId ?? this.pgId,
      daysFromDue: daysFromDue ?? this.daysFromDue,
      channel: channel ?? this.channel,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ReminderRule.fromJson(Map<String, dynamic> json) {
    return ReminderRule(
      id: json['id'] as String,
      pgId: json['pg_id'] as String,
      daysFromDue: json['days_from_due'] as int,
      channel: json['channel'] as String? ?? 'push',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pg_id': pgId,
      'days_from_due': daysFromDue,
      'channel': channel,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

