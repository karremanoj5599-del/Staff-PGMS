import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../models/mess_forecast.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';

class KitchenMessScreen extends StatefulWidget {
  const KitchenMessScreen({super.key});

  @override
  State<KitchenMessScreen> createState() => _KitchenMessScreenState();
}

class _KitchenMessScreenState extends State<KitchenMessScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _manualTenantController = TextEditingController();

  MessForecast? _forecast;
  bool _loading = true;
  bool _punching = false;

  @override
  void initState() {
    super.initState();
    _fetchForecast();
  }

  @override
  void dispose() {
    _manualTenantController.dispose();
    super.dispose();
  }

  Future<void> _fetchForecast() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    final f = await _apiService.getMessForecast(user?.adminUserId);
    if (mounted) {
      setState(() {
        _forecast = f;
        _loading = false;
      });
    }
  }

  Future<void> _processMealPunch(String qrData) async {
    setState(() => _punching = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;

    final result = await _apiService.scanMessDiningPass(
      qrData,
      user?.name ?? 'Kitchen Staff',
      user?.adminUserId,
    );

    if (mounted) {
      setState(() => _punching = false);
      if (result.success) {
        final tenant = result.data?['tenant'] ?? {};
        final mealType = result.data?['meal_type']?.toString().toUpperCase() ?? 'MEAL';

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Text('$mealType Verified'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tenant['name'] ?? 'Resident',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text('Room: ${tenant['room_number'] ?? "-"} · Bed: ${tenant['bed_number'] ?? "-"}'),
                const SizedBox(height: 8),
                const Text(
                  'Meal attendance recorded. Tenant is authorized to dine.',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _fetchForecast();
                },
                child: const Text('Next Resident'),
              ),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 8),
                Text('Meal Denied'),
              ],
            ),
            content: Text(result.error ?? 'Invalid dining pass'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _openDiningScanner() {
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
                onDetect: (capture) {
                  if (scanned) return;
                  final barcodes = capture.barcodes;
                  for (final b in barcodes) {
                    final code = b.rawValue;
                    if (code != null && code.isNotEmpty) {
                      scanned = true;
                      Navigator.of(ctx).pop();
                      _processMealPunch(code);
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
                      'Scan Resident Dining Pass',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              Center(
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.greenAccent, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final colors = theme.resolvedColors(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Kitchen Mess Terminal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchForecast,
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: colors.accent))
          : RefreshIndicator(
              onRefresh: _fetchForecast,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Headcount Summary Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.teal.withAlpha(50), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_forecast?.dayOfWeek ?? "Today"} Prep Forecast',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _forecast?.date ?? '',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatItem('Active Residents', '${_forecast?.totalActiveTenants ?? 0}'),
                            _buildStatItem('Opted-Out Today', '${_forecast?.optedOutCount ?? 0}'),
                            _buildStatItem(
                              'Expected Headcount',
                              '${(_forecast?.totalActiveTenants ?? 0) - (_forecast?.optedOutCount ?? 0)}',
                              highlight: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Punch Action Button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _openDiningScanner,
                      icon: const Icon(Icons.qr_code_scanner, size: 24),
                      label: const Text('Open Resident QR Scanner', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Manual Verification input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _manualTenantController,
                          decoration: InputDecoration(
                            hintText: 'Enter Tenant Mobile or ID',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            isDense: true,
                            prefixIcon: const Icon(Icons.person_search_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _punching ? null : () {
                          final data = _manualTenantController.text.trim();
                          if (data.isNotEmpty) {
                            _processMealPunch(data);
                            _manualTenantController.clear();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _punching
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Verify'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Text(
                    "Today's Meals Breakdown",
                    style: TextStyle(fontSize: 18 * theme.uiScale, fontWeight: FontWeight.bold, color: colors.text),
                  ),
                  const SizedBox(height: 12),

                  if (_forecast != null) ...[
                    _buildMealCard('Breakfast', _forecast!.breakfast, Colors.amber.shade700, colors),
                    const SizedBox(height: 12),
                    _buildMealCard('Lunch', _forecast!.lunch, Colors.orange.shade700, colors),
                    const SizedBox(height: 12),
                    _buildMealCard('Dinner', _forecast!.dinner, Colors.indigo.shade700, colors),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStatItem(String label, String value, {bool highlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: highlight ? Colors.amberAccent : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildMealCard(String mealName, MealForecastDetail meal, Color accentColor, dynamic colors) {
    final progress = meal.forecast > 0 ? (meal.served / meal.forecast).clamp(0.0, 1.0) : 0.0;

    return Card(
      color: colors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.restaurant, color: accentColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      mealName,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.text),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${meal.served} / ${meal.forecast} Served',
                    style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Menu: ${meal.menu}',
              style: TextStyle(fontSize: 13, color: colors.textMuted),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: colors.separator,
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progress * 100).toInt()}% Complete',
                  style: TextStyle(fontSize: 11, color: colors.textMuted),
                ),
                Text(
                  '${meal.remaining} Remaining to Serve',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.text),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
