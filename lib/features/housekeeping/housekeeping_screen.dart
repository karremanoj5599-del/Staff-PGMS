import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/housekeeping_task.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';

class HousekeepingScreen extends StatefulWidget {
  const HousekeepingScreen({super.key});

  @override
  State<HousekeepingScreen> createState() => _HousekeepingScreenState();
}

class _HousekeepingScreenState extends State<HousekeepingScreen> {
  final ApiService _apiService = ApiService();
  List<HousekeepingTask> _tasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchChecklist();
  }

  Future<void> _fetchChecklist() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    final list = await _apiService.getHousekeepingChecklist(user?.adminUserId);
    if (mounted) {
      setState(() {
        _tasks = list;
        _loading = false;
      });
    }
  }

  Future<void> _markCleaned(HousekeepingTask task) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Mark ${task.areaName} Cleaned'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Notes / Remarks (Optional)',
                hintText: 'e.g. Moped, sanitised, trash cleared',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Confirm Cleaned')),
        ],
      ),
    );

    if (confirmed == true) {
      await _apiService.checkHousekeepingArea(
        task.id,
        user?.name ?? 'Housekeeping Staff',
        controller.text.trim(),
        user?.adminUserId,
      );
      _fetchChecklist();
    }
  }

  Future<void> _signOffInspection(HousekeepingTask task) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    int rating = 5;
    final notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Warden Sign-Off: ${task.areaName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Rate Cleanliness Quality:'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  return IconButton(
                    icon: Icon(
                      starIndex <= rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () => setDialogState(() => rating = starIndex),
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Inspection Remarks',
                  hintText: 'e.g. Spotless, all fixtures checked',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Sign-Off')),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await _apiService.signOffHousekeeping(
        task.id,
        user?.name ?? 'Warden',
        rating,
        notesController.text.trim(),
        user?.adminUserId,
      );
      _fetchChecklist();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final colors = theme.resolvedColors(context);

    final total = _tasks.length;
    final cleanedCount = _tasks.where((t) => t.status == 'cleaned' || t.status == 'inspected').length;
    final inspectedCount = _tasks.where((t) => t.status == 'inspected').length;
    final progress = total > 0 ? (cleanedCount / total) : 0.0;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Daily Housekeeping Checklist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchChecklist,
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: colors.accent))
          : RefreshIndicator(
              onRefresh: _fetchChecklist,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Progress Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 8),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Today's Cleaning Progress",
                              style: TextStyle(fontSize: 16 * theme.uiScale, fontWeight: FontWeight.bold, color: colors.text),
                            ),
                            Text(
                              '$cleanedCount / $total Cleaned',
                              style: TextStyle(color: colors.accent, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: colors.separator,
                            valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${(progress * 100).toInt()}% Areas Done',
                              style: TextStyle(fontSize: 12, color: colors.textMuted),
                            ),
                            Text(
                              'Inspected: $inspectedCount / $total',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Checklist by Area',
                    style: TextStyle(fontSize: 18 * theme.uiScale, fontWeight: FontWeight.bold, color: colors.text),
                  ),
                  const SizedBox(height: 12),

                  if (_tasks.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Text('No areas configured for cleaning today', style: TextStyle(color: colors.textMuted)),
                      ),
                    )
                  else
                    ..._tasks.map((task) {
                      IconData icon;
                      if (task.areaType == 'washroom') {
                        icon = Icons.bathtub_outlined;
                      } else if (task.areaType == 'corridor') {
                        icon = Icons.stairs_outlined;
                      } else {
                        icon = Icons.bed_outlined;
                      }

                      Color statusColor;
                      String statusText;
                      if (task.status == 'inspected') {
                        statusColor = Colors.green;
                        statusText = 'Inspected ★ ${task.rating ?? 5}';
                      } else if (task.status == 'cleaned') {
                        statusColor = Colors.blue;
                        statusText = 'Cleaned';
                      } else {
                        statusColor = Colors.orange;
                        statusText = 'Pending';
                      }

                      return Card(
                        color: colors.card,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: colors.accent.withAlpha(25),
                                    child: Icon(icon, color: colors.accent, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          task.areaName,
                                          style: TextStyle(
                                            fontSize: 15 * theme.uiScale,
                                            fontWeight: FontWeight.bold,
                                            color: colors.text,
                                          ),
                                        ),
                                        if (task.notes != null && task.notes!.isNotEmpty)
                                          Text(
                                            task.notes!,
                                            style: TextStyle(fontSize: 12, color: colors.textMuted),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withAlpha(25),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      statusText,
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                                    ),
                                  ),
                                ],
                              ),
                              if (task.cleanerName != null || task.inspectorName != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  '${task.cleanerName != null ? "Cleaned by: ${task.cleanerName!}" : ""}${task.inspectorName != null ? " · Inspector: ${task.inspectorName!}" : ""}',
                                  style: TextStyle(fontSize: 11, color: colors.textMuted),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (task.status == 'pending') ...[
                                    ElevatedButton.icon(
                                      onPressed: () => _markCleaned(task),
                                      icon: const Icon(Icons.check, size: 16),
                                      label: const Text('Mark Cleaned'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                  ],
                                  if (task.status == 'cleaned') ...[
                                    ElevatedButton.icon(
                                      onPressed: () => _signOffInspection(task),
                                      icon: const Icon(Icons.verified, size: 16),
                                      label: const Text('Warden Sign-Off'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
