import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';

class ThemeProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  bool _isDark = false;

  ThemeProvider(this._prefs) {
    _loadTheme();
  }

  bool get isDark => _isDark;

  void _loadTheme() {
    _isDark = _prefs.getBool('isDark') ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    await _prefs.setBool('isDark', _isDark);
    notifyListeners();
  }

  ThemeData get currentTheme => AppTheme.getThemeData(_isDark);
}