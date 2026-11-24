import 'package:flutter/foundation.dart';

@immutable
class PgDetails {
  final String id;
  final String name;
  final String genderPolicy; // 'men', 'women', 'any'
  final String? contactPhone;
  final String? addressId;
  final String line1;
  final String? area;
  final int cityId;
  final String cityName;
  final String stateName;
  final String? pincode;

  const PgDetails({
    required this.id,
    required this.name,
    required this.genderPolicy,
    this.contactPhone,
    this.addressId,
    required this.line1,
    this.area,
    required this.cityId,
    required this.cityName,
    required this.stateName,
    this.pincode,
  });

  String get formattedAddress {
    final parts = <String>[];
    if (line1.isNotEmpty) parts.add(line1);
    if (area != null && area!.trim().isNotEmpty) parts.add(area!.trim());
    final cityState = [cityName, stateName].where((s) => s.isNotEmpty).join(', ');
    if (pincode != null && pincode!.trim().isNotEmpty) {
      parts.add('$cityState $pincode');
    } else if (cityState.isNotEmpty) {
      parts.add(cityState);
    }
    return parts.join('\n');
  }

  PgDetails copyWith({
    String? id,
    String? name,
    String? genderPolicy,
    String? contactPhone,
    String? addressId,
    String? line1,
    String? area,
    int? cityId,
    String? cityName,
    String? stateName,
    String? pincode,
  }) {
    return PgDetails(
      id: id ?? this.id,
      name: name ?? this.name,
      genderPolicy: genderPolicy ?? this.genderPolicy,
      contactPhone: contactPhone ?? this.contactPhone,
      addressId: addressId ?? this.addressId,
      line1: line1 ?? this.line1,
      area: area ?? this.area,
      cityId: cityId ?? this.cityId,
      cityName: cityName ?? this.cityName,
      stateName: stateName ?? this.stateName,
      pincode: pincode ?? this.pincode,
    );
  }

  factory PgDetails.fromJson(Map<String, dynamic> json) {
    final addressMap = json['addresses'] as Map<String, dynamic>? ?? {};
    final citiesMap = addressMap['cities'] as Map<String, dynamic>? ?? {};
    final statesMap = citiesMap['states'] as Map<String, dynamic>? ?? {};

    return PgDetails(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      genderPolicy: json['gender_policy'] as String? ?? 'any',
      contactPhone: json['contact_phone'] as String?,
      addressId: (json['address_id'] as String?) ?? (addressMap['id'] as String?),
      line1: addressMap['line1'] as String? ?? '',
      area: addressMap['area'] as String?,
      cityId: addressMap['city_id'] as int? ?? (citiesMap['id'] as int? ?? 0),
      cityName: citiesMap['name'] as String? ?? '',
      stateName: statesMap['name'] as String? ?? '',
      pincode: addressMap['pincode'] as String?,
    );
  }
}
