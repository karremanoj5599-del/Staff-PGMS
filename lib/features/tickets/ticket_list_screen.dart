import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/ticket.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/status_badge.dart';

class TicketListScreen extends StatefulWidget {
  const TicketListScreen({super.key});

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  final ApiService _apiService = ApiService();
  List<Ticket> _tickets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  Future<void> _fetchTickets() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    final list = await _apiService.getTickets(user.id, user.adminUserId);
    if (mounted) {
      setState(() {
        _tickets = list;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final colors = theme.resolvedColors(context);

    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              user?.pgName ?? 'Tickets',
              style: TextStyle(
                fontSize: 18 * theme.uiScale,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (user?.pgName != null)
              Text(
                'Staff Portal',
                style: TextStyle(
                  fontSize: 11 * theme.uiScale,
                  color: colors.textMuted,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan Visitor Pass',
            onPressed: () => context.push('/scan'),
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: colors.accent))
          : RefreshIndicator(
              color: colors.accent,
              onRefresh: _fetchTickets,
              child: _tickets.isEmpty
                  ? Center(
                      child: Text(
                        'No tickets assigned to you.',
                        style: TextStyle(
                          fontSize: 16 * theme.uiScale,
                          color: colors.textMuted,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _tickets.length,
                      itemBuilder: (context, index) {
                        final ticket = _tickets[index];
                        return AppCard(
                          onTap: () => context.push('/ticket/${ticket.id}'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '#${ticket.id}',
                                    style: TextStyle(
                                      fontSize: 16 * theme.uiScale,
                                      fontWeight: FontWeight.bold,
                                      color: colors.text,
                                    ),
                                  ),
                                  StatusBadge(status: ticket.status),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                ticket.issueCategory.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 14 * theme.uiScale,
                                  fontWeight: FontWeight.w600,
                                  color: colors.accent,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ticket.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14 * theme.uiScale,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
