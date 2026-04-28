import 'package:flutter/material.dart';

import '../services/chizuk_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import 'chizuk_screen.dart';

/// מסך הסכמה חד-פעמי לפיצ'ר "חיזוק יומי". מוצג בכניסה הראשונה בלבד.
class ChizukConsentScreen extends StatelessWidget {
  const ChizukConsentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: IconButton(
                      icon: const Icon(Icons.close,
                          color: AppColors.textPrimary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.favorite_outline,
                      color: AppColors.goldSoft, size: 56),
                  const SizedBox(height: 16),
                  Text(
                    "חיזוק יומי",
                    textAlign: TextAlign.center,
                    style: AppFonts.liturgical(
                      size: 32,
                      weight: FontWeight.w800,
                      color: AppColors.goldSoft,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "פיצ'ר חבוי לעידוד התמדה אישית.",
                    textAlign: TextAlign.center,
                    style: AppFonts.ui(
                      size: 14,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 22),
                  GlassCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 18),
                    borderRadius: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionLabel("מה יש כאן"),
                        const SizedBox(height: 8),
                        _line("שני כפתורים יומיים — בלי שיפוט."),
                        const SizedBox(height: 10),
                        _line("רצף נוכחי, שיא־כל־הזמנים וציוני דרך."),
                        const SizedBox(height: 10),
                        _line("ציטוטים מחזקים מחז\"ל ומגדולי הדור."),
                        const SizedBox(height: 16),
                        _sectionLabel("מה אין"),
                        const SizedBox(height: 8),
                        _line("אין שיתוף. הכל נשאר על המכשיר שלך."),
                        const SizedBox(height: 10),
                        _line("אין איפוס. סופרים קדימה, לעולם לא חוזרים אחורה."),
                        const SizedBox(height: 10),
                        _line(
                            "אין שום מקום בתפריט או בחיפוש — נכנסים רק מי שמחפש."),
                      ],
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () async {
                      await ChizukService.giveConsent();
                      if (!context.mounted) return;
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                            builder: (_) => const ChizukScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGold,
                      padding:
                          const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      "המשך",
                      style: AppFonts.ui(
                        size: 17,
                        weight: FontWeight.w800,
                        color: AppColors.bgDeep,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      "לא עכשיו",
                      style: AppFonts.ui(
                        size: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String s) {
    return Text(
      s,
      style: AppFonts.ui(
        size: 12,
        weight: FontWeight.w800,
        color: AppColors.goldSoft,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _line(String s) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8, left: 10),
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            color: AppColors.goldSoft,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Text(
            s,
            style: AppFonts.ui(
              size: 14,
              color: AppColors.textPrimary,
              height: 1.55,
            ),
          ),
        ),
      ],
    );
  }
}
