import 'package:flutter/foundation.dart';

@immutable
class GuestListItem {
  final String stayId;
  final String pgId;
  final String pgName;
  final String? pgContactPhone;
  final String personId;
  final String? fullName;
  final String phone;
  final String? photoFileId;
  final bool hasSignedIn;
  final String stayStatus;
  final String joinDate;
  final String? leaveDate;
  final int billingDay;
  final String? bedId;
  final String? bedLabel;
  final String? roomId;
  final String? roomNumber;
  final int? monthlyRentPaise;
  final int chargedPaise;
  final int paidPaise;
  final int outstandingPaise;
  final int overduePaise;
  final int creditPaise;
  final int pendingVerificationPaise;
  final String? oldestUnpaidDueDate;
  final int? dueNowPaise;
  final String? nextDueDate;
  final int? nextDuePaise;
  final String attentionState; // 'overdue' | 'pending' | 'due' | 'paid' | 'past'

  const GuestListItem({
    required this.stayId,
    required this.pgId,
    required this.pgName,
    this.pgContactPhone,
    required this.personId,
    this.fullName,
    required this.phone,
    this.photoFileId,
    this.hasSignedIn = false,
    required this.stayStatus,
    required this.joinDate,
    this.leaveDate,
    required this.billingDay,
    this.bedId,
    this.bedLabel,
    this.roomId,
    this.roomNumber,
    this.monthlyRentPaise,
    this.chargedPaise = 0,
    this.paidPaise = 0,
    this.outstandingPaise = 0,
    this.overduePaise = 0,
    this.creditPaise = 0,
    this.pendingVerificationPaise = 0,
    this.oldestUnpaidDueDate,
    this.dueNowPaise,
    this.nextDueDate,
    this.nextDuePaise,
    required this.attentionState,
  });

  factory GuestListItem.fromJson(Map<String, dynamic> json) {
    return GuestListItem(
      stayId: json['stay_id'] as String? ?? '',
      pgId: json['pg_id'] as String? ?? '',
      pgName: json['pg_name'] as String? ?? '',
      pgContactPhone: json['pg_contact_phone'] as String?,
      personId: json['person_id'] as String? ?? '',
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String? ?? '',
      photoFileId: json['photo_file_id'] as String?,
      hasSignedIn: json['has_signed_in'] as bool? ?? false,
      stayStatus: json['stay_status'] as String? ?? 'active',
      joinDate: json['join_date'] as String? ?? '',
      leaveDate: json['leave_date'] as String?,
      billingDay: (json['billing_day'] as num?)?.toInt() ?? 1,
      bedId: json['bed_id'] as String?,
      bedLabel: json['bed_label'] as String?,
      roomId: json['room_id'] as String?,
      roomNumber: json['room_number'] as String?,
      monthlyRentPaise: (json['monthly_rent_paise'] as num?)?.toInt(),
      chargedPaise: (json['charged_paise'] as num?)?.toInt() ?? 0,
      paidPaise: (json['paid_paise'] as num?)?.toInt() ?? 0,
      outstandingPaise: (json['outstanding_paise'] as num?)?.toInt() ?? 0,
      overduePaise: (json['overdue_paise'] as num?)?.toInt() ?? 0,
      creditPaise: (json['credit_paise'] as num?)?.toInt() ?? 0,
      pendingVerificationPaise: (json['pending_verification_paise'] as num?)?.toInt() ?? 0,
      oldestUnpaidDueDate: json['oldest_unpaid_due_date'] as String?,
      dueNowPaise: (json['due_now_paise'] as num?)?.toInt(),
      nextDueDate: json['next_due_date'] as String?,
      nextDuePaise: (json['next_due_paise'] as num?)?.toInt(),
      attentionState: json['attention_state'] as String? ?? 'paid',
    );
  }
}

