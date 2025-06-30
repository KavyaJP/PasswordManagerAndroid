import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController {
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);

  static Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString('theme_mode') ?? 'system';

    switch (themeString) {
      case 'light':
        themeMode.value = ThemeMode.light;
        break;
      case 'dark':
        themeMode.value = ThemeMode.dark;
        break;
      default:
        themeMode.value = ThemeMode.system;
    }
  }

  static Future<void> setTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    themeMode.value = mode;

    switch (mode) {
      case ThemeMode.light:
        await prefs.setString('theme_mode', 'light');
        break;
      case ThemeMode.dark:
        await prefs.setString('theme_mode', 'dark');
        break;
      case ThemeMode.system:
        await prefs.setString('theme_mode', 'system');
        break;
    }
  }
}
