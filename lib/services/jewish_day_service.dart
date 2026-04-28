import 'package:kosher_dart/kosher_dart.dart';

import '../models/city_preset.dart';

/// עוטף את kosher_dart ונותן ל-UI ממשק פשוט ועברי:
/// "האם היום שבת?", "האם היום יום טוב?", זמני היום לפי העיר, וכו'.
///
/// כל המצב הזה אופליין. האפליקציה מיועדת לארץ ישראל - inIsrael=true.
class JewishDayService {
  final CityPreset city;
  final DateTime date;

  late final JewishCalendar _jc;
  late final ZmanimCalendar _zc;

  JewishDayService({required this.city, DateTime? date})
      : date = date ?? DateTime.now() {
    _jc = JewishCalendar.fromDateTime(this.date)..inIsrael = true;

    // kosher_dart זורק ArgumentError אם elevation שלילי (טבריה -200).
    // ברמה של זמני חמה הגובה כמעט לא משפיע מתחת לפני הים, אז clampנו ל-0.
    final elev = city.elevationMeters < 0 ? 0.0 : city.elevationMeters;
    final geo = GeoLocation.setLocation(
      city.displayName,
      city.latitude,
      city.longitude,
      this.date,
      elev,
    );
    _zc = ZmanimCalendar.intGeolocation(geo);
    _zc.setUseElevation(true);
  }

  /// האם תאריך הלועזי הזה חל בשבת (כלומר יום ו' בערב עד מוצ"ש)
  bool get isShabbat => _jc.getDayOfWeek() == JewishDate.saturday;

  /// האם היום יום טוב (פסח, שבועות, סוכות, ר"ה, יו"כ, שמ"ע)
  bool get isYomTov => _jc.isYomTov();

  /// האם היום יו"ט שאסור במלאכה (לא כולל חנוכה/פורים ופורים שני)
  bool get isYomTovAssurBemelacha => _jc.isYomTovAssurBemelacha();

  /// האם היום חול המועד (פסח או סוכות)
  bool get isCholHamoed => _jc.isCholHamoed();
  bool get isCholHamoedPesach => _jc.isCholHamoedPesach();
  bool get isCholHamoedSuccos => _jc.isCholHamoedSuccos();

  /// האם היום תשעה באב
  bool get isTishaBav => _jc.getYomTovIndex() == JewishCalendar.TISHA_BEAV;

  /// האם היום ראש חודש
  bool get isRoshChodesh => _jc.isRoshChodesh();

  /// האם מחר שבת/יו"ט (רלוונטי להדלקת נרות)
  bool get isTomorrowShabbatOrYomTov => _jc.isTomorrowShabbosOrYomTov();

  /// האם היום אסור במלאכה (שבת או יו"ט)
  bool get isAssurBemelacha => _jc.isAssurBemelacha();

  /// שם היום בעברית - לתצוגה בכרטיס
  String get dayLabel {
    if (isShabbat) return "שבת קודש";
    if (isYomTov) {
      switch (_jc.getYomTovIndex()) {
        case JewishCalendar.PESACH:
          return "פסח";
        case JewishCalendar.SHAVUOS:
          return "שבועות";
        case JewishCalendar.ROSH_HASHANA:
          return "ראש השנה";
        case JewishCalendar.YOM_KIPPUR:
          return "יום כיפור";
        case JewishCalendar.SUCCOS:
          return "סוכות";
        case JewishCalendar.SHEMINI_ATZERES:
          return "שמיני עצרת";
        case JewishCalendar.SIMCHAS_TORAH:
          return "שמחת תורה";
      }
    }
    if (isCholHamoedPesach) return "חול המועד פסח";
    if (isCholHamoedSuccos) return "חול המועד סוכות";
    if (isTishaBav) return "תשעה באב";
    if (isRoshChodesh) return "ראש חודש";
    return "יום חול";
  }

  // ---------- זמני היום ----------

  /// עלות השחר (16.1 מעלות לפני זריחה — ברירת מחדל kosher_dart)
  DateTime? get alosHashachar => _zc.getAlosHashachar();

  /// משיכיר — זמן עטיפת טלית/הנחת תפילין (11 מעלות, נפוץ אצל ספרדים)
  late final ComplexZmanimCalendar _czc =
      ComplexZmanimCalendar.intGeoLocation(_zc.getGeoLocation());
  DateTime? get misheyakir => _czc.getMisheyakir11Degrees();

  /// זריחה (הנץ החמה)
  DateTime? get sunrise => _zc.getSunrise();

  /// שקיעה
  DateTime? get sunset => _zc.getSunset();

  /// צאת הכוכבים (8.5 מעלות, ברירת מחדל של kosher_dart)
  DateTime? get tzais => _zc.getTzais();

  /// צאת הכוכבים שיטת ר"ת (72 דקות זמניות אחרי שקיעה) — לסיום שבת מחמיר
  DateTime? get tzaisRabbeinuTam => _zc.getTzais72();

  /// חצות היום
  DateTime? get chatzos => _zc.getChatzos();

  /// סוף זמן קריאת שמע (שיטת הגר"א - ברירת מחדל למנהג ספרד)
  DateTime? get sofZmanShma => _zc.getSofZmanShmaGRA();

  /// סוף זמן קריאת שמע מג"א (72 דק' לפני זריחה ועד 72 אחרי שקיעה)
  DateTime? get sofZmanShmaMGA => _zc.getSofZmanShmaMGA();

  /// סוף זמן תפילה (שיטת הגר"א)
  DateTime? get sofZmanTfila => _zc.getSofZmanTfilaGRA();

  /// סוף זמן תפילה מג"א
  DateTime? get sofZmanTfilaMGA => _zc.getSofZmanTfilaMGA();

  /// מנחה גדולה
  DateTime? get minchaGedola => _zc.getMinchaGedola();

  /// מנחה קטנה
  DateTime? get minchaKetana => _zc.getMinchaKetana();

  /// פלג המנחה
  DateTime? get plagHamincha => _zc.getPlagHamincha();

  /// זמן הדלקת נרות (אם מחר שבת/יו"ט) - ברירת מחדל 18 דק' לפני שקיעה
  DateTime? get candleLighting => _zc.getCandleLighting();

  /// תאריך עברי מעוצב, למשל "כ״א שבט תשפ״ו".
  String get hebrewDateString {
    final f = HebrewDateFormatter();
    f.hebrewFormat = true;
    f.useGershGershayim = true;
    return f.format(_jc);
  }
}
