import '../models/city_preset.dart';
import 'jewish_day_service.dart';

/// שעון הלכתי — מתרגם בין הזמן הלועזי הרגיל לבין "היום ההלכתי הנוכחי".
///
/// היום ההלכתי מתחיל בשקיעה (פסילת אור יום, חיוב ערבית) או בצאת הכוכבים
/// (קדושת היום). רוב האפליקציה משתמשת בתאריך הלועזי, אבל לחישוב מצב חיובי
/// ("איזה יום עכשיו?") משתמשים בכאן.
class HalachicClock {
  /// מחזיר את התאריך הלועזי שמייצג את היום ההלכתי הנוכחי.
  ///
  /// לפני צאת הכוכבים → היום הלועזי הנוכחי.
  /// אחרי צאת הכוכבים  → התאריך של מחר.
  ///
  /// כך, ב-מוצ"ש בערב, "היום ההלכתי" כבר יום ראשון.
  static DateTime halachicToday(CityPreset city, [DateTime? now]) {
    now ??= DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final jd = JewishDayService(city: city, date: today);
    final tzeit = jd.tzais;
    if (tzeit != null && now.isAfter(tzeit)) {
      return today.add(const Duration(days: 1));
    }
    return today;
  }

  /// האם השעה הנוכחית כבר אחרי צאת הכוכבים (כלומר היום ההלכתי הבא נכנס).
  static bool isAfterTzeit(CityPreset city, [DateTime? now]) {
    now ??= DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final jd = JewishDayService(city: city, date: today);
    final tzeit = jd.tzais;
    return tzeit != null && now.isAfter(tzeit);
  }

  /// האם השעה הנוכחית כבר אחרי שקיעה (תחילת היום ההלכתי הבא, אבל לפני צאת).
  /// בין שקיעה לצאת הכוכבים = "בין השמשות".
  static bool isAfterShkia(CityPreset city, [DateTime? now]) {
    now ??= DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final jd = JewishDayService(city: city, date: today);
    final shkia = jd.sunset;
    return shkia != null && now.isAfter(shkia);
  }
}
