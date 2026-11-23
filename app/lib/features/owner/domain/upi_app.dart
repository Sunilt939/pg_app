import 'package:flutter/foundation.dart';

@immutable
class UpiApp {
  final int id;
  final String code;
  final String label;

  const UpiApp({
    required this.id,
    required this.code,
    required this.label,
  });

  factory UpiApp.fromJson(Map<String, dynamic> json) {
    return UpiApp(
      id: json['id'] as int,
      code: json['code'] as String,
      label: json['label'] as String,
    );
  }
}

