import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
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
                  const SizedBox(height: 36),

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
