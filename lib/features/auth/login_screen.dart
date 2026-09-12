import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/connection_problem_view.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  // Server Connectivity State
  bool? _isServerConnected;
  bool _isCheckingConnection = false;
  String? _connectionErrorDetail;

  @override
  void initState() {
    super.initState();
    _checkServerConnection();
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkServerConnection() async {
    if (!mounted) return;
    setState(() {
      _isCheckingConnection = true;
      _connectionErrorDetail = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await authProvider.apiService.checkConnection();

    if (mounted) {
      setState(() {
        _isCheckingConnection = false;
        _isServerConnected = result.success;
        if (!result.success) {
          _connectionErrorDetail = result.error;
        }
      });
    }
  }

  void _showConnectionProblem({String? customError}) {
    ConnectionProblemView.showModal(
      context,
      serverUrl: ApiConfig.baseUrl,
      errorDetail: customError ?? _connectionErrorDetail,
      onRetry: () async {
        await _checkServerConnection();
        if (_isServerConnected == false) {
          throw Exception('Still offline');
        }
      },
    );
  }

  Future<void> _handleLogin() async {
    final mobile = _mobileController.text.trim();
    final password = _passwordController.text;

    if (mobile.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your mobile number and password'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final error = await authProvider.login(mobile, password);

    if (mounted) {
      setState(() => _loading = false);
      if (error != null) {
        final isConnectionIssue = error.contains('CONNECTION_ERROR') ||
            error.contains('Failed to connect') ||
            error.contains('SocketException') ||
            error.contains('ClientException') ||
            error.contains('Failed host lookup');

        if (isConnectionIssue) {
          setState(() => _isServerConnected = false);
          _showConnectionProblem(customError: error.replaceFirst('CONNECTION_ERROR: ', ''));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Widget _buildServerStatusBadge(dynamic colors, ThemeProvider theme) {
    if (_isCheckingConnection) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.amber.withAlpha(25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amber.withAlpha(80)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber),
            ),
            const SizedBox(width: 8),
            Text(
              'Checking server connection...',
              style: TextStyle(
                fontSize: 12 * theme.uiScale,
                color: Colors.amber,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (_isServerConnected == false) {
      return InkWell(
        onTap: () => _showConnectionProblem(),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.red.withAlpha(30),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red.withAlpha(120)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Server Offline · Tap for info',
                style: TextStyle(
                  fontSize: 12 * theme.uiScale,
                  color: const Color(0xFFEF4444),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_ios, size: 10, color: Color(0xFFEF4444)),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => _showConnectionProblem(customError: 'Server is currently reachable and responding.'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.withAlpha(25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.withAlpha(80)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Server Online',
              style: TextStyle(
                fontSize: 12 * theme.uiScale,
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final colors = theme.resolvedColors(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Staff Login',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32 * theme.uiScale,
                      fontWeight: FontWeight.bold,
                      color: colors.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Property Management System',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16 * theme.uiScale,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Interactive Server Status Indicator
                  Center(
                    child: _buildServerStatusBadge(colors, theme),
                  ),
                  const SizedBox(height: 24),

                  AppTextField(
                    label: 'Mobile Number',
                    placeholder: 'Enter your mobile number',
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icon(Icons.phone, color: colors.textMuted),
                  ),
                  const SizedBox(height: 18),

                  AppTextField(
                    label: 'Password / PIN',
                    placeholder: 'Enter your password or PIN',
                    controller: _passwordController,
                    obscureText: true,
                    prefixIcon: Icon(Icons.lock, color: colors.textMuted),
                  ),
                  const SizedBox(height: 28),

                  AppButton(
                    text: 'Log In',
                    isLoading: _loading,
                    onPressed: _handleLogin,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
