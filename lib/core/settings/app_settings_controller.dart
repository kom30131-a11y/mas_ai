import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsController extends ChangeNotifier {
  AppSettingsController._();

  static final instance = AppSettingsController._();

  static const _themeKey = 'theme_mode';
  static const _languageKey = 'language';

  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('ar');

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  bool get isArabic => _locale.languageCode == 'ar';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    _themeMode = switch (prefs.getString(_themeKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    _locale = switch (prefs.getString(_languageKey)) {
      'en' => const Locale('en'),
      _ => const Locale('ar'),
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _themeKey,
      switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      },
    );
  }

  Future<void> setLanguage(String languageCode) async {
    _locale = Locale(
      languageCode == 'en' ? 'en' : 'ar',
    );

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _languageKey,
      _locale.languageCode,
    );
  }
}
