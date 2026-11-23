import 'package:flutter/foundation.dart';

@immutable
class ReceiptAllocation {
  final String description;
  final int amountPaise;

  const ReceiptAllocation({
    required this.description,
    required this.amountPaise,
  });

  factory ReceiptAllocation.fromJson(Map<String, dynamic> json) {
    return ReceiptAllocation(
      description: json['description'] as String? ?? '',
      amountPaise: (json['amount_paise'] as num?)?.toInt() ?? 0,
    );
  }
}

@immutable
class ReceiptDetail {
  final String receiptId;
  final int receiptNo;
  final DateTime issuedAt;
  final String paymentId;
  final String stayId;
  final String pgId;
  final String pgName;
  final String? pgContactPhone;
  final String? pgAddressLine1;
  final String? pgArea;
  final String? pgCity;
  final String guestName;
  final String guestPhone;
  final String? roomNumber;
  final String? bedLabel;
  final int amountPaise;
  final DateTime paidOn;
  final String status;
  final String? statusReason;
  final String methodCode;
  final String methodLabel;
  final String? payerAppLabel;
  final String? utr;
  final List<ReceiptAllocation> allocations;
  final int unallocatedPaise;

  const ReceiptDetail({
    required this.receiptId,
    required this.receiptNo,
    required this.issuedAt,
    required this.paymentId,
    required this.stayId,
    required this.pgId,
    required this.pgName,
    this.pgContactPhone,
    this.pgAddressLine1,
    this.pgArea,
    this.pgCity,
    required this.guestName,
    required this.guestPhone,
    this.roomNumber,
    this.bedLabel,
    required this.amountPaise,
    required this.paidOn,
    required this.status,
    this.statusReason,
    required this.methodCode,
    required this.methodLabel,
    this.payerAppLabel,
    this.utr,
    required this.allocations,
    required this.unallocatedPaise,
  });

  factory ReceiptDetail.fromJson(Map<String, dynamic> json) {
    final rawAllocations = json['allocations'];
    final List<ReceiptAllocation> allocList = [];
    if (rawAllocations is List) {
      for (final item in rawAllocations) {
        if (item is Map<String, dynamic>) {
          allocList.add(ReceiptAllocation.fromJson(item));
        }
      }
    }

    return ReceiptDetail(
      receiptId: json['receipt_id'] as String,
      receiptNo: (json['receipt_no'] as num).toInt(),
      issuedAt: DateTime.parse(json['issued_at'] as String),
      paymentId: json['payment_id'] as String,
      stayId: json['stay_id'] as String,
      pgId: json['pg_id'] as String,
      pgName: json['pg_name'] as String,
      pgContactPhone: json['pg_contact_phone'] as String?,
      pgAddressLine1: json['pg_address_line1'] as String?,
      pgArea: json['pg_area'] as String?,
      pgCity: json['pg_city'] as String?,
      guestName: json['guest_name'] as String,
      guestPhone: json['guest_phone'] as String,
      roomNumber: json['room_number'] as String?,
      bedLabel: json['bed_label'] as String?,
      amountPaise: (json['amount_paise'] as num).toInt(),
      paidOn: DateTime.parse(json['paid_on'] as String),
      status: json['status'] as String,
      statusReason: json['status_reason'] as String?,
      methodCode: json['method_code'] as String,
      methodLabel: json['method_label'] as String,
      payerAppLabel: json['payer_app_label'] as String?,
      utr: json['utr'] as String?,
      allocations: allocList,
      unallocatedPaise: (json['unallocated_paise'] as num?)?.toInt() ?? 0,
    );
  }
}

