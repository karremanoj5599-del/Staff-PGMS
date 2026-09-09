import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/leave.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/status_badge.dart';

class LeavesScreen extends StatefulWidget {
  const LeavesScreen({super.key});

  @override
  State<LeavesScreen> createState() => _LeavesScreenState();
}

class _LeavesScreenState extends State<LeavesScreen> {
  final ApiService _apiService = ApiService();
  List<LeaveRecord> _leaves = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeaves();
  }

  Future<void> _fetchLeaves() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    final list = await _apiService.getLeaves(user.id, user.adminUserId);
    if (mounted) {
      setState(() {
        _leaves = list;
        _loading = false;
      });
    }
  }

  void _showRequestModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LeaveRequestModal(onRequestSubmitted: _fetchLeaves),
    );
  }

  String _formatDate(String str) {
    try {
      final dt = DateTime.parse(str);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return str;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final colors = theme.resolvedColors(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('Leaves')),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: colors.accent))
          : RefreshIndicator(
              color: colors.accent,
              onRefresh: _fetchLeaves,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Leave Requests',
                        style: TextStyle(
                          fontSize: 22 * theme.uiScale,
                          fontWeight: FontWeight.bold,
                          color: colors.accent,
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('New Request'),
                        onPressed: _showRequestModal,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (_leaves.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Text(
                          'No leave requests found.',
                          style: TextStyle(
                            fontSize: 16 * theme.uiScale,
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                    )
                  else
                    ..._leaves.map((leave) {
                      return AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${_formatDate(leave.startDate)} - ${_formatDate(leave.endDate)}',
                                  style: TextStyle(
                                    fontSize: 15 * theme.uiScale,
                                    fontWeight: FontWeight.bold,
                                    color: colors.text,
                                  ),
                                ),
                                StatusBadge(status: leave.status),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Reason:',
                              style: TextStyle(
                                fontSize: 12 * theme.uiScale,
                                color: colors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              leave.reason,
                              style: TextStyle(
                                fontSize: 14 * theme.uiScale,
                                color: colors.text,
                              ),
                            ),
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

class _LeaveRequestModal extends StatefulWidget {
  final VoidCallback onRequestSubmitted;

  const _LeaveRequestModal({required this.onRequestSubmitted});

  @override
  State<_LeaveRequestModal> createState() => _LeaveRequestModalState();
}

class _LeaveRequestModalState extends State<_LeaveRequestModal> {
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _reasonController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _submitting = false;

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final start = _startDateController.text.trim();
    final end = _endDateController.text.trim();
    final reason = _reasonController.text.trim();

    if (start.isEmpty || end.isEmpty || reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _submitting = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;

    final success = await _apiService.requestLeave(
      user!.id,
      user.adminUserId,
      start,
      end,
      reason,
    );

    if (mounted) {
      setState(() => _submitting = false);
      if (success) {
        Navigator.of(context).pop();
        widget.onRequestSubmitted();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Leave request submitted!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit leave request')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final colors = theme.resolvedColors(context);

    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Request Leave',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20 * theme.uiScale,
                fontWeight: FontWeight.bold,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 20),

            AppTextField(
              label: 'Start Date (YYYY-MM-DD)',
              placeholder: 'e.g. 2026-08-01',
              controller: _startDateController,
            ),
            const SizedBox(height: 14),

            AppTextField(
              label: 'End Date (YYYY-MM-DD)',
              placeholder: 'e.g. 2026-08-03',
              controller: _endDateController,
            ),
            const SizedBox(height: 14),

            AppTextField(
              label: 'Reason',
              placeholder: 'Explain why you are requesting leave',
              controller: _reasonController,
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Cancel',
                    variant: AppButtonVariant.secondary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    text: 'Submit',
                    variant: AppButtonVariant.success,
                    isLoading: _submitting,
                    onPressed: _handleSubmit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
