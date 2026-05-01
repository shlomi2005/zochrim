/// מערכת מילסטונים ותארים למסך החיזוק.
/// מבוסס על מחקר התנהגותי: Progress Principle + Endowed Progress Effect +
/// Identity-Based Habits (Clear). תואר מתפתח מחזק זהות,
/// מילסטונים יוצרים דופמין של ציפייה.

class ChizukMilestone {
  final int days;
  final String title; // "יום ראשון" / "7 ימים" וכו' - לכרטיס החגיגה
  final String subtitle; // משפט קצר שמסביר למה זה משמעותי
  final String quote; // ציטוט מיוחד למילסטון הזה
  final String? medalAsset; // נתיב למדליה. null = אייקון גנרי בלבד.
  const ChizukMilestone({
    required this.days,
    required this.title,
    required this.subtitle,
    required this.quote,
    this.medalAsset,
  });
}

const List<ChizukMilestone> chizukMilestones = [
  ChizukMilestone(
    days: 1,
    title: "היום הראשון",
    subtitle: "הצעד הראשון הוא הכי חשוב",
    quote:
        "כל התחלה קשה — ואתה כבר כאן. זה לבד שווה הכל.",
  ),
  ChizukMilestone(
    days: 3,
    title: "3 ימים",
    subtitle: "הוכחת לעצמך שזה אפשרי",
    quote:
        "שלושה ימים זה לא מקרה. זו בחירה שחוזרת על עצמה — ובחירה יוצרת אדם.",
    medalAsset: "assets/medals/01_nitzan_3days.png",
  ),
  ChizukMilestone(
    days: 7,
    title: "שבוע שלם",
    subtitle: "שבוע — כמו בריאת העולם",
    quote:
        "'שבע יפול צדיק וקם' — והקימה היא הניצחון, לא הנפילה. שבוע של קימה זה אור גדול.",
    medalAsset: "assets/medals/02_shavua_7days.png",
  ),
  ChizukMilestone(
    days: 14,
    title: "שבועיים",
    subtitle: "ההרגל מתחיל להיקבע",
    quote:
        "שבועיים — המוח כבר מזהה את הנתיב החדש. כל יום הבא יהיה קל יותר.",
    medalAsset: "assets/medals/03_shtei_shavuot_14days.png",
  ),
  ChizukMilestone(
    days: 21,
    title: "21 ימים",
    subtitle: "הזמן שבו הרגל נהיה טבע שני",
    quote:
        "21 ימים. אתה לא סתם עושה — אתה כבר *הוא*. אדם שמתגבר, זו הזהות שלך עכשיו.",
    medalAsset: "assets/medals/04_chodesh_baderech_21days.png",
  ),
  ChizukMilestone(
    days: 30,
    title: "חודש מלא",
    subtitle: "חודש שלם של ניצחונות",
    quote:
        "חודש. זה שינוי אמיתי. תסתכל אחורה ותראה — אתה כבר לא אותו אדם שהתחיל.",
    medalAsset: "assets/medals/05_chodesh_shalem_30days.png",
  ),
  ChizukMilestone(
    days: 50,
    title: "חמישים יום",
    subtitle: "כמו ספירת העומר — חצי הדרך לחירות פנימית",
    quote:
        "50 יום זה זמן של בנייה — כמו מיציאת מצרים עד מתן תורה. אתה בונה את עצמך מחדש.",
    medalAsset: "assets/medals/06_chamishim_50days.png",
  ),
  ChizukMilestone(
    days: 100,
    title: "100 ימים",
    subtitle: "שלושה ספרות של כוח",
    quote:
        "100. מספר עגול. כמו 100 ברכות ליום. אתה בונה משהו קדוש.",
    medalAsset: "assets/medals/07_meah_yom_100days.png",
  ),
  ChizukMilestone(
    days: 180,
    title: "חצי שנה",
    subtitle: "שישה חודשים ברציפות",
    quote:
        "חצי שנה. לאורך הדרך עברת ימים קלים וימים קשים — ובחרת. כל יום. זו גדלות.",
  ),
  ChizukMilestone(
    days: 365,
    title: "שנה שלמה",
    subtitle: "הקפת שמש של ניצחון",
    quote:
        "שנה. עברת את כל העונות, החגים, הלחץ, השמחה — עם ראש מורם. אין מילים.",
  ),
];

/// מחזיר את המילסטון הבא שהמשתמש עוד לא הגיע אליו, או null אם הגיע לכולם.
ChizukMilestone? nextMilestoneAfter(int currentRun) {
  for (final m in chizukMilestones) {
    if (m.days > currentRun) return m;
  }
  return null;
}

/// בודק אם הערך currentRun הוא בדיוק יום של מילסטון. מחזיר null אם לא.
ChizukMilestone? milestoneAt(int days) {
  for (final m in chizukMilestones) {
    if (m.days == days) return m;
  }
  return null;
}

/// תואר מתפתח — מבוסס על הרצף הארוך ביותר שהמשתמש הגיע אליו אי-פעם.
/// משתמשים ב-longestRun ולא ב-currentRun כדי שהתואר לא ייפול אם היה יום קשה.
/// זו הזהות שנבנתה — היא לא נעלמת.
String chizukTitleFor(int longestRun) {
  if (longestRun >= 365) return "בעל כתר";
  if (longestRun >= 180) return "צדיק";
  if (longestRun >= 90) return "איתן";
  if (longestRun >= 30) return "אלוף";
  if (longestRun >= 14) return "גיבור";
  if (longestRun >= 7) return "מתמיד";
  if (longestRun >= 3) return "מתאמץ";
  if (longestRun >= 1) return "התחיל";
  return "";
}

/// אמירת זהות לפי התואר — "אני מישהו ש…"
String chizukIdentityFor(int longestRun) {
  if (longestRun >= 30) return "אני מישהו ששולט בעצמו";
  if (longestRun >= 14) return "אני מישהו שמתגבר";
  if (longestRun >= 7) return "אני מישהו שמתמיד";
  if (longestRun >= 3) return "אני מישהו שלא מוותר";
  if (longestRun >= 1) return "אני מישהו שהתחיל";
  return "נתחיל יחד";
}
