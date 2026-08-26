import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _playAdhanKey = 'play_adhan';
  static const _themeModeKey = 'theme_mode';

  static Future<bool> getPlayAdhan() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_playAdhanKey) ?? true;
  }

  static Future<void> setPlayAdhan(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_playAdhanKey, value);
  }

  static Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final String? themeStr = prefs.getString(_themeModeKey);
    if (themeStr == 'light') return ThemeMode.light;
    if (themeStr == 'dark') return ThemeMode.dark;
    return ThemeMode.dark; // Default to dark theme
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode == ThemeMode.light ? 'light' : 'dark');
  }
}
