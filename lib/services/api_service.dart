import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user.dart';
import '../models/ticket.dart';
import '../models/attendance.dart';
import '../models/leave.dart';
import '../models/active_visitor.dart';
import '../models/mess_forecast.dart';
import '../models/housekeeping_task.dart';
import '../models/staff_roster.dart';

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;

  ApiResponse({required this.success, this.data, this.error});
}

class ApiService {
  final String _baseUrl;

  ApiService({String? baseUrl}) : _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  static String? _authToken;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Map<String, String> _headers({String? adminUserId, String? token, String? userId}) {
    final map = <String, String>{
      'Content-Type': 'application/json',
    };
    final resolvedId = adminUserId ?? userId;
    if (resolvedId != null && resolvedId.isNotEmpty) {
      map['x-user-id'] = resolvedId;
    }
    final effectiveToken = token ?? _authToken;
    if (effectiveToken != null && effectiveToken.isNotEmpty) {
      map['Authorization'] = 'Bearer $effectiveToken';
    }
    return map;
  }

  // ─── HEALTH & CONNECTIVITY ─────────────────────────────────
  Future<ApiResponse<bool>> checkConnection() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse(success: true, data: true);
      }
      return ApiResponse(
        success: false,
        error: 'Server returned HTTP ${response.statusCode}',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Cannot reach server at $_baseUrl ($e)',
      );
    }
  }

  // ─── AUTH ──────────────────────────────────────────────────
  Future<ApiResponse<Map<String, dynamic>>> login(String mobile, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/staff/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'mobile': mobile, 'password': password}),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final userData = body['user'];
        final role = userData['role']?.toString().toLowerCase().trim() ?? '';

        if (role == 'tenant') {
          return ApiResponse(
            success: false,
            error: 'Access Denied: Tenants should log in via the Tenant app.',
          );
        }

        return ApiResponse(
          success: true,
          data: {
            'user': User.fromJson(userData),
            'token': body['token']?.toString() ?? '',
          },
        );
      } else {
        return ApiResponse(
          success: false,
          error: body['error'] ?? body['message'] ?? 'Invalid credentials',
        );
      }
    } catch (e) {
      debugPrint('Login error: $e');
      return ApiResponse(
        success: false,
        error: 'CONNECTION_ERROR: Could not connect to server at $_baseUrl. Please verify the server is running.',
      );
    }
  }

  // ─── TICKETS ───────────────────────────────────────────────
  Future<List<Ticket>> getTickets(int staffId, int? adminUserId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/admin/staff/$staffId/tickets'),
        headers: _headers(adminUserId: adminUserId?.toString()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List list = jsonDecode(response.body);
        return list.map((e) => Ticket.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Fetch tickets error: $e');
    }

    return [];
  }

  Future<Ticket?> getTicketDetails(int ticketId, int? adminUserId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/admin/tickets/$ticketId'),
        headers: _headers(adminUserId: adminUserId?.toString()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return Ticket.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('Fetch ticket details error: $e');
    }

    return null;
  }

  Future<bool> updateTicketStatus(int ticketId, String newStatus, int? adminUserId) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/admin/tickets/$ticketId'),
        headers: _headers(adminUserId: adminUserId?.toString()),
        body: jsonEncode({'status': newStatus}),
      );

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Update ticket status error: $e');
      return false;
    }
  }

  // ─── ATTENDANCE ────────────────────────────────────────────
  Future<List<AttendanceRecord>> getAttendance(int staffId, int? adminUserId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/staff/$staffId/attendance'),
        headers: _headers(adminUserId: adminUserId?.toString()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List list = jsonDecode(response.body);

        // Group raw punch logs by date matching Expo app logic
        final Map<String, Map<String, dynamic>> grouped = {};

        for (final log in list) {
          if (log is! Map<String, dynamic>) continue;
          final punchTimeStr = log['punch_time']?.toString();
          if (punchTimeStr == null || punchTimeStr.isEmpty) continue;
          final dt = DateTime.tryParse(punchTimeStr);
          if (dt == null) continue;

          final dateStr = dt.toIso8601String().split('T')[0];
          final punchLog = PunchLog.fromJson(log);

          if (!grouped.containsKey(dateStr)) {
            grouped[dateStr] = {
              'id': log['log_id'] ?? log['id'] ?? dateStr.hashCode,
              'date': dateStr,
              'status': 'present',
              '_first': dt,
              '_last': dt,
              'is_late': log['is_late'] == true,
              'punches': <PunchLog>[punchLog],
            };
          } else {
            final g = grouped[dateStr]!;
            final first = g['_first'] as DateTime;
            final last = g['_last'] as DateTime;
            if (dt.isBefore(first)) g['_first'] = dt;
            if (dt.isAfter(last)) g['_last'] = dt;
            if (log['is_late'] == true) g['is_late'] = true;
            (g['punches'] as List<PunchLog>).add(punchLog);
          }
        }

        String formatTime(DateTime d) {
          final hour = d.hour == 0 ? 12 : (d.hour > 12 ? d.hour - 12 : d.hour);
          final minute = d.minute.toString().padLeft(2, '0');
          final ampm = d.hour >= 12 ? 'PM' : 'AM';
          return '${hour.toString().padLeft(2, '0')}:$minute $ampm';
        }

        final formatted = grouped.values.map((g) {
          final first = g['_first'] as DateTime;
          final last = g['_last'] as DateTime;
          final punches = (g['punches'] as List<PunchLog>);
          punches.sort((a, b) => b.punchTime.compareTo(a.punchTime));

          return AttendanceRecord(
            id: g['id'] as int,
            date: g['date'] as String,
            status: g['status'] as String,
            checkInTime: formatTime(first),
            checkOutTime: first != last ? formatTime(last) : null,
            punches: punches,
            isLate: g['is_late'] == true,
          );
        }).toList();

        formatted.sort((a, b) => b.date.compareTo(a.date));
        return formatted;
      }
    } catch (e) {
      debugPrint('Fetch attendance error: $e');
    }

    return [];
  }

  Future<bool> clockIn(int staffId, int? adminUserId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/staff/$staffId/attendance/clock-in'),
        headers: _headers(adminUserId: adminUserId?.toString()),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Clock in error: $e');
      return false;
    }
  }

  Future<bool> clockOut(int staffId, int? adminUserId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/staff/$staffId/attendance/clock-out'),
        headers: _headers(adminUserId: adminUserId?.toString()),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Clock out error: $e');
      return false;
    }
  }

  // ─── LEAVES ────────────────────────────────────────────────
  Future<List<LeaveRecord>> getLeaves(int staffId, int? adminUserId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/staff/$staffId/leaves'),
        headers: _headers(adminUserId: adminUserId?.toString()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List list = jsonDecode(response.body);
        return list.map((e) => LeaveRecord.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Fetch leaves error: $e');
    }
    return [];
  }

  Future<bool> requestLeave(
    int staffId,
    int? adminUserId,
    String startDate,
    String endDate,
    String reason,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/staff/$staffId/leave'),
        headers: _headers(adminUserId: adminUserId?.toString()),
        body: jsonEncode({
          'start_date': startDate,
          'end_date': endDate,
          'reason': reason,
        }),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Request leave error: $e');
      return false;
    }
  }

  // ─── PROFILE & SETTINGS ────────────────────────────────────
  Future<Map<String, dynamic>?> getStaffProfile(int staffId, int? adminUserId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/staff/$staffId'),
        headers: _headers(adminUserId: adminUserId?.toString()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Get staff profile error: $e');
    }
    return {
      'is_available': true,
      'trade_type': 'unassigned',
    };
  }

  Future<bool> updateAvailability(int staffId, int? adminUserId, bool isAvailable) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/staff/$staffId/availability'),
        headers: _headers(adminUserId: adminUserId?.toString()),
        body: jsonEncode({'is_available': isAvailable}),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Update availability error: $e');
      return true; // optimistic
    }
  }

  Future<ApiResponse<String>> updatePin(
    int staffId,
    int? adminUserId,
    String oldPin,
    String newPin,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/staff/$staffId/update-pin'),
        headers: _headers(adminUserId: adminUserId?.toString()),
        body: jsonEncode({'oldPin': oldPin, 'newPin': newPin}),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse(
          success: true,
          data: body['message'] ?? 'Security PIN updated successfully',
        );
      } else {
        return ApiResponse(
          success: false,
          error: body['error'] ?? 'Failed to update Security PIN',
        );
      }
    } catch (e) {
      debugPrint('Update PIN error: $e');
      return ApiResponse(success: false, error: 'An error occurred while updating the PIN');
    }
  }

  // ─── VISITOR SCAN ──────────────────────────────────────────
  Future<Map<String, dynamic>> scanVisitor({
    required int staffId,
    required String token,
    required String passCode,
    required String action,
    required String staffName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/staff/visitors/scan'),
        headers: {
          'Content-Type': 'application/json',
          'x-user-id': staffId.toString(),
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'pass_code': passCode,
          'action': action,
          'staff_name': staffName,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('Visitor scan error: $e');
      return {'success': false, 'error': 'Failed to connect to the server'};
    }
  }

  // ─── GEOFENCE & CLOCK-IN ────────────────────────────────────
  Future<Map<String, dynamic>?> getPropertyGeofence(int staffId, int? adminUserId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/staff/$staffId/geofence'),
        headers: _headers(adminUserId: adminUserId?.toString()),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Get geofence error: $e');
    }
    return null;
  }

  Future<ApiResponse<bool>> clockInWithLocationOrQr({
    required int staffId,
    int? adminUserId,
    double? latitude,
    double? longitude,
    String? qrCode,
  }) async {
    try {
      final payload = <String, dynamic>{};
        if (latitude != null) payload['latitude'] = latitude;
        if (longitude != null) payload['longitude'] = longitude;
        if (qrCode != null) payload['qr_code'] = qrCode;

        final response = await http.post(
          Uri.parse('$_baseUrl/staff/$staffId/attendance/clock-in'),
          headers: _headers(adminUserId: adminUserId?.toString()),
          body: jsonEncode(payload),
        );

      final body = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse(success: true, data: true);
      }
      return ApiResponse(
        success: false,
        error: body['error'] ?? body['message'] ?? 'Failed to clock in',
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  // ─── TICKET RESOLUTION WITH PROOF ──────────────────────────
  Future<ApiResponse<bool>> resolveTicketWithProof({
    required int ticketId,
    int? adminUserId,
    String? completionPhotoBase64,
    String? spareParts,
    double? materialCost,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (completionPhotoBase64 != null) payload['completion_photo'] = completionPhotoBase64;
      if (spareParts != null && spareParts.isNotEmpty) payload['spare_parts'] = spareParts;
      if (materialCost != null && materialCost > 0) payload['material_cost'] = materialCost;

      final response = await http.post(
        Uri.parse('$_baseUrl/staff/tickets/$ticketId/resolve'),
        headers: _headers(adminUserId: adminUserId?.toString()),
        body: jsonEncode(payload),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse(success: true, data: true);
      }
      return ApiResponse(
        success: false,
        error: body['error'] ?? 'Failed to resolve ticket',
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  // ─── DELIVERY FAST-PASS & WALK-IN ─────────────────────────
  Future<ApiResponse<Map<String, dynamic>>> issueDeliveryPass({
    required String deliveryPartner,
    required String roomNumber,
    int? packageCount,
    required String staffName,
    int? adminUserId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/staff/visitors/delivery-pass'),
        headers: _headers(adminUserId: adminUserId?.toString()),
        body: jsonEncode({
          'delivery_partner': deliveryPartner,
          'room_number': roomNumber,
          'package_count': packageCount ?? 1,
          'staff_name': staffName,
        }),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse(success: true, data: body);
      }
      return ApiResponse(
        success: false,
        error: body['error'] ?? 'Failed to issue delivery pass',
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> registerWalkInVisitor({
    required String name,
    required String phone,
    String? purpose,
    String? roomNumber,
    required String staffName,
    int? adminUserId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/staff/visitors/walk-in'),
        headers: _headers(adminUserId: adminUserId?.toString()),
        body: jsonEncode({
          'name': name,
          'phone': phone,
          'purpose': purpose,
          'room_number': roomNumber,
          'staff_name': staffName,
        }),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse(success: true, data: body);
      }
      return ApiResponse(
        success: false,
        error: body['error'] ?? 'Failed to register walk-in visitor',
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  Future<List<ActiveVisitor>> getActiveVisitors(int? adminUserId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/staff/visitors/active'),
        headers: _headers(adminUserId: adminUserId?.toString()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List list = jsonDecode(response.body);
        return list.map((e) => ActiveVisitor.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Get active visitors error: $e');
    }
    return [];
  }

  Future<bool> markVisitorExit(int visitorId, String staffName, int? adminUserId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/staff/visitors/$visitorId/mark-exit'),
        headers: _headers(adminUserId: adminUserId?.toString()),
        body: jsonEncode({'staff_name': staffName}),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Mark visitor exit error: $e');
      return false;
    }
  }

  // ─── MESS FORECAST & DINING PASS ───────────────────────────
  Future<MessForecast?> getMessForecast(int? adminUserId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/staff/mess/forecast'),
        headers: _headers(adminUserId: adminUserId?.toString()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return MessForecast.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('Get mess forecast error: $e');
    }
    return null;
  }

  Future<ApiResponse<Map<String, dynamic>>> scanMessDiningPass(
    String qrData,
    String staffName,
    int? adminUserId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/staff/mess/scan'),
        headers: _headers(adminUserId: adminUserId?.toString()),
        body: jsonEncode({'qr_data': qrData, 'staff_name': staffName}),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse(success: true, data: body);
      }
      return ApiResponse(
        success: false,
        error: body['error'] ?? 'Meal verification failed',
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  // ─── HOUSEKEEPING CHECKLIST ────────────────────────────────
  Future<List<HousekeepingTask>> getHousekeepingChecklist(int? adminUserId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/staff/housekeeping/today'),
        headers: _headers(adminUserId: adminUserId?.toString()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List list = jsonDecode(response.body);
        return list.map((e) => HousekeepingTask.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Get housekeeping checklist error: $e');
    }
    return [];
  }

  Future<bool> checkHousekeepingArea(
    int taskId,
    String cleanerName,
    String? notes,
    int? adminUserId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/staff/housekeeping/check'),
        headers: _headers(adminUserId: adminUserId?.toString()),
        body: jsonEncode({
          'task_id': taskId,
          'cleaner_name': cleanerName,
          'notes': notes,
        }),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Check housekeeping error: $e');
      return false;
    }
  }

  Future<bool> signOffHousekeeping(
    int taskId,
    String inspectorName,
    int rating,
    String? notes,
    int? adminUserId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/staff/housekeeping/sign-off'),
        headers: _headers(adminUserId: adminUserId?.toString()),
        body: jsonEncode({
          'task_id': taskId,
          'inspector_name': inspectorName,
          'rating': rating,
          'notes': notes,
        }),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Sign off housekeeping error: $e');
      return false;
    }
  }

  // ─── ROSTER ────────────────────────────────────────────────
  Future<StaffRoster?> getStaffRoster(int staffId, int? adminUserId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/staff/$staffId/roster'),
        headers: _headers(adminUserId: adminUserId?.toString()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return StaffRoster.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('Get staff roster error: $e');
    }
    return null;
  }
}

