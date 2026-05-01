import 'package:kosher_dart/kosher_dart.dart';

import '../models/city_preset.dart';
import '../models/omer_day.dart';
import 'halachic_clock.dart';

/// שירות לחישוב יום הספירה הנוכחי ולהמרה בין "יום עומר" לתאריך לועזי.
///
/// מודל: כל "יום עומר" מתחיל בערב של תאריך לועזי מסוים, אחרי צאת הכוכבים.
/// הערב הזה "שייך" לתאריך הלועזי שלפניו — ומכאן שתאריך תחילת ספירת יום 1
/// (firstOmerNight) הוא הלועזי שמכיל את היום של 15 בניסן (= ערב פסח שני
/// שלאחריו, כשנכנס ל-16 בניסן, מתחילים לספור).
///
/// כל החישובים מבוססים `JewishCalendar` של kosher_dart, ולכן עובדים
/// אוטומטית לכל שנה עברית — אין שום תאריך מקודד.
///
/// כש-`city` מועברת, גבול היום נקבע לפי צאת הכוכבים האמיתי בעיר.
/// בלי `city`, נופלים חזרה ל-fallback של 20:00 (לקוד ישן/בדיקות).
class OmerService {
  /// fallback בלבד — כשלא מועברת עיר, מניחים שצאת הכוכבים ב-20:00.
  static const int nightfallHour = 20;

  /// התאריך הלועזי שבערבו (אחרי צאת הכוכבים) מתחילה ספירת יום 1.
  /// מחושב דינמית לפי השנה העברית הנוכחית — תקף לכל שנה.
  static DateTime get firstOmerNight {
    final now = JewishCalendar.fromDateTime(DateTime.now());
    return _firstOmerNightOfHebrewYear(now.getJewishYear());
  }

  /// שם תאימות לאחור — שווה ל-firstOmerNight.
  static DateTime get firstDay => firstOmerNight;

  /// התאריך הלועזי שבערבו מתחילה ספירת יום 49.
  static DateTime get lastOmerNight =>
      firstOmerNight.add(const Duration(days: 48));

  /// 15 בניסן של השנה העברית הנתונה, כתאריך לועזי.
  /// היום הזה מכיל את ליל 16 בניסן בערבו — תחילת ספירת העומר.
  static DateTime _firstOmerNightOfHebrewYear(int hebrewYear) {
    final jc =
        JewishCalendar.initDate(hebrewYear, JewishDate.NISSAN, 15);
    final greg = jc.getGregorianCalendar();
    return DateTime(greg.year, greg.month, greg.day);
  }

  /// מחזיר את התאריך שבערבו מתחילה ספירת יום 1 בשנה העברית הבאה.
  /// שימושי לטקסט "ספירת העומר תתחיל ב-...".
  static DateTime get nextOmerFirstNight {
    final nowJc = JewishCalendar.fromDateTime(DateTime.now());
    return _firstOmerNightOfHebrewYear(nowJc.getJewishYear() + 1);
  }

  /// מחשב את יום העומר הנוכחי לפי [now].
  ///
  /// - אם הועברה [city]: גבול היום נקבע לפי צאת הכוכבים האמיתי באותה עיר.
  ///   אחרי צאת = הערב הפעיל התחיל הלילה. לפני צאת = הוא התחיל אתמול.
  /// - בלי [city]: fallback ל-20:00.
  static OmerDay computeDay({DateTime? now, CityPreset? city}) {
    now ??= DateTime.now();
    final fOmer = firstOmerNight;

    final bool nightStartedToday = city != null
        ? HalachicClock.isAfterTzeit(city, now)
        : now.hour >= nightfallHour;

    final currentOmerNight = nightStartedToday
        ? DateTime(now.year, now.month, now.day)
        : DateTime(now.year, now.month, now.day - 1);

    if (currentOmerNight.isBefore(fOmer)) {
      return const OmerDay(beforeOmer: true);
    }

    final diff = currentOmerNight.difference(fOmer).inDays;
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
