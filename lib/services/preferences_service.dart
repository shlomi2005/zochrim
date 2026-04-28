import 'package:shared_preferences/shared_preferences.dart';

import '../models/zman_type.dart';

/// שומר העדפות ומצב מקומי: האם ספרתי היום, שעת תזכורת.
class PreferencesService {
  static const _keyLastCountedDay = 'last_counted_day_iso'; // iso date (yyyy-MM-dd) של התאריך הלועזי שבערב שלו ספרנו
  static const _keyLastCountedDayNumber = 'last_counted_day_number'; // 1..49
  static const _keyReminderHour = 'reminder_hour';
  static const _keyReminderMinute = 'reminder_minute';
  static const _keyFirstLaunch = 'first_launch_done';

  // תפילין - מצב יומי + תזמון תזכורת
  static const _keyTefillinLastDoneIso = 'tefillin_last_done_iso'; // yyyy-MM-dd שבבוקר שלו סומן
  static const _keyTefillinStreak = 'tefillin_streak';
  static const _keyTefillinReminderHour = 'tefillin_reminder_hour';
  static const _keyTefillinReminderMinute = 'tefillin_reminder_minute';

  // מתגי הפעלה/כיבוי per-notification (ברירת מחדל: דלוקים)
  static const _keyTefillinEnabled = 'tefillin_notifications_enabled';
  static const _keyOmerEnabled = 'omer_notifications_enabled';

  // דף יומי בבלי
  static const _keyDafYomiEnabled = 'daf_yomi_enabled';
  static const _keyDafYomiHour = 'daf_yomi_hour';
  static const _keyDafYomiMinute = 'daf_yomi_minute';

  /// ברירת מחדל לשעת תזכורת דף יומי (בוקר)
  static const int defaultDafYomiHour = 7;
  static const int defaultDafYomiMinute = 0;

  /// ברירת מחדל לשעת תזכורת עומר (ערב)
  static const int defaultReminderHour = 20;
  static const int defaultReminderMinute = 15;

  /// ברירת מחדל לשעת תזכורת תפילין (בוקר)
  static const int defaultTefillinHour = 7;
  static const int defaultTefillinMinute = 30;

  static Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  /// מחזיר את מספר היום האחרון שסומן כ"ספרתי" (1-49), או null אם עוד לא סומן.
  /// ה-service של ההתראות והמסך משתמשים בזה כדי להראות ✓ / לדלג על התראה.
  static Future<int?> getLastCountedDayNumber() async {
    final p = await _prefs;
    final n = p.getInt(_keyLastCountedDayNumber);
    return (n != null && n > 0) ? n : null;
  }

  /// מחזיר את ה-ISO (yyyy-MM-dd) של התאריך הלועזי של הערב שבו ספרנו לאחרונה.
  static Future<String?> getLastCountedDateIso() async {
    final p = await _prefs;
    return p.getString(_keyLastCountedDay);
  }

  /// מסמן שהמשתמש ספר את יום [day] (1-49) בתאריך הלועזי [effectiveDate].
  static Future<void> markCounted(int day, DateTime effectiveDate) async {
    final p = await _prefs;
    final iso = "${effectiveDate.year.toString().padLeft(4, '0')}-"
        "${effectiveDate.month.toString().padLeft(2, '0')}-"
        "${effectiveDate.day.toString().padLeft(2, '0')}";
    await p.setInt(_keyLastCountedDayNumber, day);
    await p.setString(_keyLastCountedDay, iso);
  }

  /// האם כבר ספרנו את יום [day] (1-49)?
  static Future<bool> hasCountedDay(int day) async {
    final last = await getLastCountedDayNumber();
    return last != null && last >= day;
  }

  // ------------------ שעת תזכורת ------------------

  static Future<int> getReminderHour() async {
    final p = await _prefs;
    return p.getInt(_keyReminderHour) ?? defaultReminderHour;
  }

  static Future<int> getReminderMinute() async {
    final p = await _prefs;
    return p.getInt(_keyReminderMinute) ?? defaultReminderMinute;
  }

  static Future<void> setReminderTime(int hour, int minute) async {
    final p = await _prefs;
    await p.setInt(_keyReminderHour, hour);
    await p.setInt(_keyReminderMinute, minute);
  }

  // ------------------ first launch ------------------

  static Future<bool> isFirstLaunch() async {
    final p = await _prefs;
    return !(p.getBool(_keyFirstLaunch) ?? false);
  }

  static Future<void> markFirstLaunchDone() async {
    final p = await _prefs;
    await p.setBool(_keyFirstLaunch, true);
  }

  // ------------------ תפילין ------------------

  static String _isoDate(DateTime d) =>
      "${d.year.toString().padLeft(4, '0')}-"
      "${d.month.toString().padLeft(2, '0')}-"
      "${d.day.toString().padLeft(2, '0')}";

  /// מחזיר את התאריך (yyyy-MM-dd) של היום האחרון שבו סומן "הנחתי תפילין", או null.
  static Future<String?> getTefillinLastDoneIso() async {
    final p = await _prefs;
    return p.getString(_keyTefillinLastDoneIso);
  }

