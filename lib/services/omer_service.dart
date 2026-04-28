import '../models/city_preset.dart';
import '../models/omer_day.dart';
import 'halachic_clock.dart';

/// שירות לחישוב יום הספירה הנוכחי ולהמרה בין "יום עומר" לתאריך לועזי.
///
/// ספירת העומר תשפ"ו:
///   - ערב יום 1: ליל ג', 2 באפריל 2026 (הערב נכנס מ-2/4 אל 3/4)
///   - ערב יום 49: ליל ד', 20 במאי 2026
///   - שבועות: ליל ה', 21 במאי 2026
///
/// מודל: כל "יום עומר" מתחיל בערב של תאריך לועזי מסוים, אחרי צאת הכוכבים.
/// הערב הזה "שייך" לתאריך הלועזי שלפניו — ומכאן `firstOmerNight = 2/4/2026`.
///
/// כש-`city` מועברת, גבול היום נקבע לפי צאת הכוכבים האמיתי בעיר.
/// בלי `city`, נופלים חזרה ל-fallback של 20:00 (לקוד ישן/בדיקות).
class OmerService {
  /// התאריך הלועזי שבערבו (אחרי צאת הכוכבים) מתחילה ספירת יום 1.
  static final DateTime firstOmerNight = DateTime(2026, 4, 2);

  /// alias שימושי לקוד ישן
  static DateTime get firstDay => firstOmerNight;

  /// התאריך הלועזי שבערבו מתחילה ספירת יום 49 (20.5.2026)
  static DateTime get lastOmerNight =>
      firstOmerNight.add(const Duration(days: 48));

  /// fallback בלבד — כשלא מועברת עיר, מניחים שצאת הכוכבים ב-20:00.
  static const int nightfallHour = 20;

  /// מחשב את יום העומר הנוכחי לפי [now].
  ///
  /// - אם הועברה [city]: גבול היום נקבע לפי צאת הכוכבים האמיתי באותה עיר.
  ///   אחרי צאת = הערב הפעיל התחיל הלילה. לפני צאת = הוא התחיל אתמול.
  /// - בלי [city]: fallback ל-20:00.
  static OmerDay computeDay({DateTime? now, CityPreset? city}) {
    now ??= DateTime.now();

    final bool nightStartedToday = city != null
        ? HalachicClock.isAfterTzeit(city, now)
        : now.hour >= nightfallHour;

    final currentOmerNight = nightStartedToday
        ? DateTime(now.year, now.month, now.day)
        : DateTime(now.year, now.month, now.day - 1);

    if (currentOmerNight.isBefore(firstOmerNight)) {
      return const OmerDay(beforeOmer: true);
    }

    final diff = currentOmerNight.difference(firstOmerNight).inDays;
    final day = diff + 1;
    if (day > 49) return const OmerDay(afterOmer: true);
    return OmerDay(dayNumber: day);
  }

  /// ימים שנותרו עד לסוף הספירה (49)
  static int daysRemaining({DateTime? now, CityPreset? city}) {
    final od = computeDay(now: now, city: city);
    if (od.beforeOmer) return 49;
    if (od.afterOmer) return 0;
    return 49 - (od.dayNumber ?? 0);
  }

  /// התאריך הלועזי שבערבו מתחילה ספירת יום [day] (1-49).
  /// זה התאריך שבו נשלחת ההתראה היומית (בשעה שהמשתמש בחר).
  static DateTime dateForDay(int day) {
    return firstOmerNight.add(Duration(days: day - 1));
  }
}
