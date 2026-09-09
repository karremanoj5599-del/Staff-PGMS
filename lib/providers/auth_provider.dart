import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  static const _storage = FlutterSecureStorage();
  final ApiService _apiService = ApiService();

  User? _user;
  String? _token;
  bool _isLoading = true;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final storedUser = await _storage.read(key: 'user');
      final storedToken = await _storage.read(key: 'token');

      if (storedUser != null && storedUser.isNotEmpty) {
        _user = User.fromJson(jsonDecode(storedUser));
        _token = storedToken;
      }
    } catch (e) {
      debugPrint('Failed to load user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> login(String mobile, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _apiService.login(mobile, password);

      if (result.success && result.data != null) {
        final u = result.data!['user'] as User;
        final t = result.data!['token'] as String;

        await _saveAuthData(u, t);
        return null; // success, no error
      } else {
        return result.error ?? 'Login failed';
      }
    } catch (e) {
      return 'Failed to connect to the server';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> demoLogin() async {
    // Try online demo login first; if fails, fall back to offline demo user
    final err = await login('0000000000', 'password123');
    if (err != null) {
      final demoUser = User(
        id: 1,
        name: 'Demo Staff',
        email: 'staff@pgms.com',
        mobile: '0000000000',
        role: 'staff',
        adminUserId: 1,
        isAvailable: true,
        tradeType: 'plumber',
      );
      await _saveAuthData(demoUser, 'demo_token');
    }
  }

  Future<void> _saveAuthData(User userData, String token) async {
    _user = userData;
    _token = token;
    try {
      await _storage.write(key: 'user', value: jsonEncode(userData.toJson()));
      await _storage.write(key: 'token', value: token);
    } catch (e) {
      debugPrint('Failed to store auth data: $e');
    }
    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    _token = null;
    try {
      await _storage.delete(key: 'user');
      await _storage.delete(key: 'token');
    } catch (e) {
      debugPrint('Failed to clear auth data: $e');
    }
    notifyListeners();
  }

  void updateUser(User updated) {
    _user = updated;
    _storage.write(key: 'user', value: jsonEncode(updated.toJson()));
    notifyListeners();
  }
}
