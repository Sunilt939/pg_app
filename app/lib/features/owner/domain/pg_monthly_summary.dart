import 'package:flutter/foundation.dart';

@immutable
class PgMonthlySummary {
  final String pgId;
  final String periodMonth;
  final int tenantsBilled;
  final int expectedPaise;
  final int collectedPaise;
  final int pendingPaise;
  final int overduePaise;

  const PgMonthlySummary({
    required this.pgId,
    required this.periodMonth,
    this.tenantsBilled = 0,
    this.expectedPaise = 0,
    this.collectedPaise = 0,
    this.pendingPaise = 0,
    this.overduePaise = 0,
  });

  factory PgMonthlySummary.fromJson(Map<String, dynamic> json) {
    return PgMonthlySummary(
      pgId: json['pg_id'] as String? ?? '',
      periodMonth: json['period_month'] as String? ?? '',
      tenantsBilled: (json['tenants_billed'] as num?)?.toInt() ?? 0,
      expectedPaise: (json['expected_paise'] as num?)?.toInt() ?? 0,
      collectedPaise: (json['collected_paise'] as num?)?.toInt() ?? 0,
      pendingPaise: (json['pending_paise'] as num?)?.toInt() ?? 0,
      overduePaise: (json['overdue_paise'] as num?)?.toInt() ?? 0,
    );
  }
}

