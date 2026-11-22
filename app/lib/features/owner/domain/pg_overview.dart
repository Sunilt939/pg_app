import 'package:flutter/foundation.dart';

@immutable
class PgOverview {
  final String pgId;
  final int openCount;
  final int overdueCount;
  final int dueCount;
  final int paidCount;
  final int pastCount;
  final int overdueTotalPaise;
  final int pendingPaymentCount;

  const PgOverview({
    required this.pgId,
    this.openCount = 0,
    this.overdueCount = 0,
    this.dueCount = 0,
    this.paidCount = 0,
    this.pastCount = 0,
    this.overdueTotalPaise = 0,
    this.pendingPaymentCount = 0,
  });

  factory PgOverview.fromJson(Map<String, dynamic> json) {
    return PgOverview(
      pgId: json['pg_id'] as String? ?? '',
      openCount: (json['open_count'] as num?)?.toInt() ?? 0,
      overdueCount: (json['overdue_count'] as num?)?.toInt() ?? 0,
      dueCount: (json['due_count'] as num?)?.toInt() ?? 0,
      paidCount: (json['paid_count'] as num?)?.toInt() ?? 0,
      pastCount: (json['past_count'] as num?)?.toInt() ?? 0,
      overdueTotalPaise: (json['overdue_total_paise'] as num?)?.toInt() ?? 0,
      pendingPaymentCount: (json['pending_payment_count'] as num?)?.toInt() ?? 0,
    );
  }
}

