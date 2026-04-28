/// נתוני מסך "אודות וקרדיטים" — מידע אפליקציה ורישיונות של ספריות צד שלישי.
/// עדכן כאן כשמעלים גרסה או מוסיפים/מסירים ספרייה.
library;

const String appDisplayName = "זוכרים";
const String appVersion = "1.0.0";
const String appAuthor = "שלומי";
const String appContactEmail = "shi053484@gmail.com";
const String appLicense = "MIT License";
const String appGithubUrl = "https://github.com/shlomi2005/zochrim";

class CreditEntry {
  final String package;
  final String version;
  final String role;
  final String license;
  const CreditEntry({
    required this.package,
    required this.version,
    required this.role,
    required this.license,
  });
}

/// ספריות ישירות (direct main) מתוך pubspec.lock.
/// ספריות transitive נכללות אוטומטית ב-LicenseRegistry של Flutter
/// ומוצגות בכפתור "רישיונות מלאים".
const List<CreditEntry> directDependencies = [
  CreditEntry(
    package: "kosher_dart",
    version: "2.0.18",
    role: "חישוב לוח שנה עברי וזמני היום (אופליין)",
    license: "LGPL-2.1",
  ),
  CreditEntry(
    package: "flutter_local_notifications",
    version: "17.2.4",
    role: "תזמון התראות מקומיות",
    license: "BSD-3-Clause",
  ),
  CreditEntry(
    package: "timezone",
    version: "0.9.4",
    role: "עבודה עם אזורי זמן",
    license: "BSD-2-Clause",
  ),
  CreditEntry(
    package: "flutter_timezone",
    version: "3.0.1",
    role: "זיהוי אזור הזמן של המכשיר",
    license: "MIT",
  ),
  CreditEntry(
    package: "google_fonts",
    version: "6.3.2",
    role: "פונטים Frank Ruhl Libre ו-Heebo (מוטבעים בזמן בנייה)",
    license: "Apache-2.0",
  ),
  CreditEntry(
    package: "shared_preferences",
    version: "2.5.3",
    role: "אחסון מקומי של העדפות המשתמש",
    license: "BSD-3-Clause",
  ),
  CreditEntry(
    package: "cupertino_icons",
    version: "1.0.8",
    role: "אייקונים בסגנון iOS",
    license: "MIT",
  ),
];
