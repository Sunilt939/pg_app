import 'package:flutter/foundation.dart';

@immutable
class PaymentFeedItem {
  final String paymentId;
  final String stayId;
  final String? pgId;
  final String? personId;
  final String? fullName;
  final String? phone;
  final String? roomNumber;
  final String? bedLabel;
  final int amountPaise;
  final String paidOn;
  final String status; // 'pending' | 'confirmed' | 'rejected' | 'reversed'
  final String? statusReason;
  final String? note;
  final String methodCode; // 'cash' | 'upi' | 'bank' | 'cheque'
  final String methodLabel;
  final String? accountNickname;
  final String? receivedAccountId;
  final String? payerAppCode;
  final String? payerAppLabel;
  final String? payerPhone;
  final String? utr;
  final String? screenshotFileId;
  final bool reportedByGuest;
  final String? createdAt;
  final String? confirmedAt;
  final String? receiptId;
  final int? receiptNo;

  const PaymentFeedItem({
    required this.paymentId,
    required this.stayId,
    this.pgId,
    this.personId,
    this.fullName,
    this.phone,
    this.roomNumber,
    this.bedLabel,
    this.amountPaise = 0,
    required this.paidOn,
    required this.status,
    this.statusReason,
    this.note,
    this.methodCode = 'cash',
    this.methodLabel = 'Cash',
    this.accountNickname,
    this.receivedAccountId,
    this.payerAppCode,
    this.payerAppLabel,
    this.payerPhone,
    this.utr,
    this.screenshotFileId,
    this.reportedByGuest = false,
    this.createdAt,
    this.confirmedAt,
    this.receiptId,
    this.receiptNo,
  });

  factory PaymentFeedItem.fromJson(Map<String, dynamic> json) {
    return PaymentFeedItem(
      paymentId: json['payment_id'] as String? ?? json['id'] as String? ?? '',
      stayId: json['stay_id'] as String? ?? '',
      pgId: json['pg_id'] as String?,
      personId: json['person_id'] as String?,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      roomNumber: json['room_number'] as String?,
      bedLabel: json['bed_label'] as String?,
      amountPaise: (json['amount_paise'] as num?)?.toInt() ?? 0,
      paidOn: json['paid_on'] as String? ?? '',
      status: json['status'] as String? ?? 'confirmed',
      statusReason: json['status_reason'] as String?,
      note: json['note'] as String?,
      methodCode: json['method_code'] as String? ?? 'cash',
      methodLabel: json['method_label'] as String? ?? 'Cash',
      accountNickname: json['account_nickname'] as String?,
      receivedAccountId: json['received_account_id'] as String?,
      payerAppCode: json['payer_app_code'] as String?,
      payerAppLabel: json['payer_app_label'] as String?,
      payerPhone: json['payer_phone'] as String?,
      utr: json['utr'] as String?,
      screenshotFileId: json['screenshot_file_id'] as String?,
      reportedByGuest: json['reported_by_guest'] as bool? ?? false,
      createdAt: json['created_at'] as String?,
      confirmedAt: json['confirmed_at'] as String?,
      receiptId: json['receipt_id'] as String?,
      receiptNo: (json['receipt_no'] as num?)?.toInt(),
    );
  }
}

