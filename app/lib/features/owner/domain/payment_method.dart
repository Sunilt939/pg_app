import 'package:flutter/foundation.dart';

@immutable
class PaymentMethod {
  final int id;
  final String code;
  final String label;
  final bool isActive;

  const PaymentMethod({
    required this.id,
    required this.code,
    required this.label,
    this.isActive = true,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as int,
      code: json['code'] as String,
      label: json['label'] as String,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

