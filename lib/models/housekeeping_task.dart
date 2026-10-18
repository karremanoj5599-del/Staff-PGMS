class HousekeepingTask {
  final int id;
  final int? floorId;
  final String? roomNumber;
  final String areaType; // room, washroom, corridor
  final String areaName;
  final String status; // pending, cleaned, inspected
  final String? cleanerName;
  final String? cleanedAt;
  final String? inspectorName;
  final String? inspectedAt;
  final int? rating;
  final String? notes;

  HousekeepingTask({
    required this.id,
    this.floorId,
    this.roomNumber,
    required this.areaType,
    required this.areaName,
    required this.status,
    this.cleanerName,
    this.cleanedAt,
    this.inspectorName,
    this.inspectedAt,
    this.rating,
    this.notes,
  });

  factory HousekeepingTask.fromJson(Map<String, dynamic> json) {
    return HousekeepingTask(
      id: json['id'] as int? ?? 0,
      floorId: json['floor_id'] as int?,
      roomNumber: json['room_number']?.toString(),
      areaType: json['area_type']?.toString() ?? 'room',
      areaName: json['area_name']?.toString() ?? 'Area',
      status: json['status']?.toString() ?? 'pending',
      cleanerName: json['cleaner_name']?.toString(),
      cleanedAt: json['cleaned_at']?.toString(),
      inspectorName: json['inspector_name']?.toString(),
      inspectedAt: json['inspected_at']?.toString(),
      rating: json['rating'] as int?,
      notes: json['notes']?.toString(),
    );
  }
}
