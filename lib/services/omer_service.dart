import '../models/omer_day.dart';

/// שירות לחישוב יום הספירה הנוכחי ולהמרה בין "יום עומר" לתאריך לועזי.
///
/// ספירת העומר תשפ"ו:
///   - ערב יום 1: ליל ג', 2 באפריל 2026 (הערב נכנס מ-2/4 אל 3/4)
///   - ערב יום 49: ליל ד', 20 במאי 2026
///   - שבועות: ליל ה', 21 במאי 2026
///
/// מודל: כל "יום עומר" מתחיל בערב של תאריך לועזי מסוים, אחרי 20:00 (צאת הכוכבים).
/// הערב הזה "שייך" לתאריך הלועזי שלפניו - ומכאן `firstOmerNight = 2/4/2026`.
class OmerService {
  /// התאריך הלועזי שבערבו (אחרי 20:00) מתחילה ספירת יום 1.
  static final DateTime firstOmerNight = DateTime(2026, 4, 2);

  /// alias שימושי לקוד ישן
  static DateTime get firstDay => firstOmerNight;

  /// התאריך הלועזי שבערבו מתחילה ספירת יום 49 (20.5.2026)
  static DateTime get lastOmerNight =>
      firstOmerNight.add(const Duration(days: 48));

  /// השעה שממנה והלאה סופרים את הערב הנוכחי (צאת כוכבים משוער)
  static const int nightfallHour = 20;

  /// מחשב את יום העומר הנוכחי לפי [now].
  ///
  /// לוגיקה: "היום של הערב הפעיל" הוא תאריך הערב שבצאת הכוכבים שלו התחיל היום.
  /// - אם [now] אחרי 20:00 - הערב הפעיל התחיל בלילה של [now] הנוכחי.
  /// - אחרת - הערב הפעיל התחיל אתמול בלילה.
  static OmerDay computeDay([DateTime? now]) {
    now ??= DateTime.now();

    final DateTime currentOmerNight;
    if (now.hour >= nightfallHour) {
      currentOmerNight = DateTime(now.year, now.month, now.day);
    } else {
      currentOmerNight = DateTime(now.year, now.month, now.day - 1);
    }

    if (currentOmerNight.isBefore(firstOmerNight)) {
      return const OmerDay(beforeOmer: true);
    }

    final diff = currentOmerNight.difference(firstOmerNight).inDays;
    final day = diff + 1;
    if (day > 49) return const OmerDay(afterOmer: true);
    return OmerDay(dayNumber: day);
  }

  /// ימים שנותרו עד לסוף הספירה (49)
  static int daysRemaining([DateTime? now]) {
    final od = computeDay(now);
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
