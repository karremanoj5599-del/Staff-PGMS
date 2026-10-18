class ShiftDay {
  final String day;
  final String shift;
  final String status;

  ShiftDay({
    required this.day,
    required this.shift,
    required this.status,
  });

  factory ShiftDay.fromJson(Map<String, dynamic> json) {
    return ShiftDay(
      day: json['day']?.toString() ?? '',
      shift: json['shift']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Working',
    );
  }
}

class StaffRoster {
  final int staffId;
  final String name;
  final String tradeType;
  final String shiftStartTime;
  final String shiftEndTime;
  final int shiftGraceMinutes;
  final String weeklyOffDay;
  final bool isAvailable;
  final List<ShiftDay> shifts;

  StaffRoster({
    required this.staffId,
    required this.name,
    required this.tradeType,
    required this.shiftStartTime,
    required this.shiftEndTime,
    required this.shiftGraceMinutes,
    required this.weeklyOffDay,
    required this.isAvailable,
    required this.shifts,
  });

  factory StaffRoster.fromJson(Map<String, dynamic> json) {
    final list = json['shifts'] as List? ?? [];
    return StaffRoster(
      staffId: json['staff_id'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
      tradeType: json['trade_type']?.toString() ?? 'Operations',
      shiftStartTime: json['shift_start_time']?.toString() ?? '09:00:00',
      shiftEndTime: json['shift_end_time']?.toString() ?? '18:00:00',
      shiftGraceMinutes: json['shift_grace_minutes'] as int? ?? 15,
      weeklyOffDay: json['weekly_off_day']?.toString() ?? 'Sunday',
      isAvailable: json['is_available'] == true,
      shifts: list.map((e) => ShiftDay.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
