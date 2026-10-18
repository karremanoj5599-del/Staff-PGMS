import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

typedef UnauthorizedCallback = void Function();

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final http.Client _httpClient = http.Client();

  String? _token;
  String? _adminUserId;
  UnauthorizedCallback? _onUnauthorized;

  void setAuth({String? token, String? adminUserId}) {
    _token = token;
    if (adminUserId != null && adminUserId.isNotEmpty) {
      _adminUserId = adminUserId;
    }
  }

  void clearAuth() {
    _token = null;
    _adminUserId = null;
  }

  void setOnUnauthorized(UnauthorizedCallback? callback) {
    _onUnauthorized = callback;
  }

  String get baseUrl => ApiConfig.baseUrl;

  Map<String, String> _buildHeaders({Map<String, String>? extraHeaders}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    if (_adminUserId != null && _adminUserId!.isNotEmpty) {
      headers['x-admin-user-id'] = _adminUserId!;
      headers['x-user-id'] = _adminUserId!;
    }
    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    return headers;
  }

  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 15),
    int maxRetries = 2,
  }) async {
    final uri = _buildUri(endpoint, queryParams);
    final reqHeaders = _buildHeaders(extraHeaders: headers);

    int attempt = 0;
    while (true) {
      attempt++;
      try {
        if (kDebugMode) {
          debugPrint('[Staff ApiClient] GET $uri (attempt $attempt)');
        }
        final response = await _httpClient.get(uri, headers: reqHeaders).timeout(timeout);
        _logResponse('GET', uri, response);

        if (response.statusCode == 401 && _token != null) {
          _handleUnauthorized();
        }
        return response;
      } on SocketException catch (_) {
        if (attempt > maxRetries) rethrow;
        await Future.delayed(Duration(milliseconds: 300 * attempt));
      } on TimeoutException catch (_) {
        if (attempt > maxRetries) rethrow;
        await Future.delayed(Duration(milliseconds: 300 * attempt));
      }
    }
  }

  Future<http.Response> post(
    String endpoint, {
    dynamic body,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final uri = _buildUri(endpoint, queryParams);
    final reqHeaders = _buildHeaders(extraHeaders: headers);
    final encodedBody = body != null ? jsonEncode(body) : null;

    if (kDebugMode) {
      debugPrint('[Staff ApiClient] POST $uri');
    }
    final response = await _httpClient.post(uri, headers: reqHeaders, body: encodedBody).timeout(timeout);
    _logResponse('POST', uri, response);

    if (response.statusCode == 401 && _token != null) {
      _handleUnauthorized();
    }
    return response;
  }

  Future<http.Response> put(
    String endpoint, {
    dynamic body,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final uri = _buildUri(endpoint, queryParams);
    final reqHeaders = _buildHeaders(extraHeaders: headers);
    final encodedBody = body != null ? jsonEncode(body) : null;

    if (kDebugMode) {
      debugPrint('[Staff ApiClient] PUT $uri');
    }
    final response = await _httpClient.put(uri, headers: reqHeaders, body: encodedBody).timeout(timeout);
    _logResponse('PUT', uri, response);

    if (response.statusCode == 401 && _token != null) {
      _handleUnauthorized();
    }
    return response;
  }

  Future<http.Response> delete(
    String endpoint, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final uri = _buildUri(endpoint, queryParams);
    final reqHeaders = _buildHeaders(extraHeaders: headers);

    if (kDebugMode) {
      debugPrint('[Staff ApiClient] DELETE $uri');
    }
    final response = await _httpClient.delete(uri, headers: reqHeaders).timeout(timeout);
    _logResponse('DELETE', uri, response);

    if (response.statusCode == 401 && _token != null) {
      _handleUnauthorized();
    }
    return response;
  }

  Uri _buildUri(String endpoint, Map<String, String>? queryParams) {
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final fullUrl = '$baseUrl$cleanEndpoint';
    final baseUri = Uri.parse(fullUrl);
    if (queryParams != null && queryParams.isNotEmpty) {
      return baseUri.replace(queryParameters: queryParams);
    }
    return baseUri;
  }

  void _handleUnauthorized() {
    debugPrint('[Staff ApiClient] 401 Unauthorized encountered. Invoking onUnauthorized hook.');
    _onUnauthorized?.call();
  }

  void _logResponse(String method, Uri uri, http.Response response) {
    if (kDebugMode) {
      debugPrint('[Staff ApiClient] $method ${uri.path} -> ${response.statusCode} (${response.body.length} bytes)');
    }
  }
}
