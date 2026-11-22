import 'package:flutter/foundation.dart';

@immutable
class ChargeBalance {
  final String chargeId;
  final String stayId;
  final int? chargeTypeId;
  final String? periodMonth;
  final String description;
  final String dueDate;
  final int amountPaise;
  final int paidPaise;
  final int outstandingPaise;
  final String status; // 'paid' | 'partial' | 'due' | 'overdue' | 'void'

  const ChargeBalance({
    required this.chargeId,
    required this.stayId,
    this.chargeTypeId,
    this.periodMonth,
    required this.description,
    required this.dueDate,
    this.amountPaise = 0,
    this.paidPaise = 0,
    this.outstandingPaise = 0,
    required this.status,
  });

  factory ChargeBalance.fromJson(Map<String, dynamic> json) {
    return ChargeBalance(
      chargeId: json['charge_id'] as String? ?? json['id'] as String? ?? '',
      stayId: json['stay_id'] as String? ?? '',
      chargeTypeId: (json['charge_type_id'] as num?)?.toInt(),
      periodMonth: json['period_month'] as String?,
      description: json['description'] as String? ?? '',
      dueDate: json['due_date'] as String? ?? '',
      amountPaise: (json['amount_paise'] as num?)?.toInt() ?? 0,
      paidPaise: (json['paid_paise'] as num?)?.toInt() ?? 0,
      outstandingPaise: (json['outstanding_paise'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'due',
    );
  }
}

