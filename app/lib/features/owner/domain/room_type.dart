class RoomType {
  final int id;
  final String code;
  final String label;

  const RoomType({
    required this.id,
    required this.code,
    required this.label,
  });

  factory RoomType.fromJson(Map<String, dynamic> json) {
    return RoomType(
      id: json['id'] as int,
      code: json['code'] as String,
      label: json['label'] as String,
    );
  }
}

