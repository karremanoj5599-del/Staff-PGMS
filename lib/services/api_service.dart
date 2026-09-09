import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user.dart';
import '../models/ticket.dart';
import '../models/attendance.dart';
import '../models/leave.dart';

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;

  ApiResponse({required this.success, this.data, this.error});
}

class ApiService {
  final String _baseUrl;

  ApiService({String? baseUrl}) : _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  Map<String, String> _headers({String? adminUserId, String? token, String? userId}) {
    final map = <String, String>{
      'Content-Type': 'application/json',
    };
    if (adminUserId != null && adminUserId.isNotEmpty) {
      map['x-user-id'] = adminUserId;
    } else if (userId != null && userId.isNotEmpty) {
      map['x-user-id'] = userId;
    }
    if (token != null && token.isNotEmpty) {
      map['Authorization'] = 'Bearer $token';
    }
    return map;
  }

  // ─── AUTH ──────────────────────────────────────────────────
  Future<ApiResponse<Map<String, dynamic>>> login(String mobile, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/staff/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile': mobile, 'password': password}),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final userData = body['user'];
        final role = userData['role']?.toString() ?? '';
        final allowedRoles = ['staff', 'admin', 'Cleaning', 'Security', 'Cook'];

        if (!allowedRoles.contains(role)) {
          return ApiResponse(
            success: false,
            error: 'Access Denied: Only staff members can use this app.',
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
      return ApiResponse(success: false, error: 'Failed to connect to the server');
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

    // Mock fallback matching existing Expo app
    return [
      Ticket(
        id: 1,
        tenantId: 101,
        issueCategory: 'plumbing',
        description: 'Leaking pipe under sink',
        status: 'pending',
        createdAt: '2026-07-10T10:00:00Z',
      ),
      Ticket(
        id: 2,
        tenantId: 102,
        issueCategory: 'electrical',
        description: 'Lights not working in living room',
        status: 'in_progress',
        createdAt: '2026-07-11T14:30:00Z',
      ),
    ];
  }

  Future<Ticket?> getTicketDetails(int ticketId, int? adminUserId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/admin/tickets/$ticketId'),
        headers: {'Authorization': 'Bearer ${adminUserId ?? ''}'},
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return Ticket.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('Fetch ticket details error: $e');
    }

    // Mock fallback
    return Ticket(
      id: ticketId,
      tenantId: 101,
      issueCategory: 'plumbing',
      description: 'Leaking pipe under sink. Needs urgent attention as water is spilling everywhere.',
      status: 'pending',
      createdAt: '2026-07-10T10:00:00Z',
    );
  }

  Future<bool> updateTicketStatus(int ticketId, String newStatus, int? adminUserId) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/admin/tickets/$ticketId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${adminUserId ?? ''}',
        },
        body: jsonEncode({'status': newStatus}),
      );

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Update ticket status error: $e');
      return true; // Mock fallback
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
          final punchTimeStr = log['punch_time']?.toString();
          if (punchTimeStr == null || punchTimeStr.isEmpty) continue;
          final dt = DateTime.tryParse(punchTimeStr);
          if (dt == null) continue;

          final dateStr = dt.toIso8601String().split('T')[0];

          if (!grouped.containsKey(dateStr)) {
            grouped[dateStr] = {
              'id': log['log_id'] ?? log['id'] ?? dateStr.hashCode,
              'date': dateStr,
              'status': 'present',
              '_first': dt,
              '_last': dt,
            };
          } else {
            final g = grouped[dateStr]!;
            final first = g['_first'] as DateTime;
            final last = g['_last'] as DateTime;
            if (dt.isBefore(first)) g['_first'] = dt;
            if (dt.isAfter(last)) g['_last'] = dt;
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
          return AttendanceRecord(
            id: g['id'] as int,
            date: g['date'] as String,
            status: g['status'] as String,
            checkInTime: formatTime(first),
            checkOutTime: first != last ? formatTime(last) : null,
          );
        }).toList();

        formatted.sort((a, b) => b.date.compareTo(a.date));
        return formatted;
      }
    } catch (e) {
      debugPrint('Fetch attendance error: $e');
    }

    // Mock fallback
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    return [
      AttendanceRecord(
        id: 1,
        date: today.toIso8601String().split('T')[0],
        status: 'present',
        checkInTime: '09:00 AM',
        checkOutTime: '05:00 PM',
      ),
      AttendanceRecord(
        id: 2,
        date: yesterday.toIso8601String().split('T')[0],
        status: 'present',
        checkInTime: '08:55 AM',
        checkOutTime: '05:10 PM',
      ),
      AttendanceRecord(
        id: 3,
        date: '2026-07-10',
        status: 'leave',
      ),
    ];
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
}
