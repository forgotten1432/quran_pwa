import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _lastPageKey = 'last_read_page';
  static const String _isDarkModeKey = 'is_dark_mode';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> saveLastPage(int page) async {
    await _prefs?.setInt(_lastPageKey, page);
  }

  int getLastPage() {
    return _prefs?.getInt(_lastPageKey) ?? 1;
  }

  Future<void> saveDarkMode(bool isDark) async {
    await _prefs?.setBool(_isDarkModeKey, isDark);
  }

  bool getDarkMode() {
    return _prefs?.getBool(_isDarkModeKey) ?? false;
  }
}
