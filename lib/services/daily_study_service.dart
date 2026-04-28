import 'package:kosher_dart/kosher_dart.dart';

/// שירות לימוד יומי — דף יומי בבלי מבוסס kosher_dart (חישוב מקומי).
/// משנה יומית — עדיין לא מוטמע, דורש טבלת נתונים מאומתת.
class DailyStudyService {
  static HebrewDateFormatter _formatter() {
    final f = HebrewDateFormatter();
    f.hebrewFormat = true;
    f.useGershGershayim = true;
    return f;
  }

  /// דף יומי בבלי בפורמט עברי מלא, למשל: "ברכות ב׳".
  static String getDafYomiBavli([DateTime? forDate]) {
    final d = forDate ?? DateTime.now();
    final jc = JewishCalendar.fromDateTime(d);
    final daf = jc.getDafYomiBavli();
    return _formatter().formatDafYomiBavli(daf);
  }

  /// שם המסכת בעברית (בלי מספר דף), למשל: "ברכות".
  static String getDafYomiMasechet([DateTime? forDate]) {
    final d = forDate ?? DateTime.now();
    final jc = JewishCalendar.fromDateTime(d);
    return jc.getDafYomiBavli().getMasechta();
  }

  /// מספר הדף באותיות עבריות, למשל: "ב׳" / "ק״ד".
  static String getDafYomiDafFormatted([DateTime? forDate]) {
    final d = forDate ?? DateTime.now();
    final jc = JewishCalendar.fromDateTime(d);
    final daf = jc.getDafYomiBavli();
    return _formatter().formatHebrewNumber(daf.getDaf());
  }
}
