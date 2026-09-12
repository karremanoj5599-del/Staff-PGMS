class PunchLog {
  final int logId;
  final String punchTime;
  final String formattedTime;
  final String direction; // 'In' or 'Out'
  final String deviceName;
  final String? deviceSn;
  final String verifyType;
  final bool isLate;

  PunchLog({
    required this.logId,
    required this.punchTime,
    required this.formattedTime,
    required this.direction,
    required this.deviceName,
    this.deviceSn,
    required this.verifyType,
    this.isLate = false,
  });

  factory PunchLog.fromJson(Map<String, dynamic> json) {
    String verifyName = 'Biometric';
    final vt = json['verify_type'];
    if (vt == 15 || vt == '15' || vt == 'app') {
      verifyName = 'Mobile App';
    } else if (vt == 1 || vt == '1' || vt == 'finger') {
      verifyName = 'Fingerprint';
    } else if (vt == 2 || vt == '2' || vt == 'face') {
      verifyName = 'Face AI';
    } else if (vt == 4 || vt == '4' || vt == 'card') {
      verifyName = 'RFID Card';
    }

    final isCheckIn = json['status'] == 0 || json['status'] == '0' || json['direction'] == 'In';
    return PunchLog(
      logId: json['log_id'] is int ? json['log_id'] : int.tryParse(json['log_id']?.toString() ?? '') ?? 0,
      punchTime: json['punch_time']?.toString() ?? '',
      formattedTime: json['formatted_time']?.toString() ?? '',
      direction: isCheckIn ? 'In' : 'Out',
      deviceName: json['device_name']?.toString() ?? json['device_sn']?.toString() ?? 'Gate Terminal',
      deviceSn: json['device_sn']?.toString(),
      verifyType: verifyName,
      isLate: json['is_late'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'log_id': logId,
      'punch_time': punchTime,
      'formatted_time': formattedTime,
      'direction': direction,
      'device_name': deviceName,
      if (deviceSn != null) 'device_sn': deviceSn,
      'verify_type': verifyType,
      'is_late': isLate,
    };
  }
}

class AttendanceRecord {
  final int id;
  final String date;
  final String status;
  final String? checkInTime;
  final String? checkOutTime;
  final List<PunchLog> punches;
  final int totalPunches;
  final bool isLate;

  AttendanceRecord({
    required this.id,
    required this.date,
    required this.status,
    this.checkInTime,
    this.checkOutTime,
    this.punches = const [],
    int? totalPunches,
    this.isLate = false,
  }) : totalPunches = totalPunches ?? punches.length;

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    final rawPunches = json['punches'] is List ? (json['punches'] as List) : [];
    final punchList = rawPunches
        .whereType<Map<String, dynamic>>()
        .map((p) => PunchLog.fromJson(p))
        .toList();

    return AttendanceRecord(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      date: json['date']?.toString() ?? '',
      status: json['status']?.toString() ?? 'present',
      checkInTime: json['check_in_time']?.toString(),
      checkOutTime: json['check_out_time']?.toString(),
      punches: punchList,
      totalPunches: json['total_punches'] is int
          ? json['total_punches']
          : (int.tryParse(json['total_punches']?.toString() ?? '') ?? punchList.length),
      isLate: json['is_late'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'status': status,
      if (checkInTime != null) 'check_in_time': checkInTime,
      if (checkOutTime != null) 'check_out_time': checkOutTime,
      'total_punches': totalPunches,
      'is_late': isLate,
      'punches': punches.map((p) => p.toJson()).toList(),
    };
  }
}
