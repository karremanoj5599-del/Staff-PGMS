import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../providers/theme_provider.dart';
import 'app_button.dart';

class ConnectionProblemView extends StatefulWidget {
  final String? serverUrl;
  final String? customTitle;
  final String? customMessage;
  final String? errorDetail;
  final Future<void> Function()? onRetry;
  final VoidCallback? onDismiss;
  final bool isFullScreen;

  const ConnectionProblemView({
    super.key,
    this.serverUrl,
    this.customTitle,
    this.customMessage,
    this.errorDetail,
    this.onRetry,
    this.onDismiss,
    this.isFullScreen = true,
  });

  /// Convenient helper to display as a full modal bottom sheet
  static Future<void> showModal(
    BuildContext context, {
    String? serverUrl,
    String? errorDetail,
    Future<void> Function()? onRetry,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.85,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: ConnectionProblemView(
            serverUrl: serverUrl,
            errorDetail: errorDetail,
            onRetry: onRetry,
            onDismiss: () => Navigator.of(ctx).pop(),
            isFullScreen: false,
          ),
        ),
      ),
    );
  }

  @override
  State<ConnectionProblemView> createState() => _ConnectionProblemViewState();
}

class _ConnectionProblemViewState extends State<ConnectionProblemView> {
  bool _isRetrying = false;
  String? _feedbackMessage;
  bool _isSuccess = false;

  Future<void> _handleRetry() async {
    if (widget.onRetry == null) return;
    setState(() {
      _isRetrying = true;
      _feedbackMessage = null;
    });

    try {
      await widget.onRetry!();
      if (mounted) {
        setState(() {
          _isSuccess = true;
          _feedbackMessage = 'Connected successfully!';
        });
        await Future.delayed(const Duration(milliseconds: 700));
        if (mounted && widget.onDismiss != null) {
          widget.onDismiss!();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSuccess = false;
          _feedbackMessage = 'Still unable to connect. Please check the steps below.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isRetrying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final colors = theme.resolvedColors(context);
    final resolvedUrl = widget.serverUrl ?? ApiConfig.baseUrl;

    final content = SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Glowing Warning Icon
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red.withAlpha(25),
                        ),
                      ),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red.withAlpha(45),
                          border: Border.all(color: Colors.red.withAlpha(120), width: 1.5),
                        ),
                        child: const Icon(
                          Icons.cloud_off_rounded,
                          size: 38,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  widget.customTitle ?? 'Connection Problem',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22 * theme.uiScale,
                    fontWeight: FontWeight.w800,
                    color: colors.text,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  widget.customMessage ??
                      'The app is unable to reach the PGMS backend server. Please review the details below.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14 * theme.uiScale,
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Server Details Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.dns_rounded, size: 16, color: colors.accent),
                          const SizedBox(width: 8),
                          Text(
                            'Target Server',
                            style: TextStyle(
                              fontSize: 12 * theme.uiScale,
                              fontWeight: FontWeight.bold,
                              color: colors.textMuted,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: colors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colors.cardBorder),
                        ),
                        child: Text(
                          resolvedUrl,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12 * theme.uiScale,
                            color: colors.text,
                          ),
                        ),
                      ),
                      if (widget.errorDetail != null && widget.errorDetail!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline, size: 15, color: Color(0xFFEF4444)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                widget.errorDetail!,
                                style: TextStyle(
                                  fontSize: 12 * theme.uiScale,
                                  color: const Color(0xFFEF4444),
                                  fontWeight: FontWeight.w500,
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

                // Troubleshooting Tips Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How to resolve this:',
                        style: TextStyle(
                          fontSize: 13 * theme.uiScale,
                          fontWeight: FontWeight.bold,
                          color: colors.text,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildTip(
                        icon: Icons.wifi,
                        text: 'Ensure your phone has active Wi-Fi or mobile data.',
                        colors: colors,
                        theme: theme,
                      ),
                      const SizedBox(height: 8),
                      _buildTip(
                        icon: Icons.usb,
                        text: 'If testing over USB, run `adb reverse tcp:5000 tcp:5000` on your PC.',
                        colors: colors,
                        theme: theme,
                      ),
                      const SizedBox(height: 8),
                      _buildTip(
                        icon: Icons.storage_rounded,
                        text: 'Ensure the PGMS backend (`npm run dev`) is running on port 5000.',
                        colors: colors,
                        theme: theme,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Dynamic feedback message
                if (_feedbackMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: (_isSuccess ? Colors.green : Colors.red).withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: (_isSuccess ? Colors.green : Colors.red).withAlpha(100),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isSuccess ? Icons.check_circle : Icons.error_outline,
                          size: 18,
                          color: _isSuccess ? Colors.green : const Color(0xFFEF4444),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _feedbackMessage!,
                            style: TextStyle(
                              fontSize: 12 * theme.uiScale,
                              fontWeight: FontWeight.w600,
                              color: _isSuccess ? Colors.green : const Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Action Buttons
                if (widget.onRetry != null)
                  AppButton(
                    text: _isRetrying ? 'Checking Connection...' : 'Retry Connection',
                    isLoading: _isRetrying,
                    onPressed: _handleRetry,
                  ),

                if (widget.onDismiss != null) ...[
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: widget.onDismiss,
                    child: Text(
                      'Back to Login',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 14 * theme.uiScale,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.isFullScreen) {
      return Scaffold(
        backgroundColor: colors.background,
        appBar: widget.onDismiss != null
            ? AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: colors.text),
                  onPressed: widget.onDismiss,
                ),
              )
            : null,
        body: content,
      );
    }

    return Container(
      color: colors.background,
      child: content,
    );
  }

  Widget _buildTip({
    required IconData icon,
    required String text,
    required dynamic colors,
    required ThemeProvider theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: colors.accent),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12 * theme.uiScale,
              color: colors.textSecondary,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
