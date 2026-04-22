import 'package:flutter/material.dart';
import '../models/omer_day.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

/// הכרטיס המרכזי - מספר היום הענק + הטקסט המלא של הספירה
class OmerCard extends StatefulWidget {
  final OmerDay omerDay;
  final String? userName;
  const OmerCard({super.key, required this.omerDay, this.userName});

  @override
  State<OmerCard> createState() => _OmerCardState();
}

class _OmerCardState extends State<OmerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.omerDay;

    if (d.beforeOmer) {
      return _messageCard("עוד לא התחלנו לספור 🌱",
          "ספירת העומר מתחילה בליל חמישי, 2 באפריל 2026");
    }
    if (d.afterOmer) {
      final name = widget.userName;
      final greet = (name != null && name.isNotEmpty)
          ? "חג שבועות שמח, $name."
          : "חג שבועות שמח.";
      return _messageCard(
        "סיימת את הספירה! 🎉",
        "$greet\nהָרַחֲמָן הוּא יַחֲזִיר לָנוּ עֲבוֹדַת בֵּית הַמִּקְדָּשׁ לִמְקוֹמָהּ.",
      );
    }

    final day = d.dayNumber!;
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      borderRadius: 32,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("היום",
              style: AppFonts.ui(
                  size: 16,
                  color: AppColors.textSecondary,
                  letterSpacing: 2)),
          const SizedBox(height: 8),

          // המספר הענק - עם פעימה וגרדיאנט זהב
          ScaleTransition(
            scale: _pulse,
            child: ShaderMask(
              shaderCallback: (rect) =>
                  AppColors.goldGradient.createShader(rect),
              blendMode: BlendMode.srcIn,
              child: Text(
                "$day",
                style: AppFonts.bigNumber(size: 140),
              ),
            ),
          ),

          const SizedBox(height: 4),

          // "לָעוֹמֶר"
          ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              colors: [AppColors.goldSoft, AppColors.accentGold],
            ).createShader(rect),
            blendMode: BlendMode.srcIn,
            child: Text(
              "לָעוֹמֶר",
              style: AppFonts.liturgical(
                size: 36,
                weight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),

          const SizedBox(height: 22),
          Container(
            height: 1,
            width: 60,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.accentGold,
                  Colors.transparent
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),

          // הטקסט המלא
          Text(
            d.countText,
            textAlign: TextAlign.center,
            style: AppFonts.liturgical(
              size: 22,
              weight: FontWeight.w500,
              color: AppColors.textPrimary,
              height: 1.9,
            ),
          ),

          if (d.weeks > 0) ...[
            const SizedBox(height: 14),
            _weekBadge(d),
          ],

          // הערה ל"ג בעומר
          if (day == 33) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_fire_department,
                    color: AppColors.accentGold, size: 18),
                const SizedBox(width: 6),
                Text("ל״ג בעומר",
                    style: AppFonts.ui(
                        size: 14,
                        weight: FontWeight.w600,
                        color: AppColors.accentGold)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _weekBadge(OmerDay d) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accentGold.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accentGold.withOpacity(0.35)),
      ),
      child: Text(
        d.daysInCurrentWeek == 0
            ? "${d.weeks} שבועות שלמים"
            : "${d.weeks} שבועות ו־${d.daysInCurrentWeek} ימים",
        style: AppFonts.ui(
            size: 13,
            color: AppColors.goldSoft,
            weight: FontWeight.w600,
            letterSpacing: 0.4),
      ),
    );
  }

  Widget _messageCard(String title, String subtitle) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      borderRadius: 32,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title,
              textAlign: TextAlign.center,
              style: AppFonts.liturgical(
                  size: 28,
                  weight: FontWeight.w700,
                  color: AppColors.goldSoft)),
          const SizedBox(height: 18),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: AppFonts.liturgical(
                  size: 18, color: AppColors.textSecondary, height: 1.8)),
        ],
      ),
    );
  }
}
