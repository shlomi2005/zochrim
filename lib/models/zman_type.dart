import 'package:flutter/material.dart';

import '../services/jewish_day_service.dart';

/// סוגי זמני היום שאפשר לקבל עליהם התראה מראש.
/// הסדר כאן קובע גם את הסדר בהגדרות ואת ה-ID של ההתראה.
enum ZmanType {
  alosHashachar,
  misheyakir,
  netz,
  sofZmanShmaMGA,
  sofZmanShma,
  sofZmanTfilaMGA,
  sofZmanTfila,
  chatzos,
  minchaGedola,
  minchaKetana,
  plagHamincha,
  shkia,
  tzeitHakochavim,
  tzeitRabbeinuTam,
  candleLighting,
}

class ZmanConfig {
  final ZmanType type;
  final String label;
  final String shortLabel;
  final IconData icon;
  final String notificationTitle;

  /// אם true — לא שולחים בשבת/יו"ט (אסור במלאכה). רלוונטי לרוב הזמנים.
  /// candleLighting קבוע false כי הוא חל בערב שבת/יו"ט.
  final bool silenceOnAssurBemelacha;

  /// מחשב את הזמן ליום נתון. מחזיר null אם אין זמן רלוונטי היום.
  final DateTime? Function(JewishDayService jd) compute;

  const ZmanConfig({
    required this.type,
    required this.label,
    required this.shortLabel,
    required this.icon,
    required this.notificationTitle,
    required this.silenceOnAssurBemelacha,
    required this.compute,
  });
}