  /// האם כבר סימן היום שהניח תפילין?
  static Future<bool> hasDoneTefillinToday() async {
    final iso = await getTefillinLastDoneIso();
    if (iso == null) return false;
    return iso == _isoDate(DateTime.now());
  }

  /// מסמן שהמשתמש הניח תפילין היום. מעדכן גם סטריק (אם אתמול היה סימון - ממשיך).
  static Future<void> markTefillinDone() async {
    final p = await _prefs;
    final today = DateTime.now();
    final todayIso = _isoDate(today);
    final prevIso = p.getString(_keyTefillinLastDoneIso);

    // חישוב סטריק: אם היום כבר מסומן - לא משנים. אם אתמול - ממשיך. אחרת מתחיל מחדש.
    int streak = p.getInt(_keyTefillinStreak) ?? 0;
    if (prevIso == todayIso) {
      // כבר היום - לא משנים
    } else {
      final yesterday = today.subtract(const Duration(days: 1));
      final yesterdayIso = _isoDate(yesterday);
      if (prevIso == yesterdayIso) {
        streak += 1;
      } else {
        streak = 1;
      }
    }

    await p.setString(_keyTefillinLastDoneIso, todayIso);
    await p.setInt(_keyTefillinStreak, streak);
  }

  /// מחזיר את הסטריק הנוכחי (כמה ימים ברציפות).
  static Future<int> getTefillinStreak() async {
    final p = await _prefs;
    final streak = p.getInt(_keyTefillinStreak) ?? 0;
    if (streak == 0) return 0;

    // אם לא הונח אתמול או היום - הסטריק נשבר
    final last = p.getString(_keyTefillinLastDoneIso);
    if (last == null) return 0;
    final today = DateTime.now();
    final todayIso = _isoDate(today);
    final yesterdayIso = _isoDate(today.subtract(const Duration(days: 1)));
    if (last == todayIso || last == yesterdayIso) return streak;
    return 0;
  }

  // שעת תזכורת תפילין
  static Future<int> getTefillinHour() async {
    final p = await _prefs;
    return p.getInt(_keyTefillinReminderHour) ?? defaultTefillinHour;
  }

  static Future<int> getTefillinMinute() async {
    final p = await _prefs;
    return p.getInt(_keyTefillinReminderMinute) ?? defaultTefillinMinute;
  }

  static Future<void> setTefillinTime(int hour, int minute) async {
    final p = await _prefs;
    await p.setInt(_keyTefillinReminderHour, hour);
    await p.setInt(_keyTefillinReminderMinute, minute);
  }

  // ------------------ מתגי הפעלה ------------------

  static Future<bool> isTefillinEnabled() async {
    final p = await _prefs;
    return p.getBool(_keyTefillinEnabled) ?? true;
  }

  static Future<void> setTefillinEnabled(bool enabled) async {
    final p = await _prefs;
    await p.setBool(_keyTefillinEnabled, enabled);
  }

  static Future<bool> isOmerEnabled() async {
    final p = await _prefs;
    return p.getBool(_keyOmerEnabled) ?? true;
  }

  static Future<void> setOmerEnabled(bool enabled) async {
    final p = await _prefs;
    await p.setBool(_keyOmerEnabled, enabled);
  }

  // ------------------ זמני היום ------------------

  /// ברירת מחדל: כל הזמנים כבויים (opt-in). המשתמש מפעיל מה שהוא רוצה.
  static String _zmanEnabledKey(ZmanType z) => 'zman_${z.name}_enabled';
  static String _zmanLeadKey(ZmanType z) => 'zman_${z.name}_lead_min';

  static Future<bool> isZmanEnabled(ZmanType z) async {
    final p = await _prefs;
    return p.getBool(_zmanEnabledKey(z)) ?? false;
  }

  static Future<void> setZmanEnabled(ZmanType z, bool enabled) async {
    final p = await _prefs;
    await p.setBool(_zmanEnabledKey(z), enabled);
  }

  static Future<int> getZmanLeadMinutes(ZmanType z) async {
    final p = await _prefs;
    return p.getInt(_zmanLeadKey(z)) ?? defaultLeadMinutes;
  }

  static Future<void> setZmanLeadMinutes(ZmanType z, int minutes) async {
    final p = await _prefs;
    await p.setInt(_zmanLeadKey(z), minutes);
  }

  // ------------------ דף יומי ------------------

  static Future<bool> isDafYomiEnabled() async {
    final p = await _prefs;
    return p.getBool(_keyDafYomiEnabled) ?? false;
  }

  static Future<void> setDafYomiEnabled(bool enabled) async {
    final p = await _prefs;
    await p.setBool(_keyDafYomiEnabled, enabled);
  }

  static Future<int> getDafYomiHour() async {
    final p = await _prefs;
    return p.getInt(_keyDafYomiHour) ?? defaultDafYomiHour;
  }

  static Future<int> getDafYomiMinute() async {
    final p = await _prefs;
    return p.getInt(_keyDafYomiMinute) ?? defaultDafYomiMinute;
  }

  static Future<void> setDafYomiTime(int hour, int minute) async {
    final p = await _prefs;
    await p.setInt(_keyDafYomiHour, hour);
    await p.setInt(_keyDafYomiMinute, minute);
  }
}
