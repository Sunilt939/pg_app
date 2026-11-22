class ChargeType {
  final int id;
  final String code;
  final String label;
  final bool isRefundable;
  final bool isRecurring;
  final bool isActive;

  const ChargeType({
    required this.id,
    required this.code,
    required this.label,
    this.isRefundable = false,
    this.isRecurring = false,
    this.isActive = true,
  });

  factory ChargeType.fromJson(Map<String, dynamic> json) {
    return ChargeType(
      id: json['id'] as int,
      code: json['code'] as String,
      label: json['label'] as String,
      isRefundable: json['is_refundable'] as bool? ?? false,
      isRecurring: json['is_recurring'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

