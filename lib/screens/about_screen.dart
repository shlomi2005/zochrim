import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/credits_data.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

/// מסך אודות וקרדיטים — פרטי האפליקציה, פילוסופיה, רישיונות ספריות.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              _appBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _header(),
                        const SizedBox(height: 20),
                        _dedicationCard(),
                        const SizedBox(height: 16),
                        _philosophyCard(),
                        const SizedBox(height: 16),
                        _featuresCard(),
                        const SizedBox(height: 24),
                        _sectionTitle("ספריות צד שלישי"),
                        _creditsIntro(),
                        const SizedBox(height: 10),
                        for (final c in directDependencies) ...[
                          _creditCard(c),
                          const SizedBox(height: 10),
                        ],
                        const SizedBox(height: 14),
                        _fullLicensesButton(context),
                        const SizedBox(height: 10),
                        _githubButton(context),
                        const SizedBox(height: 24),
                        _contactCard(context),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _appBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_forward,
                color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              "אודות",
              textAlign: TextAlign.center,
              style: AppFonts.ui(
                size: 20,
                weight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _header() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      borderRadius: 20,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              'assets/icon/app_icon.png',
              width: 84,
              height: 84,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            appDisplayName,
            style: AppFonts.liturgical(
              size: 28,
              weight: FontWeight.w800,
              color: AppColors.goldSoft,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "ליווי יומי לחיי מצוות",
            style: AppFonts.ui(
              size: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.glassFill,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Text(
              "גרסה $appVersion",
              style: AppFonts.ui(
                size: 12,
                weight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _philosophyCard() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite_border,
                  color: AppColors.accentRose, size: 20),
              const SizedBox(width: 8),
              Text(
                "חינם, פתוח, ללא מעקב",
                style: AppFonts.ui(
                  size: 15,
                  weight: FontWeight.w800,
                  color: AppColors.goldSoft,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "זוכרים מופצת חינם כמחווה לציבור. "
            "הקוד פתוח תחת רישיון $appLicense, "
            "האפליקציה פועלת במלואה אופליין, "
            "ואינה אוספת שום נתון אישי.",
            style: AppFonts.ui(
              size: 14,
              color: AppColors.textPrimary,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dedicationCard() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.local_fire_department_outlined,
              color: AppColors.goldSoft, size: 26),
          const SizedBox(height: 10),
          Text(
            "לעילוי נשמת",
            textAlign: TextAlign.center,
            style: AppFonts.ui(
              size: 12,
              weight: FontWeight.w800,
              color: AppColors.goldSoft,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "יששכר שלמה בן יפה",
            textAlign: TextAlign.center,
            style: AppFonts.liturgical(
              size: 18,
              weight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "ולעילוי נשמת",
            textAlign: TextAlign.center,
            style: AppFonts.ui(
              size: 12,
              weight: FontWeight.w800,
              color: AppColors.goldSoft,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "חיים בן סוליקה",
            textAlign: TextAlign.center,
            style: AppFonts.liturgical(
              size: 18,
              weight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "ת.נ.צ.ב.ה",
            style: AppFonts.ui(
              size: 11,
              weight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 2.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _featuresCard() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_outlined,
                  color: AppColors.goldSoft, size: 20),
              const SizedBox(width: 8),
              Text(
                "מה יש באפליקציה",
                style: AppFonts.ui(
                  size: 15,
                  weight: FontWeight.w800,
                  color: AppColors.goldSoft,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _featureLine("📿", "ספירת העומר",
              "ספירה יומית עם תזכורת בערב, מסונכרנת עם צאת הכוכבים בעיר שלך."),
          _featureLine("🪶", "תפילין",
              "תזכורת בוקרית, רצף ימים והתחשבות בשבת ויום טוב."),
          _featureLine("🌅", "זמני היום",
              "15 זמנים: עלות, משיכיר, הנץ, סוף ק\"ש (גר\"א/מג\"א), סוף תפילה (גר\"א/מג\"א), חצות, מנחה גדולה/קטנה, פלג, שקיעה, צאת, צאת ר\"ת והדלקת נרות."),
          _featureLine("📖", "דף יומי",
              "תזכורת ללימוד הדף היומי בבלי, בשעה שאתה בוחר."),
          _featureLine("🕯️", "שעון הלכתי",
              "האפליקציה יודעת ששקיעה מתחילה יום חדש וצאת הכוכבים מסיים שבת — כל החישובים מתאימים את עצמם."),
          _featureLine("✨", "חיזוק יומי",
              "פיצ'ר חבוי לעידוד התמדה אישית — בלי שיפוט, בלי שיתוף, הכל על המכשיר."),
        ],
      ),
    );
  }

  Widget _featureLine(String emoji, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.ui(
                    size: 14,
                    weight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: AppFonts.ui(
                    size: 12,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String s) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 10, right: 6),
      child: Text(
        s,
        style: AppFonts.ui(
          size: 13,
          weight: FontWeight.w700,
          color: AppColors.goldSoft,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _creditsIntro() {
    return Text(
      "תודה למפתחים שמאחורי הספריות האלה — הן אפשרו לבנות את זוכרים.",
      style: AppFonts.ui(
        size: 13,
        color: AppColors.textSecondary,
        height: 1.5,
      ),
    );
  }

  Widget _creditCard(CreditEntry c) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    c.package,
                    style: AppFonts.ui(
                      size: 15,
                      weight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  "v${c.version}",
                  style: AppFonts.ui(
                    size: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            c.role,
            style: AppFonts.ui(
              size: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.glassFill,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Text(
              c.license,
              style: AppFonts.ui(
                size: 11,
                weight: FontWeight.w600,
                color: AppColors.goldSoft,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fullLicensesButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        showLicensePage(
          context: context,
          applicationName: appDisplayName,
          applicationVersion: appVersion,
          applicationLegalese: "© $appAuthor\n$appLicense",
        );
      },
      icon: const Icon(Icons.description_outlined,
          color: AppColors.goldSoft, size: 20),
      label: Text(
        "רישיונות מלאים (כולל תלויות עקיפות)",
        style: AppFonts.ui(
          size: 14,
          weight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: const BorderSide(color: AppColors.goldSoft, width: 1),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _githubButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _openUrl(context, appGithubUrl),
      icon: const Icon(Icons.code, color: AppColors.goldSoft, size: 20),
      label: Text(
        "קוד פתוח ב-GitHub",
        style: AppFonts.ui(
          size: 14,
          weight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: const BorderSide(color: AppColors.goldSoft, width: 1),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _contactCard(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline,
                  color: AppColors.goldSoft, size: 18),
              const SizedBox(width: 8),
              Text(
                "פיתוח",
                style: AppFonts.ui(
                  size: 13,
                  weight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            appAuthor,
            style: AppFonts.ui(
              size: 15,
              weight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          _emailButton(context),
        ],
      ),
    );
  }

  Widget _emailButton(BuildContext context) {
    return InkWell(
      onTap: () => _openEmail(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.glassFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppColors.goldSoft.withValues(alpha: 0.45), width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.mail_outline,
                color: AppColors.goldSoft, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "יצירת קשר",
                    style: AppFonts.ui(
                      size: 12,
                      weight: FontWeight.w700,
                      color: AppColors.goldSoft,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      appContactEmail,
                      style: AppFonts.ui(
                        size: 14,
                        weight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_left,
                color: AppColors.textMuted, size: 22),
          ],
        ),
      ),
    );
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("לא הצלחתי לפתוח: $url")),
      );
    }
  }

  Future<void> _openEmail(BuildContext context) async {
    final mailto = Uri(
      scheme: 'mailto',
      path: appContactEmail,
      queryParameters: {'subject': 'זוכרים — פנייה'},
    );
    final ok = await launchUrl(mailto);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("לא הצלחתי לפתוח את אפליקציית המייל")),
      );
    }
  }
}
