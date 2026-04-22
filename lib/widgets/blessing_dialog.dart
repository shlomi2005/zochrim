import 'package:flutter/material.dart';
import '../data/omer_days.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

/// דיאלוג "הצג כוונה" - לשם יחוד + פסוקים + הברכה.
/// בליל מ"ט (יום 49) - מדלגים על הפסוקים.
class BlessingDialog extends StatelessWidget {
  final int? dayNumber; // 1-49, לצורך דילוג הפסוקים ביום 49
  const BlessingDialog({super.key, this.dayNumber});

  bool get _skipPesukim => dayNumber == 49;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.bgGradient,
          borderRadius: BorderRadius.all(Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(4),
        child: GlassCard(
          padding: const EdgeInsets.all(22),
          borderRadius: 24,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.82,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _title("לְשֵׁם יִחוּד"),
                  const SizedBox(height: 14),
                  _liturgicalText(kavvanahOpening),
                  const SizedBox(height: 22),

                  if (_skipPesukim) ...[
                    _skipNotice(),
                    const SizedBox(height: 22),
                  ] else ...[
                    _divider(),
                    const SizedBox(height: 22),
                    _sectionLabel("פסוקי הכוונה"),
                    const SizedBox(height: 12),
                    _liturgicalText(kavvanahPesukim, size: 17),
                    const SizedBox(height: 22),
                  ],

                  _divider(),
                  const SizedBox(height: 22),
                  _title("בָּרוּךְ אַתָּה יְהוָֹה"),
                  const SizedBox(height: 14),
                  _liturgicalText(blessing,
                      size: 21, weight: FontWeight.w600),
                  const SizedBox(height: 10),
                  Text(
                    "(ואז סופרים את הספירה של הלילה)",
                    textAlign: TextAlign.center,
                    style:
                        AppFonts.ui(size: 13, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 18),
                  _closeBtn(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _title(String text) {
    return ShaderMask(
      shaderCallback: (r) => AppColors.goldGradient.createShader(r),
      blendMode: BlendMode.srcIn,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppFonts.liturgical(
            size: 26, weight: FontWeight.w800, height: 1.3),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: AppFonts.ui(
        size: 13,
        color: AppColors.textSecondary,
        letterSpacing: 2,
        weight: FontWeight.w600,
      ),
    );
  }

  Widget _liturgicalText(String text,
      {double size = 18, FontWeight weight = FontWeight.w500}) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: AppFonts.liturgical(size: size, weight: weight, height: 2.0),
    );
  }

  Widget _skipNotice() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accentGold.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.accentGold.withOpacity(0.30), width: 1),
      ),
      child: Text(
        "בליל מ״ט — מדלגים על הפסוקים",
        textAlign: TextAlign.center,
        style: AppFonts.ui(
          size: 14,
          color: AppColors.goldSoft,
          weight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 1,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppColors.accentGold,
            Colors.transparent
          ],
        ),
      ),
    );
  }

  Widget _closeBtn(BuildContext context) {
    return TextButton(
      onPressed: () => Navigator.of(context).pop(),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.goldSoft,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text("סגור",
          style: AppFonts.ui(
              size: 16,
              weight: FontWeight.w600,
              color: AppColors.goldSoft)),
    );
  }
}
