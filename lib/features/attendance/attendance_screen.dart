import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/attendance.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/status_badge.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final ApiService _apiService = ApiService();
  List<AttendanceRecord> _records = [];
  bool _loading = true;
  bool _actionLoading = false;
  final Set<int> _expandedRecordIds = {};

  @override
  void initState() {
    super.initState();
    _fetchAttendance();
  }

  Future<void> _fetchAttendance() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    final list = await _apiService.getAttendance(user.id, user.adminUserId);
    if (mounted) {
      setState(() {
        _records = list;
        _loading = false;
      });
    }
  }

  Future<void> _clockIn() async {
    setState(() => _actionLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    final success = await _apiService.clockIn(user!.id, user.adminUserId);

    if (mounted) {
      setState(() => _actionLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Clocked In successfully!' : 'Failed to clock in'),
        ),
      );
      _fetchAttendance();
    }
  }

  Future<void> _clockOut() async {
    setState(() => _actionLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    final success = await _apiService.clockOut(user!.id, user.adminUserId);

    if (mounted) {
      setState(() => _actionLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Clocked Out successfully!' : 'Failed to clock out'),
        ),
      );
      _fetchAttendance();
    }
  }

  void _toggleExpanded(int id) {
    setState(() {
      if (_expandedRecordIds.contains(id)) {
        _expandedRecordIds.remove(id);
      } else {
        _expandedRecordIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final colors = theme.resolvedColors(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('Attendance & Gate Logs')),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: colors.accent))
          : RefreshIndicator(
              color: colors.accent,
              onRefresh: _fetchAttendance,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Punch & Shift Logs',
                        style: TextStyle(
                          fontSize: 20 * theme.uiScale,
                          fontWeight: FontWeight.bold,
                          color: colors.text,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.accent.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Biometric Synced',
                          style: TextStyle(
                            fontSize: 11 * theme.uiScale,
                            color: colors.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons: Clock In & Clock Out
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: 'Clock In',
                          variant: AppButtonVariant.success,
                          icon: Icons.login_rounded,
                          isLoading: _actionLoading,
                          onPressed: _clockIn,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          text: 'Clock Out',
                          variant: AppButtonVariant.danger,
                          icon: Icons.logout_rounded,
                          isLoading: _actionLoading,
                          onPressed: _clockOut,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (_records.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Text(
                          'No attendance records found.',
                          style: TextStyle(
                            fontSize: 16 * theme.uiScale,
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                    )
                  else
                    ..._records.map((record) {
                      final isExpanded = _expandedRecordIds.contains(record.id);

                      String displayDate = record.date;
                      try {
                        final dt = DateTime.parse(record.date);
                        displayDate = DateFormat('EEE, dd MMM yyyy').format(dt);
                      } catch (_) {}

                      return AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayDate,
                                      style: TextStyle(
                                        fontSize: 16 * theme.uiScale,
                                        fontWeight: FontWeight.bold,
                                        color: colors.text,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        if (record.punches.isNotEmpty)
                                          Container(
                                            margin: const EdgeInsets.only(right: 6),
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: colors.cardBorder,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '${record.punches.length} ${record.punches.length == 1 ? "Punch" : "Punches"}',
                                              style: TextStyle(
                                                fontSize: 11 * theme.uiScale,
                                                color: colors.textSecondary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        if (record.isLate)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: colors.danger.withAlpha(25),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'Late Check-in',
                                              style: TextStyle(
                                                fontSize: 11 * theme.uiScale,
                                                color: colors.danger,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                StatusBadge(status: record.status),
                              ],
                            ),

                            if (record.status.toLowerCase() == 'present') ...[
                              const SizedBox(height: 12),
                              Divider(color: colors.separator),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        'First In',
                                        style: TextStyle(
                                          fontSize: 12 * theme.uiScale,
                                          color: colors.textMuted,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        record.checkInTime ?? '--:--',
                                        style: TextStyle(
                                          fontSize: 15 * theme.uiScale,
                                          fontWeight: FontWeight.w600,
                                          color: colors.text,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(height: 24, width: 1, color: colors.separator),
                                  Column(
                                    children: [
                                      Text(
                                        'Last Out',
                                        style: TextStyle(
                                          fontSize: 12 * theme.uiScale,
                                          color: colors.textMuted,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        record.checkOutTime ?? '--:--',
                                        style: TextStyle(
                                          fontSize: 15 * theme.uiScale,
                                          fontWeight: FontWeight.w600,
                                          color: colors.text,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],

                            // Punch Logs Details Section
                            if (record.punches.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              InkWell(
                                onTap: () => _toggleExpanded(record.id),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        isExpanded ? 'Hide Gate Logs' : 'View Punch Details (${record.punches.length})',
                                        style: TextStyle(
                                          fontSize: 13 * theme.uiScale,
                                          color: colors.accent,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Icon(
                                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                        color: colors.accent,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              if (isExpanded) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: colors.background,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: colors.cardBorder),
                                  ),
                                  child: Column(
                                    children: record.punches.map((punch) {
                                      final isIn = punch.direction.toLowerCase() == 'in';
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 6),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: isIn
                                                    ? colors.success.withAlpha(30)
                                                    : colors.warning.withAlpha(30),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                isIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                                color: isIn ? colors.success : colors.warning,
                                                size: 16,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(
                                                        punch.formattedTime.isNotEmpty
                                                            ? punch.formattedTime
                                                            : punch.punchTime,
                                                        style: TextStyle(
                                                          fontSize: 13 * theme.uiScale,
                                                          fontWeight: FontWeight.bold,
                                                          color: colors.text,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                        decoration: BoxDecoration(
                                                          color: colors.cardBorder,
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: Text(
                                                          punch.verifyType,
                                                          style: TextStyle(
                                                            fontSize: 10 * theme.uiScale,
                                                            color: colors.textSecondary,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    punch.deviceName,
                                                    style: TextStyle(
                                                      fontSize: 11 * theme.uiScale,
                                                      color: colors.textMuted,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: isIn
                                                    ? colors.success.withAlpha(20)
                                                    : colors.warning.withAlpha(20),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                punch.direction.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 11 * theme.uiScale,
                                                  fontWeight: FontWeight.bold,
                                                  color: isIn ? colors.success : colors.warning,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
