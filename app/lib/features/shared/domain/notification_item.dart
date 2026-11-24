import 'package:flutter/foundation.dart';

@immutable
class NotificationItem {
  final String id;
  final String personId;
  final String kind;
  final String title;
  final String body;
  final String? stayId;
  final String? chargeId;
  final String? reminderRuleId;
  final String channel;
  final String status;
  final DateTime? scheduledFor;
  final DateTime? sentAt;
  final DateTime? readAt;
  final DateTime createdAt;

  const NotificationItem({
    required this.id,
    required this.personId,
    required this.kind,
    required this.title,
    required this.body,
    this.stayId,
    this.chargeId,
    this.reminderRuleId,
    this.channel = 'in_app',
    this.status = 'sent',
    this.scheduledFor,
    this.sentAt,
    this.readAt,
    required this.createdAt,
  });

  bool get isUnread => status != 'read' && readAt == null;

  NotificationItem copyWith({
    String? id,
    String? personId,
    String? kind,
    String? title,
    String? body,
    String? stayId,
    String? chargeId,
    String? reminderRuleId,
    String? channel,
    String? status,
    DateTime? scheduledFor,
    DateTime? sentAt,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      body: body ?? this.body,
      stayId: stayId ?? this.stayId,
      chargeId: chargeId ?? this.chargeId,
      reminderRuleId: reminderRuleId ?? this.reminderRuleId,
      channel: channel ?? this.channel,
      status: status ?? this.status,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      sentAt: sentAt ?? this.sentAt,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      personId: json['person_id'] as String? ?? '',
      kind: json['kind'] as String? ?? 'system',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      stayId: json['stay_id'] as String?,
      chargeId: json['charge_id'] as String?,
      reminderRuleId: json['reminder_rule_id'] as String?,
      channel: json['channel'] as String? ?? 'in_app',
      status: json['status'] as String? ?? 'sent',
      scheduledFor: json['scheduled_for'] != null
          ? DateTime.tryParse(json['scheduled_for'] as String)
          : null,
      sentAt: json['sent_at'] != null
          ? DateTime.tryParse(json['sent_at'] as String)
          : null,
      readAt: json['read_at'] != null
          ? DateTime.tryParse(json['read_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'person_id': personId,
      'kind': kind,
      'title': title,
      'body': body,
      'stay_id': stayId,
      'charge_id': chargeId,
      'reminder_rule_id': reminderRuleId,
      'channel': channel,
      'status': status,
      'scheduled_for': scheduledFor?.toIso8601String(),
      'sent_at': sentAt?.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

