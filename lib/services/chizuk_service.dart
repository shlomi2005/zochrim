import 'package:shared_preferences/shared_preferences.dart';

import '../data/chizuk_milestones.dart';
import '../models/chizuk_status.dart';

/// שירות "חיזוק יומי" — כל הנתונים נשמרים מקומית, אף פעם לא יוצאים מהמכשיר.
///
/// עיקרון מנחה: סה"כ ימי ההתגברות לעולם לא מתאפסים. גם שיא-כל-הזמנים נשמר.
/// רצף נוכחי נספר משמרני: ימים לא-מסומנים לא שוברים אותו, רק סימון struggled.
class ChizukService {
  static const _keyOvercame = 'chizuk_overcame_dates';
  static const _keyStruggled = 'chizuk_struggled_dates';
  static const _keyConsent = 'chizuk_consent_given';
  static const _keyLongestRun = 'chizuk_longest_run_ever';
  static const _keyLastQuoteIdx = 'chizuk_last_quote_idx';
  static const _keyHighestMilestone = 'chizuk_highest_milestone_reached';
  static const _keyLastCelebrationDate = 'chizuk_last_celebration_date';
  static const _keyJourneyStartDate = 'chizuk_journey_start_date';

  static Future<SharedPreferences> get _prefs =>
      SharedPreferences.getInstance();

  static String _iso(DateTime d) =>
      "${d.year.toString().padLeft(4, '0')}-"
      "${d.month.toString().padLeft(2, '0')}-"
      "${d.day.toString().padLeft(2, '0')}";

