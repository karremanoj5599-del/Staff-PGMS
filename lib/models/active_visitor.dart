class ActiveVisitor {
  final int id;
  final String name;
  final String? phone;
  final String? purpose;
  final String passCode;
  final String visitorType;
  final String? entryTime;
  final String? entryStaffName;
  final String? tenantName;
  final String? tenantMobile;
  final String? roomNumber;
  final int durationMinutes;
  final String durationFormatted;
  final bool isOverstay;

  ActiveVisitor({
    required this.id,
    required this.name,
    this.phone,
    this.purpose,
    required this.passCode,
    required this.visitorType,
    this.entryTime,
    this.entryStaffName,
    this.tenantName,
    this.tenantMobile,
    this.roomNumber,
    required this.durationMinutes,
    required this.durationFormatted,
    required this.isOverstay,
  });

  factory ActiveVisitor.fromJson(Map<String, dynamic> json) {
    return ActiveVisitor(
      id: json['id'] as int? ?? 0,
      name: json['name']?.toString() ?? 'Visitor',
      phone: json['phone']?.toString(),
      purpose: json['purpose']?.toString(),
      passCode: json['pass_code']?.toString() ?? '',
      visitorType: json['visitor_type']?.toString() ?? 'visitor',
      entryTime: json['entry_time']?.toString(),
      entryStaffName: json['entry_staff_name']?.toString(),
      tenantName: json['tenant_name']?.toString(),
      tenantMobile: json['tenant_mobile']?.toString(),
      roomNumber: json['room_number']?.toString(),
      durationMinutes: json['duration_minutes'] as int? ?? 0,
      durationFormatted: json['duration_formatted']?.toString() ?? '0m',
      isOverstay: json['is_overstay'] == true,
    );
  }
}
