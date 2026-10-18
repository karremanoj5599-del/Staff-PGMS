import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/ticket.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/status_badge.dart';

class TicketDetailScreen extends StatefulWidget {
  final int ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final ApiService _apiService = ApiService();
  Ticket? _ticket;
  bool _loading = true;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    final t = await _apiService.getTicketDetails(widget.ticketId, user?.adminUserId);
    if (mounted) {
      setState(() {
        _ticket = t;
        _loading = false;
      });
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _updating = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;

    final success = await _apiService.updateTicketStatus(
      widget.ticketId,
      newStatus,
      user?.adminUserId,
    );

    if (mounted) {
      setState(() {
        _updating = false;
        if (success && _ticket != null) {
          _ticket = _ticket!.copyWith(status: newStatus);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ticket marked as ${newStatus.replaceAll('_', ' ')}'),
        ),
      );
    }
  }

  Future<void> _callTenant(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$clean');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await Clipboard.setData(ClipboardData(text: clean));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Phone copied to clipboard: $clean')),
          );
        }
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: clean));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Phone copied to clipboard: $clean')),
        );
      }
    }
  }

  Future<void> _whatsappTenant(String phone, Ticket ticket) async {
    var clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length == 10) clean = '91$clean';
    final msg = Uri.encodeComponent(
      'Hello ${ticket.tenantName ?? "there"}, regarding your maintenance ticket #${ticket.id} (${ticket.issueCategory.toUpperCase()}): "${ticket.description.length > 50 ? "${ticket.description.substring(0, 50)}..." : ticket.description}"',
    );
    final uri = Uri.parse('https://wa.me/$clean?text=$msg');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open WhatsApp.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('WhatsApp error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final colors = theme.resolvedColors(context);

    if (_loading) {
      return Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(title: Text('Ticket #${widget.ticketId}')),
        body: Center(child: CircularProgressIndicator(color: colors.accent)),
      );
    }

    if (_ticket == null) {
      return Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(title: Text('Ticket #${widget.ticketId}')),
        body: Center(
          child: Text(
            'Ticket not found.',
            style: TextStyle(color: colors.danger, fontSize: 18 * theme.uiScale),
          ),
        ),
      );
    }

    final ticket = _ticket!;
    String formattedDate = ticket.createdAt;
    try {
      final dt = DateTime.parse(ticket.createdAt);
      formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(dt);
    } catch (_) {}

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text('Ticket #${ticket.id}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Category and Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  ticket.issueCategory.toUpperCase(),
                  style: TextStyle(
                    fontSize: 20 * theme.uiScale,
                    fontWeight: FontWeight.bold,
                    color: colors.accent,
                  ),
                ),
                StatusBadge(status: ticket.status),
              ],
            ),
            const SizedBox(height: 8),

            Text(
              'Created: $formattedDate',
              style: TextStyle(
                fontSize: 14 * theme.uiScale,
                color: colors.textMuted,
              ),
            ),
            const SizedBox(height: 20),

            // Tenant Contact Card
            if (ticket.tenantName != null || ticket.tenantMobile != null || ticket.tenantRoom != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colors.accent.withAlpha(25),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.person, color: colors.accent, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ticket.tenantName ?? 'Tenant',
                                  style: TextStyle(
                                    fontSize: 15 * theme.uiScale,
                                    fontWeight: FontWeight.bold,
                                    color: colors.text,
                                  ),
                                ),
                                if (ticket.tenantMobile != null && ticket.tenantMobile!.isNotEmpty)
                                  Text(
                                    ticket.tenantMobile!,
                                    style: TextStyle(
                                      fontSize: 12 * theme.uiScale,
                                      color: colors.textMuted,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        if (ticket.tenantRoom != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: colors.accent.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Room ${ticket.tenantRoom}${ticket.tenantBed != null ? " · Bed ${ticket.tenantBed}" : ""}',
                              style: TextStyle(
                                fontSize: 11 * theme.uiScale,
                                fontWeight: FontWeight.bold,
                                color: colors.accent,
                              ),
                            ),
                          ),
                      ],
                    ),

                    if (ticket.tenantMobile != null && ticket.tenantMobile!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _callTenant(ticket.tenantMobile!),
                              icon: const Icon(Icons.phone, size: 16),
                              label: const Text('Call'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.accent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _whatsappTenant(ticket.tenantMobile!, ticket),
                              icon: const Icon(Icons.chat, size: 16),
                              label: const Text('WhatsApp'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            Divider(color: colors.separator),
            const SizedBox(height: 16),

            // Section: Description
            Text(
              'Description',
              style: TextStyle(
                fontSize: 18 * theme.uiScale,
                fontWeight: FontWeight.bold,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              ticket.description,
              style: TextStyle(
                fontSize: 15 * theme.uiScale,
                height: 1.5,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 24),
            Divider(color: colors.separator),
            const SizedBox(height: 16),

            // Section: Actions
            Text(
              'Actions',
              style: TextStyle(
                fontSize: 18 * theme.uiScale,
                fontWeight: FontWeight.bold,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 16),

            if (ticket.status == 'pending') ...[
              AppButton(
                text: 'Start Work',
                width: double.infinity,
                isLoading: _updating,
                onPressed: () => _updateStatus('in_progress'),
              ),
              const SizedBox(height: 12),
            ],

            if (ticket.status == 'pending' || ticket.status == 'in_progress') ...[
              AppButton(
                text: 'Mark Resolved (With Proof)',
                width: double.infinity,
                variant: AppButtonVariant.success,
                isLoading: _updating,
                onPressed: () => _showResolveModal(context),
              ),
            ],
            if (ticket.status == 'resolved') ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'This ticket is already resolved.',
                    style: TextStyle(
                      fontSize: 16 * theme.uiScale,
                      color: colors.success,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showResolveModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ResolveTicketSheet(
        ticket: _ticket!,
        onResolved: (updatedTicket) {
          setState(() {
            _ticket = updatedTicket;
          });
        },
      ),
    );
  }
}

class _ResolveTicketSheet extends StatefulWidget {
  final Ticket ticket;
  final Function(Ticket) onResolved;

  const _ResolveTicketSheet({
    required this.ticket,
    required this.onResolved,
  });

  @override
  State<_ResolveTicketSheet> createState() => _ResolveTicketSheetState();
}

class _ResolveTicketSheetState extends State<_ResolveTicketSheet> {
  final ApiService _apiService = ApiService();
  final TextEditingController _sparePartsController = TextEditingController();
  final TextEditingController _materialCostController = TextEditingController();

  Uint8List? _photoBytes;
  String? _photoBase64;
  bool _submitting = false;

  @override
  void dispose() {
    _sparePartsController.dispose();
    _materialCostController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _photoBytes = bytes;
          _photoBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _submitResolution() async {
    setState(() => _submitting = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;

    final cost = double.tryParse(_materialCostController.text.trim());

    final res = await _apiService.resolveTicketWithProof(
      ticketId: widget.ticket.id,
      adminUserId: user?.adminUserId,
      completionPhotoBase64: _photoBase64,
      spareParts: _sparePartsController.text.trim(),
      materialCost: cost,
    );

    if (mounted) {
      setState(() => _submitting = false);
      if (res.success) {
        final updated = widget.ticket.copyWith(status: 'resolved');
        widget.onResolved(updated);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket resolved and completion proof recorded!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.error ?? 'Failed to resolve ticket')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final colors = theme.resolvedColors(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Resolve Ticket #${widget.ticket.id}',
                  style: TextStyle(
                    fontSize: 18 * theme.uiScale,
                    fontWeight: FontWeight.bold,
                    color: colors.text,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Text(
              'Attach repair completion photo & record spare parts/costs',
              style: TextStyle(fontSize: 13 * theme.uiScale, color: colors.textMuted),
            ),
            const SizedBox(height: 16),

            // Photo Evidence Section
            Text(
              'Repair Completion Photo *',
              style: TextStyle(fontSize: 14 * theme.uiScale, fontWeight: FontWeight.bold, color: colors.text),
            ),
            const SizedBox(height: 8),

            if (_photoBytes != null) ...[
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _photoBytes!,
                      width: double.infinity,
                      height: 160,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      radius: 16,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 16, color: Colors.white),
                        onPressed: () => setState(() {
                          _photoBytes = null;
                          _photoBase64 = null;
                        }),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickPhoto(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Take Photo'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickPhoto(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('From Gallery'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Spare Parts Used Field
            TextField(
              controller: _sparePartsController,
              decoration: InputDecoration(
                labelText: 'Spare Parts Used (Optional)',
                hintText: 'e.g. Replaced 0.5-inch PVC ball valve',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.build_circle_outlined),
              ),
            ),
            const SizedBox(height: 12),

            // Material Cost Field
            TextField(
              controller: _materialCostController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Material Expense ₹ (Optional)',
                hintText: 'e.g. 250',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.currency_rupee),
                helperText: 'Auto-logs as Maintenance Expense in accounts',
              ),
            ),
            const SizedBox(height: 20),

            AppButton(
              text: 'Confirm Resolution',
              width: double.infinity,
              variant: AppButtonVariant.success,
              isLoading: _submitting,
              onPressed: _submitResolution,
            ),
          ],
        ),
      ),
    );
  }
}

