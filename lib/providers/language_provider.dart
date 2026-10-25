import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { english, sinhala }

class LanguageProvider extends ChangeNotifier {
  static const String _prefKey = 'app_language';
  AppLanguage _currentLanguage = AppLanguage.english;

  LanguageProvider() {
    _loadLanguage();
  }

  AppLanguage get currentLanguage => _currentLanguage;
  bool get isSinhala => _currentLanguage == AppLanguage.sinhala;

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved == 'sinhala') {
      _currentLanguage = AppLanguage.sinhala;
      notifyListeners();
    }
  }

  Future<void> setLanguage(AppLanguage lang) async {
    _currentLanguage = lang;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, lang == AppLanguage.sinhala ? 'sinhala' : 'english');
  }

  // Translation helpers
  String get appTitle => isSinhala ? 'ලංකා ගෑස් ට්‍රැකර්' : 'Lanka Gas Tracker';
  String get searchHint => isSinhala ? 'නගරය හෝ Station සොයන්න...' : 'Search town or station...';
  String get addStation => isSinhala ? 'නව Station එක් කරන්න' : 'Add Gas Station';
  String get myLocation => isSinhala ? 'මගේ ස්ථානය' : 'My Location';
  String get inStock => isSinhala ? 'තොග ඇත' : 'In Stock';
  String get outOfStock => isSinhala ? 'තොග අවසන්' : 'Out of Stock';
  String get unverified => isSinhala ? 'තහවුරු කර නොමැත' : 'Unverified';
  String get settings => isSinhala ? 'සැකසුම්' : 'Settings';
  String get profile => isSinhala ? 'මගේ Profile එක' : 'My Profile';
  String get selectLanguage => isSinhala ? 'භාෂාව තෝරන්න' : 'Select Language';
  String get proximityAlert => isSinhala ? '4 KM ආසන්නතා නිවේදන' : '4 KM Proximity Alerts';

  String gasAlertTitle() {
    return isSinhala ? '🔥 ඔබට ආසන්නයේ ගෑස් ඇත!' : '🔥 Gas Available Near You!';
  }

  String gasAlertBody(String stationName, String brand, double distanceKm) {
    if (isSinhala) {
      return '$stationName ($brand) හි ගෑස් තොග ලැබී ඇත! දුර: ${distanceKm.toStringAsFixed(1)} km.';
    }
    return '$stationName ($brand) is now IN STOCK! Distance: ${distanceKm.toStringAsFixed(1)} km.';
  }
}
