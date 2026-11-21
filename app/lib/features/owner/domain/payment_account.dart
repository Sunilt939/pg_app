import 'package:flutter/foundation.dart';

@immutable
class PaymentAccount {
  final String id;
  final String pgId;
  final String nickname;
  final String kind; // 'upi' | 'bank'
  final String? upiVpa;
  final String? bankName;
  final String? accountLast4;
  final String? holderName;
  final String? linkedPhone;
  final bool isDefault;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PaymentAccount({
    required this.id,
    required this.pgId,
    required this.nickname,
    required this.kind,
    this.upiVpa,
    this.bankName,
    this.accountLast4,
    this.holderName,
    this.linkedPhone,
    this.isDefault = false,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory PaymentAccount.fromJson(Map<String, dynamic> json) {
    return PaymentAccount(
      id: json['id'] as String,
      pgId: json['pg_id'] as String,
      nickname: json['nickname'] as String,
      kind: json['kind'] as String,
      upiVpa: json['upi_vpa'] as String?,
      bankName: json['bank_name'] as String?,
      accountLast4: json['account_last4'] as String?,
      holderName: json['holder_name'] as String?,
      linkedPhone: json['linked_phone'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pg_id': pgId,
      'nickname': nickname,
      'kind': kind,
      if (upiVpa != null) 'upi_vpa': upiVpa,
      if (bankName != null) 'bank_name': bankName,
      if (accountLast4 != null) 'account_last4': accountLast4,
      if (holderName != null) 'holder_name': holderName,
      if (linkedPhone != null) 'linked_phone': linkedPhone,
      'is_default': isDefault,
      'is_active': isActive,
    };
  }

  PaymentAccount copyWith({
    String? id,
    String? pgId,
    String? nickname,
    String? kind,
    String? upiVpa,
    String? bankName,
    String? accountLast4,
    String? holderName,
    String? linkedPhone,
    bool? isDefault,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentAccount(
      id: id ?? this.id,
      pgId: pgId ?? this.pgId,
      nickname: nickname ?? this.nickname,
      kind: kind ?? this.kind,
      upiVpa: upiVpa ?? this.upiVpa,
      bankName: bankName ?? this.bankName,
      accountLast4: accountLast4 ?? this.accountLast4,
      holderName: holderName ?? this.holderName,
      linkedPhone: linkedPhone ?? this.linkedPhone,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentAccount &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          pgId == other.pgId &&
          nickname == other.nickname &&
          kind == other.kind &&
          upiVpa == other.upiVpa &&
          bankName == other.bankName &&
          accountLast4 == other.accountLast4 &&
          holderName == other.holderName &&
          linkedPhone == other.linkedPhone &&
          isDefault == other.isDefault &&
          isActive == other.isActive;

  @override
  int get hashCode =>
      id.hashCode ^
      pgId.hashCode ^
      nickname.hashCode ^
      kind.hashCode ^
      upiVpa.hashCode ^
      bankName.hashCode ^
      accountLast4.hashCode ^
      holderName.hashCode ^
      linkedPhone.hashCode ^
      isDefault.hashCode ^
      isActive.hashCode;
}

