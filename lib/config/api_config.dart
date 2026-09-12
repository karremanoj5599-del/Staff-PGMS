import 'package:flutter/foundation.dart' show kDebugMode;

class ApiConfig {
  ApiConfig._();

  static String get baseUrl {
    const envUrl = String.fromEnvironment('API_URL', defaultValue: '');

    if (envUrl.isNotEmpty) {
      return envUrl.replaceAll(RegExp(r'/staff/?$'), '');
    }

    if (kDebugMode) {
      return 'http://192.168.1.106:5000/api';
    }

    // Production URL
    return 'https://pgms-nu.vercel.app/api';
  }

  /// Local development fallback
  static String get localBaseUrl => 'http://192.168.1.106:5000/api';
}
