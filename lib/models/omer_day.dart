import '../data/omer_days.dart';

/// מייצג יום בספירת העומר (1-49), או מצב "לפני"/"אחרי" העומר
class OmerDay {
  /// מספר היום 1-49, או null אם לא בתקופת העומר
  final int? dayNumber;

  /// האם אנחנו לפני תחילת ספירת העומר (לפני ליל חמישי, 2 באפריל 2026)
  final bool beforeOmer;

  /// האם אנחנו אחרי סיום ספירת העומר (אחרי 20 במאי 2026 בלילה)
  final bool afterOmer;

  const OmerDay({
    this.dayNumber,
    this.beforeOmer = false,
    this.afterOmer = false,
  });

  /// המחרוזת המלאה של הספירה (לדוגמה: "הַיּוֹם שְׁמוֹנָה יָמִים...")
  String get countText {
    if (dayNumber == null) return "";
    return omerCounts[dayNumber! - 1];
  }

  /// מספר השבועות השלמים
  int get weeks => (dayNumber ?? 0) ~/ 7;

  /// מספר הימים בשבוע הנוכחי (אחרי השבועות השלמים)
  int get daysInCurrentWeek => (dayNumber ?? 0) % 7;

  /// האם זה יום בעומר
  bool get isCounting => dayNumber != null && !beforeOmer && !afterOmer;
}