  static DateTime _parseIso(String s) {
    final parts = s.split('-');
    return DateTime(
        int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  // ------------------ הסכמה חד-פעמית ------------------

  static Future<bool> hasConsented() async {
    final p = await _prefs;
    return p.getBool(_keyConsent) ?? false;
  }

  static Future<void> giveConsent() async {
    final p = await _prefs;
    await p.setBool(_keyConsent, true);
  }

  // ------------------ סימון יום ------------------

  static Future<ChizukStatus?> getStatus(DateTime date) async {
    final iso = _iso(date);
    final p = await _prefs;
    final over = p.getStringList(_keyOvercame) ?? const [];
    final str = p.getStringList(_keyStruggled) ?? const [];
    if (over.contains(iso)) return ChizukStatus.overcame;
    if (str.contains(iso)) return ChizukStatus.struggled;
    return null;
  }

  /// מסמן יום. ניתן לשנות — הסימון האחרון מנצח.
  static Future<void> markDay(DateTime date, ChizukStatus status) async {
    final iso = _iso(date);
    final p = await _prefs;
    final over = (p.getStringList(_keyOvercame) ?? const []).toSet();
    final str = (p.getStringList(_keyStruggled) ?? const []).toSet();

    over.remove(iso);
    str.remove(iso);
    if (status == ChizukStatus.overcame) {
      over.add(iso);
    } else {
      str.add(iso);
    }

    await p.setStringList(_keyOvercame, over.toList());
    await p.setStringList(_keyStruggled, str.toList());

    final current = await getCurrentRun();
    final longest = p.getInt(_keyLongestRun) ?? 0;
    if (current > longest) {
      await p.setInt(_keyLongestRun, current);
    }
  }

  /// מבטל סימון של יום (למקרה של מי-תאפ).
  static Future<void> clearDay(DateTime date) async {
    final iso = _iso(date);
    final p = await _prefs;
    final over = (p.getStringList(_keyOvercame) ?? const []).toSet();
    final str = (p.getStringList(_keyStruggled) ?? const []).toSet();
    over.remove(iso);
    str.remove(iso);
    await p.setStringList(_keyOvercame, over.toList());
    await p.setStringList(_keyStruggled, str.toList());
  }

  // ------------------ סטטיסטיקה ------------------

  /// סה"כ ימי התגברות לאורך כל הזמן. לא מתאפס.
  static Future<int> getTotalOvercame() async {
    final p = await _prefs;
    return (p.getStringList(_keyOvercame) ?? const []).length;
  }

  /// רצף נוכחי: נספר אחורה מהיום.
  /// יום overcame = מוסיף לרצף.
  /// יום לא-מסומן = לא שובר (הרצף ממשיך דרכו).
  /// יום struggled = שובר מיד.
  static Future<int> getCurrentRun() async {
    final p = await _prefs;
    final over = (p.getStringList(_keyOvercame) ?? const []).toSet();
    final str = (p.getStringList(_keyStruggled) ?? const []).toSet();

    int run = 0;
    DateTime cursor = DateTime.now();
    cursor = DateTime(cursor.year, cursor.month, cursor.day);

    // הגבלה למקרה קצה — 5 שנים אחורה.
    for (int i = 0; i < 365 * 5; i++) {
      final iso = _iso(cursor);
      if (str.contains(iso)) break;
      if (over.contains(iso)) run += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return run;
  }

  static Future<int> getLongestRunEver() async {
    final p = await _prefs;
    final stored = p.getInt(_keyLongestRun) ?? 0;
    final current = await getCurrentRun();
    return current > stored ? current : stored;
  }

  /// מחזיר מפה של ISO → Status לכל הימים המסומנים ב-N הימים האחרונים.
  static Future<Map<String, ChizukStatus>> getLastDays(int n) async {
    final p = await _prefs;
    final over = (p.getStringList(_keyOvercame) ?? const []).toSet();
    final str = (p.getStringList(_keyStruggled) ?? const []).toSet();

    final today = DateTime.now();
    final cutoff = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: n - 1));

    final result = <String, ChizukStatus>{};
    for (final iso in over) {
      final d = _parseIso(iso);
      if (!d.isBefore(cutoff)) result[iso] = ChizukStatus.overcame;
    }
    for (final iso in str) {
      final d = _parseIso(iso);
      if (!d.isBefore(cutoff)) result[iso] = ChizukStatus.struggled;
    }
    return result;
  }

  /// מאפס את כל הנתונים (למשל אם המשתמש רוצה להתחיל מחדש).
  static Future<void> resetAll() async {
    final p = await _prefs;
    await p.remove(_keyOvercame);
    await p.remove(_keyStruggled);
    await p.remove(_keyLongestRun);
    await p.remove(_keyHighestMilestone);
    await p.remove(_keyJourneyStartDate);
  }

  // ------------------ נקודת התחלת המסע ------------------

  /// תאריך תחילת המסע — היום הראשון שבו המשתמש נכנס למסך החיזוק.
  /// אם עדיין לא נקבע, מחזיר null.
  static Future<DateTime?> getJourneyStartDate() async {
    final p = await _prefs;
    final s = p.getString(_keyJourneyStartDate);
    if (s == null) return null;
    return _parseIso(s);
  }

  /// קובע את היום הנוכחי כתחילת המסע, אם עדיין לא נקבע. מחזיר את התאריך.
  static Future<DateTime> ensureJourneyStarted() async {
    final existing = await getJourneyStartDate();
    if (existing != null) return existing;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final p = await _prefs;
    await p.setString(_keyJourneyStartDate, _iso(today));
    return today;
  }

  // ------------------ חגיגה פעם ביום ------------------

  /// בודק אם עוד לא חגגנו היום (קונפטי/ציטוט חדש).
  /// נועל את החגיגה לתאריך, כדי שיהיה להם למה לחכות למחר.
  static Future<bool> shouldCelebrateToday() async {
    final p = await _prefs;
    final last = p.getString(_keyLastCelebrationDate);
    final today = _iso(DateTime.now());
    return last != today;
  }

  /// מסמן שחגגנו היום. ישאר נעול עד מחר גם אם המשתמש ינקה וישוב לסמן.
  static Future<void> markCelebratedToday() async {
    final p = await _prefs;
    await p.setString(_keyLastCelebrationDate, _iso(DateTime.now()));
  }

  // ------------------ מילסטונים ------------------

  /// גובה המילסטון (בימים) שהמשתמש כבר חגג. 0 אם עוד לא.
  static Future<int> getHighestMilestoneReached() async {
    final p = await _prefs;
    return p.getInt(_keyHighestMilestone) ?? 0;
  }

  /// בודק אם הרצף הנוכחי הוא מילסטון חדש שעוד לא נחגג.
  /// אם כן — שומר ומחזיר את המילסטון לחגיגה. אחרת — null.
  static Future<ChizukMilestone?> checkAndClaimMilestone(int currentRun) async {
    final milestone = milestoneAt(currentRun);
    if (milestone == null) return null;

    final p = await _prefs;
    final highest = p.getInt(_keyHighestMilestone) ?? 0;
    if (milestone.days <= highest) return null;

    await p.setInt(_keyHighestMilestone, milestone.days);
    return milestone;
  }

  // ------------------ רוטציית ציטוטים ------------------

  /// מחזיר אינדקס של הציטוט הבא ברוטציה (נמנע מחזרה מיידית).
  static Future<int> nextQuoteIndex(int totalQuotes) async {
    final p = await _prefs;
    final last = p.getInt(_keyLastQuoteIdx) ?? -1;
    int next = (last + 1) % totalQuotes;
    if (next == last && totalQuotes > 1) next = (next + 1) % totalQuotes;
    await p.setInt(_keyLastQuoteIdx, next);
    return next;
  }
}
