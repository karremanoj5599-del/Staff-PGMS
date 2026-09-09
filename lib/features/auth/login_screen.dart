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

  Future<void> _handleLogin({String? overrideMobile, String? overridePassword}) async {
    final mobile = overrideMobile ?? _mobileController.text.trim();
    final password = overridePassword ?? _passwordController.text;

    if (mobile.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your mobile number and password')),
      );
      return;
    }

    setState(() => _loading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final error = await authProvider.login(mobile, password);

    if (mounted) {
      setState(() => _loading = false);
      if (error != null) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Login Failed'),
            content: Text(error),
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

  void _handleDemoLogin() {
    _mobileController.text = '0000000000';
    _passwordController.text = 'password123';
    _handleLogin(overrideMobile: '0000000000', overridePassword: 'password123');
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
                    label: 'Password',
                    placeholder: 'Enter your password',
                    controller: _passwordController,
                    obscureText: true,
                    prefixIcon: Icon(Icons.lock, color: colors.textMuted),
                  ),
                  const SizedBox(height: 28),

                  AppButton(
                    text: 'Log In',
                    isLoading: _loading,
                    onPressed: () => _handleLogin(),
                  ),
                  const SizedBox(height: 14),

                  AppButton(
                    text: 'Demo Login',
                    variant: AppButtonVariant.outline,
                    isLoading: _loading,
                    onPressed: _handleDemoLogin,
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