final List<ZmanConfig> zmanimConfigs = [
  ZmanConfig(
    type: ZmanType.alosHashachar,
    label: "עלות השחר",
    shortLabel: "עלות השחר",
    icon: Icons.dark_mode_outlined,
    notificationTitle: "🌌 עלות השחר מתקרב",
    silenceOnAssurBemelacha: true,
    compute: (jd) => jd.alosHashachar,
  ),
  ZmanConfig(
    type: ZmanType.misheyakir,
    label: "משיכיר (טלית ותפילין)",
    shortLabel: "משיכיר",
    icon: Icons.visibility_outlined,
    notificationTitle: "👁️ זמן עטיפת טלית ותפילין",
    silenceOnAssurBemelacha: true,
    compute: (jd) => jd.misheyakir,
  ),
  ZmanConfig(
    type: ZmanType.netz,
    label: "הנץ החמה (זריחה)",
    shortLabel: "הנץ",
    icon: Icons.wb_sunny,
    notificationTitle: "🌅 הנץ החמה מתקרב",
    silenceOnAssurBemelacha: true,
    compute: (jd) => jd.sunrise,
  ),
  ZmanConfig(
    type: ZmanType.sofZmanShmaMGA,
    label: "סוף זמן ק\"ש (מג\"א)",
    shortLabel: "סוף ק\"ש מג\"א",
    icon: Icons.wb_twilight_outlined,
    notificationTitle: "📖 סוף זמן ק\"ש (מג\"א)",
    silenceOnAssurBemelacha: true,
    compute: (jd) => jd.sofZmanShmaMGA,
  ),
  ZmanConfig(
    type: ZmanType.sofZmanShma,
    label: "סוף זמן ק\"ש (גר\"א)",
    shortLabel: "סוף ק\"ש",
    icon: Icons.wb_twilight_outlined,
    notificationTitle: "📖 סוף זמן קריאת שמע מתקרב",
    silenceOnAssurBemelacha: true,
    compute: (jd) => jd.sofZmanShma,
  ),
  ZmanConfig(
    type: ZmanType.sofZmanTfilaMGA,
    label: "סוף זמן תפילה (מג\"א)",
    shortLabel: "סוף תפילה מג\"א",
    icon: Icons.auto_awesome_outlined,
    notificationTitle: "🕊️ סוף זמן תפילה (מג\"א)",
    silenceOnAssurBemelacha: true,
    compute: (jd) => jd.sofZmanTfilaMGA,
  ),
  ZmanConfig(
    type: ZmanType.sofZmanTfila,
    label: "סוף זמן תפילה (גר\"א)",
    shortLabel: "סוף תפילה",
    icon: Icons.auto_awesome_outlined,
    notificationTitle: "🕊️ סוף זמן תפילה מתקרב",
    silenceOnAssurBemelacha: true,
    compute: (jd) => jd.sofZmanTfila,
  ),
  ZmanConfig(
    type: ZmanType.chatzos,
    label: "חצות היום",
    shortLabel: "חצות",
    icon: Icons.brightness_high_outlined,
    notificationTitle: "☀️ חצות היום מתקרב",
    silenceOnAssurBemelacha: true,
    compute: (jd) => jd.chatzos,
  ),
  ZmanConfig(
    type: ZmanType.minchaGedola,
    label: "מנחה גדולה",
    shortLabel: "מנחה גדולה",
    icon: Icons.wb_sunny_outlined,
    notificationTitle: "☀️ מנחה גדולה מתקרבת",
    silenceOnAssurBemelacha: true,
    compute: (jd) => jd.minchaGedola,
  ),
  ZmanConfig(
    type: ZmanType.minchaKetana,
    label: "מנחה קטנה",
    shortLabel: "מנחה קטנה",
    icon: Icons.wb_cloudy_outlined,
    notificationTitle: "⛅ מנחה קטנה מתקרבת",
    silenceOnAssurBemelacha: true,
    compute: (jd) => jd.minchaKetana,
  ),
  ZmanConfig(
    type: ZmanType.plagHamincha,
    label: "פלג המנחה",
    shortLabel: "פלג המנחה",
    icon: Icons.brightness_4_outlined,
    notificationTitle: "🌆 פלג המנחה מתקרב",
    silenceOnAssurBemelacha: true,
    compute: (jd) => jd.plagHamincha,
  ),
  ZmanConfig(
    type: ZmanType.shkia,
    label: "שקיעה",
    shortLabel: "שקיעה",
    icon: Icons.wb_twilight,
    notificationTitle: "🌇 שקיעה מתקרבת",
    silenceOnAssurBemelacha: true,
    compute: (jd) => jd.sunset,
  ),
  ZmanConfig(
    type: ZmanType.tzeitHakochavim,
    label: "צאת הכוכבים",
    shortLabel: "צאת הכוכבים",
    icon: Icons.nights_stay_outlined,
    notificationTitle: "🌃 צאת הכוכבים מתקרב",
    silenceOnAssurBemelacha: false,
    compute: (jd) => jd.tzais,
  ),
  ZmanConfig(
    type: ZmanType.tzeitRabbeinuTam,
    label: "צאת הכוכבים (ר\"ת)",
    shortLabel: "צאת ר\"ת",
    icon: Icons.brightness_2_outlined,
    notificationTitle: "🌙 צאת ר\"ת — סיום שבת מחמיר",
    silenceOnAssurBemelacha: false,
    compute: (jd) => jd.tzaisRabbeinuTam,
  ),
  ZmanConfig(
    type: ZmanType.candleLighting,
    label: "הדלקת נרות",
    shortLabel: "הדלקת נרות",
    icon: Icons.local_fire_department_outlined,
    notificationTitle: "🕯️ הדלקת נרות מתקרבת",
    silenceOnAssurBemelacha: false,
    compute: (jd) => jd.isTomorrowShabbatOrYomTov ? jd.candleLighting : null,
  ),
];

ZmanConfig zmanConfigFor(ZmanType t) =>
    zmanimConfigs.firstWhere((c) => c.type == t);

/// אפשרויות lead time שהמשתמש יכול לבחור (בדקות).
const List<int> leadMinuteOptions = [5, 10, 15, 20, 30];
const int defaultLeadMinutes = 10;
