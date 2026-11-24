import 'package:flutter/foundation.dart';

@immutable
class PgSetupStatus {
  final String pgId;
  final int roomsCount;
  final int accountsCount;
  final int guestsCount;

  const PgSetupStatus({
    required this.pgId,
    this.roomsCount = 0,
    this.accountsCount = 0,
    this.guestsCount = 0,
  });

  bool get isCompleted =>
      roomsCount > 0 && accountsCount > 0 && guestsCount > 0;

  factory PgSetupStatus.fromJson(Map<String, dynamic> json) {
    return PgSetupStatus(
      pgId: json['pg_id'] as String? ?? '',
      roomsCount: (json['rooms_count'] as num?)?.toInt() ?? 0,
      accountsCount: (json['accounts_count'] as num?)?.toInt() ?? 0,
      guestsCount: (json['guests_count'] as num?)?.toInt() ?? 0,
    );
  }
}

