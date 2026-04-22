import 'package:shared_preferences/shared_preferences.dart';

import '../models/city_preset.dart';

/// שירות פרופיל המשתמש - שם, עיר, והעדפות אישיות כלליות.
///
/// שם המשתמש משמש לפנייה אישית בברכה, בהתראות ובמחמאות.
/// העיר משמשת לחישוב זמני היום (זריחה, שקיעה, צאת כוכבים) דרך kosher_dart.
class ProfileService {
  static const _keyName = 'profile_name';
  static const _keyCityId = 'profile_city_id';
  static const _keyOnboardingDone = 'profile_onboarding_done';

  /// שם ברירת מחדל לפנייה כשאין שם מוגדר - חם, לא רשמי, בלי להניח מגדר.
  static const String defaultFallback = 'חבר יקר';

  static Future<SharedPreferences> get _prefs =>
      SharedPreferences.getInstance();

  // ----------------- שם -----------------

  /// מחזיר את השם המוגדר, או null אם המשתמש עוד לא הזין שם.
  static Future<String?> getName() async {
    final p = await _prefs;
    final v = p.getString(_keyName);
    return (v != null && v.trim().isNotEmpty) ? v.trim() : null;
  }

  static Future<void> setName(String name) async {
    final p = await _prefs;
    await p.setString(_keyName, name.trim());
  }

  /// שם מוכן לשימוש בטקסטים - נופל ל-[fallback] אם אין שם.
  static Future<String> getDisplayName(
      {String fallback = defaultFallback}) async {
    return (await getName()) ?? fallback;
  }

  // ----------------- עיר -----------------

  static Future<CityPreset> getCity() async {
    final p = await _prefs;
    final id = p.getString(_keyCityId);
    return CityPreset.fromId(id) ?? CityPreset.jerusalem;
  }

  static Future<void> setCity(CityPreset city) async {
    final p = await _prefs;
    await p.setString(_keyCityId, city.id);
  }

  // ----------------- onboarding -----------------

  static Future<bool> isOnboardingDone() async {
    final p = await _prefs;
    return p.getBool(_keyOnboardingDone) ?? false;
  }

  static Future<void> markOnboardingDone() async {
    final p = await _prefs;
    await p.setBool(_keyOnboardingDone, true);
  }
}
