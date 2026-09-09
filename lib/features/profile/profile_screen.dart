import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/theme_settings_modal.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  bool _isAvailable = false;
  String _tradeType = 'unassigned';
  bool _loading = true;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    if (user != null) {
      final profile = await _apiService.getStaffProfile(user.id, user.adminUserId);
      if (mounted) {
        setState(() {
          _isAvailable = profile?['is_available'] ?? true;
          _tradeType = profile?['trade_type'] ?? 'unassigned';
          _loading = false;
        });
      }
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleAvailability(bool val) async {
    setState(() {
      _isAvailable = val;
      _updating = true;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;

    await _apiService.updateAvailability(user!.id, user.adminUserId, val);

    if (mounted) {
      setState(() => _updating = false);
    }
  }

  void _showUpdatePinModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _UpdatePinModal(),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.of(ctx).pop();
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final colors = theme.resolvedColors(context);
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    if (_loading) {
      return Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(title: const Text('Profile')),
        body: Center(child: CircularProgressIndicator(color: colors.accent)),
      );
    }

    final initial = (user?.name.isNotEmpty == true) ? user!.name[0].toUpperCase() : 'S';

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            CircleAvatar(
              radius: 40,
              backgroundColor: colors.accent,
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 32 * theme.uiScale,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Name
            Text(
              user?.name ?? 'Staff User',
              style: TextStyle(
                fontSize: 22 * theme.uiScale,
                fontWeight: FontWeight.bold,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 4),

            // Email
            Text(
              user?.email ?? 'staff@pgms.com',
              style: TextStyle(
                fontSize: 14 * theme.uiScale,
                color: colors.textMuted,
              ),
            ),
            const SizedBox(height: 8),

            // Trade Type Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: colors.accent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _tradeType.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Divider(color: colors.separator),
            const SizedBox(height: 12),

            // Availability Switch
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available for Tickets',
                        style: TextStyle(
                          fontSize: 16 * theme.uiScale,
                          fontWeight: FontWeight.w600,
                          color: colors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Toggle to receive new assignments',
                        style: TextStyle(
                          fontSize: 13 * theme.uiScale,
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_updating)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: colors.accent),
                  )
                else
                  Switch(
                    value: _isAvailable,
                    activeThumbColor: colors.accent,
                    onChanged: _toggleAvailability,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: colors.separator),
            const SizedBox(height: 24),

            // Theme Settings Button
            AppButton(
              text: 'Theme & Display Settings',
              variant: AppButtonVariant.outline,
              width: double.infinity,
              icon: Icons.palette_outlined,
              onPressed: () => ThemeSettingsModal.show(context),
            ),
            const SizedBox(height: 14),

            // Update Security PIN Button
            AppButton(
              text: 'Update Security PIN',
              variant: AppButtonVariant.outline,
              width: double.infinity,
              icon: Icons.lock_outline,
              onPressed: _showUpdatePinModal,
            ),
            const SizedBox(height: 24),

            // Log Out Button
            AppButton(
              text: 'Log Out',
              variant: AppButtonVariant.danger,
              width: double.infinity,
              icon: Icons.logout,
              onPressed: _confirmLogout,
            ),
          ],
        ),
      ),
    );
  }
}

class _UpdatePinModal extends StatefulWidget {
  const _UpdatePinModal();

  @override
  State<_UpdatePinModal> createState() => _UpdatePinModalState();
}

class _UpdatePinModalState extends State<_UpdatePinModal> {
  final _oldPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _pinUpdating = false;

  @override
  void dispose() {
    _oldPinController.dispose();
    _newPinController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdatePin() async {
    final oldPin = _oldPinController.text.trim();
    final newPin = _newPinController.text.trim();

    if (oldPin.isEmpty || newPin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both current and new PIN')),
      );
      return;
    }

    setState(() => _pinUpdating = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;

    final result = await _apiService.updatePin(
      user!.id,
      user.adminUserId,
      oldPin,
      newPin,
    );

    if (mounted) {
      setState(() => _pinUpdating = false);
      if (result.success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.data ?? 'Security PIN updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? 'Failed to update PIN')),
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
              'Update Security PIN',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20 * theme.uiScale,
                fontWeight: FontWeight.bold,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 20),

            AppTextField(
              label: 'Current PIN',
              placeholder: 'Enter current PIN',
              controller: _oldPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 14),

            AppTextField(
              label: 'New PIN',
              placeholder: 'Enter new PIN',
              controller: _newPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
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
                    text: 'Update PIN',
                    isLoading: _pinUpdating,
                    onPressed: _handleUpdatePin,
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
