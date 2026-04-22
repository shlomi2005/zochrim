import 'package:flutter/material.dart';
import '../data/omer_days.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

/// דיאלוג "אחרי הספירה" - נוסח עדות המזרח:
/// הרחמן → מזמור לַמְנַצֵּחַ (תהילים ס"ז) → אנא בכח → ברוך שם (בלחש)
class HarachamanDialog extends StatelessWidget {
  const HarachamanDialog({super.key});

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
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _title("הָרַחֲמָן"),
                  const SizedBox(height: 14),
                  _liturgical(harachaman, size: 21),

                  const SizedBox(height: 24),
                  _divider(),
                  const SizedBox(height: 22),

                  _title("לַמְנַצֵּחַ בִּנְגִינֹת"),
                  _reference("תהילים ס״ז"),
                  const SizedBox(height: 12),
                  _liturgical(psalm67, size: 17),

                  const SizedBox(height: 24),
                  _divider(),
                  const SizedBox(height: 22),

                  _title("אָֽנָּֽא בְּכֹֽחַ"),
                  const SizedBox(height: 12),
                  ...anaBekoach.map(_anaBekoachRow),

                  const SizedBox(height: 24),
                  _divider(),
                  const SizedBox(height: 22),

                  _whisperHint("ואומר בלחש"),
                  const SizedBox(height: 10),
                  _liturgical(baruchShem,
                      size: 20, weight: FontWeight.w700),

                  const SizedBox(height: 22),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.goldSoft,
                    ),
                    child: Text("אמן",
                        style: AppFonts.ui(
                            size: 16,
                            weight: FontWeight.w600,
                            color: AppColors.goldSoft)),
                  ),
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
            size: 28, weight: FontWeight.w800, height: 1.3),
      ),
    );
  }

  Widget _reference(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppFonts.ui(
          size: 12,
          color: AppColors.textMuted,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _liturgical(String text,
      {double size = 19, FontWeight weight = FontWeight.w500}) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: AppFonts.liturgical(size: size, weight: weight, height: 2.0),
    );
  }

  Widget _anaBekoachRow(Map<String, String> verse) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Text(
            verse["text"] ?? "",
            textAlign: TextAlign.center,
            style: AppFonts.liturgical(
                size: 18, weight: FontWeight.w500, height: 1.9),
          ),
          const SizedBox(height: 4),
          Text(
            "(${verse["acronym"] ?? ""})",
            textAlign: TextAlign.center,
            style: AppFonts.ui(
              size: 12,
              color: AppColors.goldSoft.withOpacity(0.75),
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _whisperHint(String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.volume_down,
            color: AppColors.textMuted, size: 16),
        const SizedBox(width: 4),
        Text(
          text,
          textAlign: TextAlign.center,
          style: AppFonts.ui(
            size: 13,
            color: AppColors.textMuted,
            letterSpacing: 1.5,
          ),
        ),
      ],
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
}
