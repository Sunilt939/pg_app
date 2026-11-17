import 'package:flutter/foundation.dart';

@immutable
class City {
  final int id;
  final String name;
  final String stateName;

  const City({
    required this.id,
    required this.name,
    required this.stateName,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    final stateMap = json['states'] as Map<String, dynamic>?;
    return City(
      id: json['id'] as int,
      name: json['name'] as String,
      stateName: stateMap?['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'states': {
        'name': stateName,
      },
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is City &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

