import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/active_visitor.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/app_button.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MobileScannerController _scannerController = MobileScannerController();
  final TextEditingController _manualController = TextEditingController();
  final ApiService _apiService = ApiService();

  // Scanner state
  bool _scanned = false;
  String? _scannedData;
  bool _loading = false;

  // Delivery Pass state
  String _selectedPartner = 'Swiggy';
  final TextEditingController _deliveryRoomController = TextEditingController();
  int _deliveryPackageCount = 1;
  bool _issuingDelivery = false;

  // Walk-In state
  final TextEditingController _walkInNameController = TextEditingController();
  final TextEditingController _walkInPhoneController = TextEditingController();
  final TextEditingController _walkInPurposeController = TextEditingController();
  final TextEditingController _walkInRoomController = TextEditingController();
  bool _registeringWalkIn = false;

  // Active visitors state
  List<ActiveVisitor> _activeVisitors = [];
  bool _loadingVisitors = false;

  final List<String> _partners = [
    'Swiggy',
    'Zomato',
    'Amazon',
    'Flipkart',
    'Blinkit',
    'Zepto',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 3) {
        _fetchActiveVisitors();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scannerController.dispose();
    _manualController.dispose();
    _deliveryRoomController.dispose();
    _walkInNameController.dispose();
    _walkInPhoneController.dispose();
    _walkInPurposeController.dispose();
    _walkInRoomController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final code = barcode.rawValue;
      if (code != null && code.isNotEmpty) {
        setState(() {
          _scanned = true;
          _scannedData = code;
        });
        break;
      }
    }
  }

  Future<void> _processScan(String action) async {
    if (_scannedData == null) return;
    setState(() => _loading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    final token = auth.token ?? '';

    final result = await _apiService.scanVisitor(
      staffId: user!.id,
      token: token,
      passCode: _scannedData!,
      action: action,
      staffName: user.name,
    );

    if (mounted) {
      setState(() => _loading = false);

      if (result['success'] == true) {
        final visitor = result['visitor'] ?? {};
        final visitorName = visitor['name'] ?? 'Visitor';
        final tenantName = visitor['tenant_name'];
        final tenantStr = (tenantName != null && tenantName != 'Unknown')
            ? '\nResident: $tenantName'
            : '';

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(action == 'entry' ? 'Marked Entry' : 'Marked Exit'),
            content: Text('$visitorName$tenantStr\nPass: ${_scannedData!}'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  setState(() {
                    _scanned = false;
                    _scannedData = null;
                  });
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Scan Failed'),
            content: Text(result['error'] ?? 'Invalid QR code'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  setState(() {
                    _scanned = false;
                    _scannedData = null;
                  });
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _handleIssueDeliveryPass() async {
    final room = _deliveryRoomController.text.trim();
    if (room.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter tenant room number')),
      );
      return;
    }

    setState(() => _issuingDelivery = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;

    final res = await _apiService.issueDeliveryPass(
      deliveryPartner: _selectedPartner,
      roomNumber: room,
      packageCount: _deliveryPackageCount,
      staffName: user?.name ?? 'Guard',
      adminUserId: user?.adminUserId,
    );

    if (mounted) {
      setState(() => _issuingDelivery = false);
      if (res.success) {
        final passCode = res.data?['pass_code'] ?? 'DEL';
        final tenant = res.data?['tenant'];
        final tenantStr = tenant != null ? 'for ${tenant['name']}' : '';

        _deliveryRoomController.clear();
        _deliveryPackageCount = 1;

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Delivery Pass Issued'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Partner: $_selectedPartner'),
                Text('Destination: Room $room $tenantStr'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pass Code: $passCode',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Chip(label: Text('20-Min Pass', style: TextStyle(fontSize: 11))),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.error ?? 'Failed to issue delivery pass')),
        );
      }
    }
  }

  Future<void> _handleRegisterWalkIn() async {
    final name = _walkInNameController.text.trim();
    final phone = _walkInPhoneController.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and phone number are required')),
      );
      return;
    }

    setState(() => _registeringWalkIn = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;

    final res = await _apiService.registerWalkInVisitor(
      name: name,
      phone: phone,
      purpose: _walkInPurposeController.text.trim(),
      roomNumber: _walkInRoomController.text.trim(),
      staffName: user?.name ?? 'Guard',
      adminUserId: user?.adminUserId,
    );

    if (mounted) {
      setState(() => _registeringWalkIn = false);
      if (res.success) {
        final passCode = res.data?['pass_code'] ?? 'WLK';
        _walkInNameController.clear();
        _walkInPhoneController.clear();
        _walkInPurposeController.clear();
        _walkInRoomController.clear();

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Walk-In Visitor Checked In'),
            content: Text('Pass $passCode issued for $name.\nVisitor marked as Entered.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.error ?? 'Failed to register walk-in visitor')),
        );
      }
    }
  }

  Future<void> _fetchActiveVisitors() async {
    setState(() => _loadingVisitors = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;

    final list = await _apiService.getActiveVisitors(user?.adminUserId);
    if (mounted) {
      setState(() {
        _activeVisitors = list;
        _loadingVisitors = false;
      });
    }
  }

  Future<void> _markExit(ActiveVisitor visitor) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;

    final success = await _apiService.markVisitorExit(
      visitor.id,
      user?.name ?? 'Staff',
      user?.adminUserId,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${visitor.name} marked as Exited')),
        );
        _fetchActiveVisitors();
      }
    }
  }

  Future<void> _callTenant(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final colors = theme.resolvedColors(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Gate Operations & Passes'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: colors.accent,
          unselectedLabelColor: colors.textMuted,
          indicatorColor: colors.accent,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'Scan Pass'),
            Tab(icon: Icon(Icons.delivery_dining), text: 'Delivery Pass'),
            Tab(icon: Icon(Icons.person_add_alt_1), text: 'Walk-In KYC'),
            Tab(icon: Icon(Icons.people_outline), text: 'Active & Overstay'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ─── TAB 1: PASS SCANNER ─────────────────────────────
          _buildScannerTab(colors, theme),

          // ─── TAB 2: DELIVERY FAST-PASS ───────────────────────
          _buildDeliveryTab(colors, theme),

          // ─── TAB 3: WALK-IN REGISTRATION ─────────────────────
          _buildWalkInTab(colors, theme),

          // ─── TAB 4: ACTIVE VISITORS & OVERSTAY ALERTS ────────
          _buildActiveVisitorsTab(colors, theme),
        ],
      ),
    );
  }

  Widget _buildScannerTab(dynamic colors, ThemeProvider theme) {
    return Stack(
      children: [
        if (!_scanned)
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),

        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white70, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Icon(Icons.qr_code, size: 80, color: Colors.white54),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Point camera at Visitor QR Pass",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),

        // Manual pass code input at bottom
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 10),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _manualController,
                    decoration: const InputDecoration(
                      hintText: 'Enter Pass Code manually',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final code = _manualController.text.trim();
                    if (code.isNotEmpty) {
                      setState(() {
                        _scanned = true;
                        _scannedData = code;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: colors.accent),
                  child: const Text('Verify'),
                ),
              ],
            ),
          ),
        ),

        if (_loading)
          Container(
            color: Colors.black54,
            child: const Center(child: CircularProgressIndicator(color: Colors.white)),
          ),

        // Scanned Action Prompt Sheet
        if (_scanned && !_loading && _scannedData != null)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Pass Detected: $_scannedData', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _processScan('entry'),
                          icon: const Icon(Icons.login),
                          label: const Text('Mark Entry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _processScan('exit'),
                          icon: const Icon(Icons.logout),
                          label: const Text('Mark Exit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => setState(() {
                      _scanned = false;
                      _scannedData = null;
                    }),
                    child: const Text('Cancel & Scan Another'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDeliveryTab(dynamic colors, ThemeProvider theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Fast-Pass Generator',
            style: TextStyle(fontSize: 18 * theme.uiScale, fontWeight: FontWeight.bold, color: colors.text),
          ),
          Text(
            'Rapid check-in for food and e-commerce delivery agents (20-min temporary pass)',
            style: TextStyle(fontSize: 13 * theme.uiScale, color: colors.textMuted),
          ),
          const SizedBox(height: 20),

          Text('Select Delivery Partner:', style: TextStyle(fontWeight: FontWeight.bold, color: colors.text)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _partners.map((p) {
              final selected = _selectedPartner == p;
              return ChoiceChip(
                label: Text(p),
                selected: selected,
                selectedColor: colors.accent,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : colors.text,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (val) {
                  if (val) setState(() => _selectedPartner = p);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _deliveryRoomController,
            decoration: InputDecoration(
              labelText: 'Destination Room Number *',
              hintText: 'e.g. 104',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              prefixIcon: const Icon(Icons.meeting_room_outlined),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Packages Count:', style: TextStyle(fontWeight: FontWeight.bold, color: colors.text)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: _deliveryPackageCount > 1
                        ? () => setState(() => _deliveryPackageCount--)
                        : null,
                  ),
                  Text('$_deliveryPackageCount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => setState(() => _deliveryPackageCount++),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          AppButton(
            text: 'Issue 20-Min Delivery Pass',
            width: double.infinity,
            isLoading: _issuingDelivery,
            onPressed: _handleIssueDeliveryPass,
          ),
        ],
      ),
    );
  }

  Widget _buildWalkInTab(dynamic colors, ThemeProvider theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Walk-In Visitor Registration',
            style: TextStyle(fontSize: 18 * theme.uiScale, fontWeight: FontWeight.bold, color: colors.text),
          ),
          Text(
            'On-spot KYC registration for guests arriving without a pre-invite',
            style: TextStyle(fontSize: 13 * theme.uiScale, color: colors.textMuted),
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _walkInNameController,
            decoration: InputDecoration(
              labelText: 'Visitor Full Name *',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              prefixIcon: const Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 14),

          TextField(
            controller: _walkInPhoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Mobile Number *',
              hintText: '10-digit number',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              prefixIcon: const Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 14),

          TextField(
            controller: _walkInRoomController,
            decoration: InputDecoration(
              labelText: 'Visiting Room Number (Optional)',
              hintText: 'e.g. 202',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              prefixIcon: const Icon(Icons.meeting_room_outlined),
            ),
          ),
          const SizedBox(height: 14),

          TextField(
            controller: _walkInPurposeController,
            decoration: InputDecoration(
              labelText: 'Purpose of Visit',
              hintText: 'e.g. Friend visit, Project discussion',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              prefixIcon: const Icon(Icons.info_outline),
            ),
          ),
          const SizedBox(height: 24),

          AppButton(
            text: 'Check-In Visitor Now',
            width: double.infinity,
            variant: AppButtonVariant.primary,
            isLoading: _registeringWalkIn,
            onPressed: _handleRegisterWalkIn,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveVisitorsTab(dynamic colors, ThemeProvider theme) {
    final overstayCount = _activeVisitors.where((v) => v.isOverstay).length;

    return RefreshIndicator(
      onRefresh: _fetchActiveVisitors,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (overstayCount > 0) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade400, width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$overstayCount Visitor(s) Overstaying (>8h)',
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const Text(
                          'Check with host resident or confirm exit at reception.',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Visitors on Campus (${_activeVisitors.length})',
                style: TextStyle(fontSize: 16 * theme.uiScale, fontWeight: FontWeight.bold, color: colors.text),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _fetchActiveVisitors,
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_loadingVisitors)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (_activeVisitors.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline, size: 48, color: colors.textMuted),
                    const SizedBox(height: 12),
                    Text('No active visitors on campus right now', style: TextStyle(color: colors.textMuted)),
                  ],
                ),
              ),
            )
          else
            ..._activeVisitors.map((v) {
              return Card(
                color: colors.card,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: v.isOverstay
                      ? BorderSide(color: Colors.red.shade400, width: 1.5)
                      : BorderSide.none,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              v.name,
                              style: TextStyle(fontSize: 16 * theme.uiScale, fontWeight: FontWeight.bold, color: colors.text),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: v.isOverstay ? Colors.red.withAlpha(25) : Colors.blue.withAlpha(25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              v.durationFormatted + (v.isOverstay ? ' · OVERSTAY' : ''),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: v.isOverstay ? Colors.red : Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        v.purpose ?? 'Visiting',
                        style: TextStyle(fontSize: 13 * theme.uiScale, color: colors.textMuted),
                      ),
                      if (v.tenantName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Host Resident: ${v.tenantName} (${v.roomNumber != null ? "Room ${v.roomNumber!}" : ""})',
                          style: TextStyle(fontSize: 12 * theme.uiScale, fontWeight: FontWeight.w500, color: colors.accent),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (v.tenantMobile != null && v.tenantMobile!.isNotEmpty) ...[
                            OutlinedButton.icon(
                              onPressed: () => _callTenant(v.tenantMobile!),
                              icon: const Icon(Icons.phone, size: 14),
                              label: const Text('Call Host'),
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: () => _markExit(v),
                            icon: const Icon(Icons.logout, size: 14),
                            label: const Text('Mark Exit'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
