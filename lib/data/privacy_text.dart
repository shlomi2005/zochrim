/// תוכן מסך פרטיות ותנאים - מיובא מ-PRIVACY.md ושמור מקומית.
/// תאריך תחולה ועדכון אחרון: 22 באפריל 2026.
library;

class PrivacySection {
  final String title;
  final String body;
  const PrivacySection({required this.title, required this.body});
}

const String privacyEffectiveDate = "22 באפריל 2026";
const String privacyEffectiveDateEn = "22 April 2026";
const String privacyContactEmail = "shi053484@gmail.com";

const List<PrivacySection> privacySectionsHe = [
  PrivacySection(
    title: "מי אנחנו",
    body:
        "\"זוכרים\" היא אפליקציה עברית פתוחת קוד (רישיון MIT) המיועדת "
        "לתזכורת יומית לקיום מצוות — הנחת תפילין, ספירת העומר, וזמני "
        "היום ההלכתיים. האפליקציה מפותחת ומופצת על ידי מפתח יחיד, "
        "ללא כוונת רווח.\n\nאיש קשר: $privacyContactEmail",
  ),
  PrivacySection(
    title: "איזה מידע אנחנו אוספים",
    body:
        "אנחנו לא אוספים שום מידע אישי שלך. כלום.\n\n"
        "האפליקציה פועלת באופן עצמאי על המכשיר שלך (offline) "
        "ואינה שולחת שום נתון לשרת כלשהו — לא שלנו, לא של צד שלישי.",
  ),
  PrivacySection(
    title: "איזה מידע נשמר במכשיר (ולא יוצא ממנו)",
    body:
        "האפליקציה שומרת את הפרטים הבאים באזור האחסון המקומי "
        "(SharedPreferences), בהתאם להגדרות שהזנת בעצמך:\n\n"
        "• שם לפנייה אישית (אם הזנת)\n"
        "• העיר שבחרת (לחישוב זמני היום)\n"
        "• שעות התזכורת שהגדרת (בוקר / ערב)\n"
        "• מספר ימי העומר שספרת והתאריכים המתאימים\n"
        "• מצב הנחת תפילין היומי (כולל סטריק)\n\n"
        "מידע זה לא עוזב את המכשיר שלך. אם תמחק את האפליקציה — "
        "המידע נמחק לחלוטין. אין גיבוי בענן, אין סנכרון בין מכשירים, "
        "אין שליחה לשרת.",
  ),
  PrivacySection(
    title: "הרשאות שהאפליקציה מבקשת",
    body:
        "• התראות (Notifications) — כדי לשלוח את התזכורות שהגדרת.\n"
        "• SCHEDULE_EXACT_ALARM — כדי שהתזכורות יגיעו בזמן מדויק.\n"
        "• RECEIVE_BOOT_COMPLETED — כדי שהתזכורות יעבדו גם אחרי "
        "הפעלה מחדש של המכשיר.\n\n"
        "אין בקשה למיקום, מצלמה, רשימת אנשי קשר, אחסון, "
        "או כל הרשאה אחרת.",
  ),
  PrivacySection(
    title: "שירותי צד שלישי",
    body:
        "האפליקציה משתמשת בספריות קוד פתוח הפועלות באופן מקומי בלבד "
        "ואינן מבצעות תקשורת עם שרתים חיצוניים:\n\n"
        "• kosher_dart — חישוב זמני היום ולוח השנה העברי (אופליין).\n"
        "• flutter_local_notifications — הפעלת תזכורות מקומיות.\n"
        "• google_fonts — הפונטים מוטמעים באפליקציה בזמן הבנייה "
        "ואינם נטענים מהאינטרנט בזמן ריצה.",
  ),
  PrivacySection(
    title: "פרטיות ילדים",
    body:
        "האפליקציה מתאימה לכל הגילים. מכיוון שאנחנו לא אוספים "
        "שום מידע, אין נתונים כלשהם של משתמשים קטינים.",
  ),
  PrivacySection(
    title: "שינויים במדיניות",
    body:
        "אם המדיניות תשתנה בעתיד, הגרסה המעודכנת תפורסם עם תאריך חדש. "
        "המשך שימוש באפליקציה משמעו הסכמה למדיניות המעודכנת.",
  ),
  PrivacySection(
    title: "יצירת קשר",
    body:
        "לכל שאלה בנושא פרטיות: $privacyContactEmail\n\n"
        "קוד המקור של האפליקציה פתוח וזמין לסקירה פומבית.",
  ),
];

const List<PrivacySection> privacySectionsEn = [
  PrivacySection(
    title: "Who We Are",
    body:
        "\"Zochrim\" (זוכרים) is an open-source (MIT License) Hebrew app "
        "for daily mitzvah reminders — tefillin, Omer counting, and "
        "halachic times. It is developed and distributed by a solo "
        "developer on a non-profit basis.\n\nContact: $privacyContactEmail",
  ),
  PrivacySection(
    title: "What Information We Collect",
    body:
        "We do not collect any personal information. None.\n\n"
        "The app runs entirely offline on your device and does not "
        "transmit any data to any server — not ours, not any third "
        "party's.",
  ),
  PrivacySection(
    title: "What Is Stored Locally (and Stays There)",
    body:
        "The app stores the following in your device's local app storage "
        "(SharedPreferences), based solely on what you enter yourself:\n\n"
        "• Your display name (if you entered one)\n"
        "• Your selected city (used to calculate halachic times locally)\n"
        "• Your configured reminder times (morning / evening)\n"
        "• Omer count progress and corresponding dates\n"
        "• Daily tefillin status and streak count\n\n"
        "This data never leaves your device. If you uninstall the app, "
        "the data is deleted completely. There is no cloud backup, no "
        "cross-device sync, no server transmission.",
  ),
  PrivacySection(
    title: "Permissions the App Requests",
    body:
        "• Notifications — to deliver the reminders you configured.\n"
        "• SCHEDULE_EXACT_ALARM — to deliver reminders at precise times.\n"
        "• RECEIVE_BOOT_COMPLETED — to restore scheduled reminders after "
        "device reboot.\n\n"
        "The app does not request access to location, camera, contacts, "
        "storage, or any other permission.",
  ),
  PrivacySection(
    title: "Third-Party Services",
    body:
        "The app uses open-source libraries that operate entirely locally "
        "and make no external network requests:\n\n"
        "• kosher_dart — Jewish calendar and zmanim calculations (offline).\n"
        "• flutter_local_notifications — local notification scheduling.\n"
        "• google_fonts — fonts are bundled at build time and are not "
        "fetched from the internet at runtime.",
  ),
  PrivacySection(
    title: "Children's Privacy",
    body:
        "The app is suitable for all ages. Since we collect no data, "
        "there is no user data of any minors.",
  ),
  PrivacySection(
    title: "Changes to This Policy",
    body:
        "If the policy changes in the future, the updated version will "
        "be published with a new effective date. Continued use of the "
        "app constitutes acceptance of the updated policy.",
  ),
  PrivacySection(
    title: "Contact",
    body:
        "For any privacy question: $privacyContactEmail\n\n"
        "The app source code is open and publicly available for review.",
  ),
];
