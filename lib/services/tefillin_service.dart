import '../models/city_preset.dart';
import 'jewish_day_service.dart';

/// כללי הלכת תפילין לבני עדות המזרח.
///
/// מקורות (סיכום קצר):
/// - שבת ויום טוב: לא מניחים (שו"ע או"ח סי' לא). יו"ט כולל פסח, שבועות, סוכות,
///   ראש השנה, יום כיפור, שמיני עצרת, שמחת תורה.
/// - חול המועד פסח וסוכות: לדעת מרן השו"ע ומנהג ספרד - לא מניחים תפילין
///   (בניגוד למנהג אשכנז שחלקם מניחים בלי ברכה).
/// - ראש חודש: מניחים שחרית, חולצים לפני מוסף.
/// - תשעה באב: לא מניחים בשחרית (מנהג), מניחים במנחה עם ברכה.
/// - חנוכה, פורים, ר"ח טבת, ימים אחרים: מניחים כרגיל.
enum TefillinStatus {
  /// יום רגיל - מניחים תפילין בשחרית
  wearMorning,

  /// ראש חודש - מניחים שחרית, להוריד לפני מוסף
  wearRoshChodesh,

  /// תשעה באב - לא מניחים שחרית, מניחים במנחה
  wearTishaBavMincha,

  /// שבת - לא מניחים
  skipShabbat,

  /// יום טוב - לא מניחים
  skipYomTov,

  /// חול המועד (פסח/סוכות) לפי מנהג עדות המזרח - לא מניחים
  skipCholHamoed,
}

class TefillinDecision {
  final TefillinStatus status;
  final String title;
  final String? subtitle;

  const TefillinDecision({
    required this.status,
    required this.title,
    this.subtitle,
  });

  /// האם יש להניח תפילין היום (בכלל - בשחרית או במנחה)
  bool get shouldWearToday =>
      status == TefillinStatus.wearMorning ||
      status == TefillinStatus.wearRoshChodesh ||
      status == TefillinStatus.wearTishaBavMincha;

  /// האם יש להניח *בבוקר* (לצורך תזכורת בוקר)
  bool get shouldWearMorning =>
      status == TefillinStatus.wearMorning ||
      status == TefillinStatus.wearRoshChodesh;
}

class TefillinService {
  /// מחזיר החלטה ליום נתון. ברירת מחדל - היום.
  static TefillinDecision decide({
    required CityPreset city,
    DateTime? date,
  }) {
    final d = JewishDayService(city: city, date: date);

    if (d.isShabbat) {
      return const TefillinDecision(
        status: TefillinStatus.skipShabbat,
        title: "שבת קודש",
        subtitle: "לא מניחים תפילין בשבת",
      );
    }

    if (d.isYomTovAssurBemelacha) {
      return TefillinDecision(
        status: TefillinStatus.skipYomTov,
        title: d.dayLabel,
        subtitle: "לא מניחים תפילין ביום טוב",
      );
    }

    // מנהג עדות המזרח: לא מניחים תפילין בחוה"מ פסח וסוכות.
    if (d.isCholHamoedPesach || d.isCholHamoedSuccos) {
      return TefillinDecision(
        status: TefillinStatus.skipCholHamoed,
        title: d.dayLabel,
        subtitle: "למנהג עדות המזרח - לא מניחים תפילין בחול המועד",
      );
    }

    if (d.isTishaBav) {
      return const TefillinDecision(
        status: TefillinStatus.wearTishaBavMincha,
        title: "תשעה באב",
        subtitle: "לא מניחים בשחרית. מניחים במנחה עם ברכה.",
      );
    }

    if (d.isRoshChodesh) {
      return const TefillinDecision(
        status: TefillinStatus.wearRoshChodesh,
        title: "ראש חודש",
        subtitle: "מניחים שחרית, להוריד לפני מוסף",
      );
    }

    return const TefillinDecision(
      status: TefillinStatus.wearMorning,
      title: "זמן תפילין",
      subtitle: null,
    );
  }
}
