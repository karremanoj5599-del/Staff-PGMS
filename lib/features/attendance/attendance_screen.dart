import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../models/attendance.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import '../../utils/ist_date_utils.dart';
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
    if (user == null) {
      setState(() => _actionLoading = false);
      return;
    }

    double? lat;
    double? lng;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 5),
            ),
          );
          lat = position.latitude;
          lng = position.longitude;
        }
      }
    } catch (e) {
      debugPrint('Location lookup error: $e');
    }

    final result = await _apiService.clockInWithLocationOrQr(
      staffId: user.id,
      adminUserId: user.adminUserId,
      latitude: lat,
      longitude: lng,
    );

    if (mounted) {
      setState(() => _actionLoading = false);

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clocked In successfully on campus!')),
        );
        _fetchAttendance();
      } else {
        // Geofence or location error: offer reception QR scanning
        _showClockInFallbackDialog(result.error ?? 'Geofence verification failed.');
      }
    }
  }

  void _showClockInFallbackDialog(String errorMsg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_off, color: Colors.orange),
            SizedBox(width: 8),
            Text('On-Site Verification'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(errorMsg),
            const SizedBox(height: 12),
            const Text(
              'If GPS signal is weak, you can scan the Reception Desk QR code to verify your presence.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              _openReceptionQrScanner();
            },
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan Reception QR'),
          ),
        ],
      ),
    );
  }

  void _openReceptionQrScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (ctx) {
        bool scanned = false;
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Stack(
            children: [
              MobileScanner(
                onDetect: (capture) async {
                  if (scanned) return;
                  final barcodes = capture.barcodes;
                  for (final b in barcodes) {
                    final code = b.rawValue;
                    if (code != null && code.isNotEmpty) {
                      scanned = true;
                      Navigator.of(ctx).pop();
                      _clockInWithQr(code);
                      break;
                    }
                  }
                },
              ),
              Positioned(
                top: 40,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Scan Reception Desk QR',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _clockInWithQr(String qrCode) async {
    setState(() => _actionLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    final result = await _apiService.clockInWithLocationOrQr(
      staffId: user!.id,
      adminUserId: user.adminUserId,
      qrCode: qrCode,
    );

    if (mounted) {
      setState(() => _actionLoading = false);
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reception QR verified! Clocked in successfully.')),
        );
        _fetchAttendance();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? 'Invalid QR code')),
        );
      }
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
                        displayDate = ISTDateUtils.formatISTDate(record.date, 'EEE, dd MMM yyyy');
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
