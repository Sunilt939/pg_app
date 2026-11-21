import '../../../core/utils/natural_sort.dart';

class BedOccupancy {
  final String bedId;
  final String bedLabel;
  final bool bedIsActive;
  final String roomId;
  final String pgId;
  final String roomNumber;
  final int? floor;
  final bool roomIsActive;
  final String? roomTypeCode;
  final String? roomTypeLabel;
  final String? stayId;
  final String? occupantPersonId;
  final String? occupantName;
  final String? occupantPhone;

  const BedOccupancy({
    required this.bedId,
    required this.bedLabel,
    this.bedIsActive = true,
    required this.roomId,
    required this.pgId,
    required this.roomNumber,
    this.floor,
    this.roomIsActive = true,
    this.roomTypeCode,
    this.roomTypeLabel,
    this.stayId,
    this.occupantPersonId,
    this.occupantName,
    this.occupantPhone,
  });

  bool get isOccupied => stayId != null && stayId!.isNotEmpty;
  bool get isFree => !isOccupied;

  factory BedOccupancy.fromJson(Map<String, dynamic> json) {
    return BedOccupancy(
      bedId: json['bed_id'] as String? ?? '',
      bedLabel: json['bed_label'] as String? ?? '',
      bedIsActive: json['bed_is_active'] as bool? ?? true,
      roomId: json['room_id'] as String? ?? '',
      pgId: json['pg_id'] as String? ?? '',
      roomNumber: json['room_number'] as String? ?? '',
      floor: (json['floor'] as num?)?.toInt(),
      roomIsActive: json['room_is_active'] as bool? ?? true,
      roomTypeCode: json['room_type_code'] as String?,
      roomTypeLabel: json['room_type_label'] as String?,
      stayId: json['stay_id'] as String?,
      occupantPersonId: json['occupant_person_id'] as String?,
      occupantName: json['occupant_name'] as String?,
      occupantPhone: json['occupant_phone'] as String?,
    );
  }
}

class RoomSummary {
  final String roomId;
  final String pgId;
  final String roomNumber;
  final int? floor;
  final String? roomTypeCode;
  final String? roomTypeLabel;
  final List<BedOccupancy> beds;

  const RoomSummary({
    required this.roomId,
    required this.pgId,
    required this.roomNumber,
    this.floor,
    this.roomTypeCode,
    this.roomTypeLabel,
    required this.beds,
  });

  int get totalBeds => beds.where((b) => b.bedIsActive).length;
  int get freeBeds => beds.where((b) => b.bedIsActive && b.isFree).length;
  int get occupiedBeds => beds.where((b) => b.bedIsActive && b.isOccupied).length;
  bool get isFull => freeBeds == 0;

  static List<RoomSummary> fromBedList(List<BedOccupancy> allBeds) {
    final Map<String, List<BedOccupancy>> grouped = {};
    for (final bed in allBeds) {
      grouped.putIfAbsent(bed.roomId, () => []).add(bed);
    }

    final rooms = <RoomSummary>[];
    for (final entry in grouped.entries) {
      final bedsInRoom = entry.value..sort((a, b) => naturalCompare(a.bedLabel, b.bedLabel));
      final first = bedsInRoom.first;
      rooms.add(RoomSummary(
        roomId: entry.key,
        pgId: first.pgId,
        roomNumber: first.roomNumber,
        floor: first.floor,
        roomTypeCode: first.roomTypeCode,
        roomTypeLabel: first.roomTypeLabel,
        beds: bedsInRoom,
      ));
    }

    rooms.sort((a, b) => naturalCompare(a.roomNumber, b.roomNumber));
    return rooms;
  }
}

