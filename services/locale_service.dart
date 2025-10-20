import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService extends ChangeNotifier {
  static const _key = 'app_locale_code';
  Locale? _locale;

  Locale? get locale => _locale;

  Future<void> loadSaved() async {
    final sp = await SharedPreferences.getInstance();
    final code = sp.getString(_key);
    if (code != null && code.isNotEmpty) {
      _locale = Locale(code);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, locale.languageCode);
  }
}
