import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
                text: 'Mark Resolved',
                width: double.infinity,
                variant: AppButtonVariant.success,
                isLoading: _updating,
                onPressed: () => _updateStatus('resolved'),
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
}
