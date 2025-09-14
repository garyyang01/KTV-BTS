import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Locale provider for managing language switching
class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'locale';
  
  Locale _locale = const Locale('en', 'US');
  
  Locale get locale => _locale;
  
  LocaleProvider() {
    _loadLocale();
  }
  
  /// Load locale from SharedPreferences
  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final localeCode = prefs.getString(_localeKey) ?? 'en_US';
    final parts = localeCode.split('_');
    if (parts.length == 2) {
      _locale = Locale(parts[0], parts[1]);
    } else {
      _locale = const Locale('en', 'US');
    }
    notifyListeners();
  }
  
  /// Save locale to SharedPreferences
  Future<void> _saveLocale() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, '${_locale.languageCode}_${_locale.countryCode}');
  }
  
  /// Set locale
  Future<void> setLocale(Locale locale) async {
    if (_locale != locale) {
      _locale = locale;
      await _saveLocale();
      notifyListeners();
    }
  }
  
  /// Get available locales
  static List<Locale> get supportedLocales => [
    const Locale('en', 'US'), // English
    const Locale('zh', 'TW'), // Traditional Chinese
    const Locale('zh', 'CN'), // Simplified Chinese
  ];
  
  /// Get locale display name
  String getLocaleDisplayName(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'zh':
        return locale.countryCode == 'TW' ? '繁體中文' : '简体中文';
      default:
        return 'English';
    }
  }
  
  /// Get current locale display name
  String get currentLocaleDisplayName => getLocaleDisplayName(_locale);
}
