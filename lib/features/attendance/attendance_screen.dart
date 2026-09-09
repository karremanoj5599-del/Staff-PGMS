import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final colors = theme.resolvedColors(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('Attendance')),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: colors.accent))
          : RefreshIndicator(
              color: colors.accent,
              onRefresh: _fetchAttendance,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Your Attendance Record',
                    style: TextStyle(
                      fontSize: 22 * theme.uiScale,
                      fontWeight: FontWeight.bold,
                      color: colors.accent,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons: Clock In & Clock Out
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: 'Clock In',
                          variant: AppButtonVariant.success,
                          isLoading: _actionLoading,
                          onPressed: _clockIn,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          text: 'Clock Out',
                          variant: AppButtonVariant.danger,
                          isLoading: _actionLoading,
                          onPressed: _clockOut,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

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
                      return AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  record.date,
                                  style: TextStyle(
                                    fontSize: 16 * theme.uiScale,
                                    fontWeight: FontWeight.bold,
                                    color: colors.text,
                                  ),
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
                                        'Check-In',
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
                                  Column(
                                    children: [
                                      Text(
                                        'Check-Out',
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
