class RoomSetupItem {
  final String number;
  final int? floor;
  final int beds;

  const RoomSetupItem({
    required this.number,
    this.floor,
    required this.beds,
  });

  Map<String, dynamic> toJson() => {
        'number': number,
        if (floor != null) 'floor': floor,
        'beds': beds,
      };

  factory RoomSetupItem.fromJson(Map<String, dynamic> json) => RoomSetupItem(
        number: json['number'] as String,
        floor: json['floor'] as int?,
        beds: json['beds'] as int,
      );

  RoomSetupItem copyWith({
    String? number,
    int? floor,
    int? beds,
  }) {
    return RoomSetupItem(
      number: number ?? this.number,
      floor: floor ?? this.floor,
      beds: beds ?? this.beds,
    );
  }
}

