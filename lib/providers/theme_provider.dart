import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  static const _storage = FlutterSecureStorage();

  ThemeMode _themeMode = ThemeMode.system;
  Color _primaryColor = const Color(0xFF3B82F6);
  String _fontFamily = 'Inter';
  double _uiScale = 1.0;
  bool _isLoaded = false;

  ThemeMode get themeMode => _themeMode;
  Color get primaryColor => _primaryColor;
  String get fontFamily => _fontFamily;
  double get uiScale => _uiScale;
  bool get isLoaded => _isLoaded;

  ThemeProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final modeStr = await _storage.read(key: 'themeMode');
      final colorStr = await _storage.read(key: 'primaryColor');
      final fontStr = await _storage.read(key: 'fontFamily');
      final scaleStr = await _storage.read(key: 'uiScale');

      if (modeStr != null) {
        if (modeStr == 'dark') {
          _themeMode = ThemeMode.dark;
        } else if (modeStr == 'light') {
          _themeMode = ThemeMode.light;
        } else {
          _themeMode = ThemeMode.system;
        }
      }

      if (colorStr != null) {
        final parsed = int.tryParse(colorStr.replaceFirst('#', '0xFF'));
        if (parsed != null) _primaryColor = Color(parsed);
      }

      if (fontStr != null && AppTheme.supportedFonts.contains(fontStr)) {
        _fontFamily = fontStr;
      }

      if (scaleStr != null) {
        final parsed = double.tryParse(scaleStr);
        if (parsed != null && parsed >= 0.75 && parsed <= 1.25) {
          _uiScale = parsed;
        }
      }
    } catch (e) {
      debugPrint('Failed to load theme settings: $e');
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final str = mode == ThemeMode.dark ? 'dark' : (mode == ThemeMode.light ? 'light' : 'system');
    await _storage.write(key: 'themeMode', value: str);
  }

  Future<void> setPrimaryColor(Color color) async {
    _primaryColor = color;
    notifyListeners();
    final hex = '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
    await _storage.write(key: 'primaryColor', value: hex);
  }

  Future<void> setFontFamily(String font) async {
    _fontFamily = font;
    notifyListeners();
    await _storage.write(key: 'fontFamily', value: font);
  }

  Future<void> setUiScale(double scale) async {
    _uiScale = scale;
    notifyListeners();
    await _storage.write(key: 'uiScale', value: scale.toString());
  }

  ThemeData get lightTheme => AppTheme.light(
    primaryColor: _primaryColor,
    fontFamily: _fontFamily,
    uiScale: _uiScale,
  );

  ThemeData get darkTheme => AppTheme.dark(
    primaryColor: _primaryColor,
    fontFamily: _fontFamily,
    uiScale: _uiScale,
  );

  ResolvedColors resolvedColors(BuildContext context) {
    final isDark = _themeMode == ThemeMode.dark ||
        (_themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);
    return isDark
        ? ResolvedColors.dark(accentOverride: _primaryColor)
        : ResolvedColors.light(accentOverride: _primaryColor);
  }
}
