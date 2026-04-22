import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/jewish_day_service.dart';
import '../services/tefillin_service.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

/// הכרטיס המרכזי של האפליקציה - תפילין.
/// מופיע כל יום בשנה. מציג את המצב ההלכתי של היום,
/// את זמני התפילה המרכזיים, וכפתור "הנחתי תפילין".
class TefillinCard extends StatelessWidget {
  final TefillinDecision decision;
  final JewishDayService dayService;
  final bool doneToday;
  final int streak;
  final VoidCallback onMarkDone;
  final String? userName;

  const TefillinCard({
    super.key,
    required this.decision,
    required this.dayService,
    required this.doneToday,
    required this.streak,
    required this.onMarkDone,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    if (!decision.shouldWearMorning) {
      return _skipCard();
    }
    return _wearCard();
  }

  Widget _wearCard() {
    final isRoshChodesh = decision.status == TefillinStatus.wearRoshChodesh;

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
      borderRadius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // כותרת עליונה
          Row(
            children: [
              Icon(
                doneToday ? Icons.check_circle : Icons.wb_sunny_outlined,
                color: doneToday
                    ? const Color(0xFF7CCB8F)
                    : AppColors.goldSoft,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  doneToday ? "הנחת היום ✓" : "זמן תפילין",
                  style: AppFonts.ui(
                    size: 16,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.2,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
              if (streak >= 2)
                _streakBadge(),
            ],
          ),
          const SizedBox(height: 14),

          // הטקסט המרכזי
          Text(
            doneToday
                ? _doneHeadline()
                : (isRoshChodesh ? "ראש חודש" : "לא לשכוח להניח"),
            textAlign: TextAlign.center,
            style: AppFonts.liturgical(
              size: 30,
              weight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),

          if (isRoshChodesh) ...[
            const SizedBox(height: 6),
            Text(
              "להוריד לפני מוסף",
              textAlign: TextAlign.center,
              style: AppFonts.ui(
                size: 14,
                color: AppColors.goldSoft,
                weight: FontWeight.w600,
              ),
            ),
          ],

          const SizedBox(height: 18),

          // זמנים הלכתיים
          _zmanimRow(),

          const SizedBox(height: 20),

          // כפתור
          _primaryButton(),
        ],
      ),
    );
  }

  String _doneHeadline() {
    final name = userName;
    if (name != null && name.isNotEmpty) {
      return "יפה, $name.\nהמצווה נעשתה היום.";
    }
    return "יפה - המצווה נעשתה היום.";
  }

  Widget _streakBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accentGold.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accentGold.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department,
              color: AppColors.accentGold, size: 14),
          const SizedBox(width: 4),
          Text(
            "$streak",
            style: AppFonts.ui(
              size: 13,
              color: AppColors.goldSoft,
              weight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _zmanimRow() {
    final items = <_ZmanItem>[
      _ZmanItem("הנץ", dayService.sunrise),
      _ZmanItem("סו״ז ק״ש", dayService.sofZmanShma),
      _ZmanItem("סו״ז תפילה", dayService.sofZmanTfila),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((it) => _zmanCell(it)).toList(),
      ),
    );
  }

  Widget _zmanCell(_ZmanItem it) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          it.label,
          style: AppFonts.ui(
            size: 11,
            color: AppColors.textMuted,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          it.formatted,
          style: AppFonts.ui(
            size: 17,
            color: AppColors.goldSoft,
            weight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _primaryButton() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: doneToday
          ? null
          : () {
              HapticFeedback.mediumImpact();
              onMarkDone();
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: doneToday
              ? const LinearGradient(colors: [
                  Color(0xFF2d5f3f),
                  Color(0xFF4a7c59),
                ])
              : AppColors.goldGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            if (!doneToday)
              BoxShadow(
                color: AppColors.accentGold.withOpacity(0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Center(
          child: Text(
            doneToday ? "✓ הנחתי היום" : "הנחתי תפילין",
            style: AppFonts.ui(
              size: 18,
              weight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }

  Widget _skipCard() {
    final isTishaBavMincha =
        decision.status == TefillinStatus.wearTishaBavMincha;

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 28),
      borderRadius: 28,
      child: Column(
        children: [
          Icon(
            _iconForSkip(),
            color: AppColors.goldSoft,
            size: 40,
          ),
          const SizedBox(height: 14),
          Text(
            decision.title,
            textAlign: TextAlign.center,
            style: AppFonts.liturgical(
              size: 30,
              weight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (decision.subtitle != null) ...[
            const SizedBox(height: 10),
            Text(
              decision.subtitle!,
              textAlign: TextAlign.center,
              style: AppFonts.ui(
                size: 15,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ],
          if (isTishaBavMincha && dayService.minchaGedola != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.accentGold.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.accentGold.withOpacity(0.35)),
              ),
              child: Text(
                "מנחה גדולה: ${_formatTime(dayService.minchaGedola!)}",
                style: AppFonts.ui(
                  size: 15,
                  color: AppColors.goldSoft,
                  weight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _iconForSkip() {
    switch (decision.status) {
      case TefillinStatus.skipShabbat:
        return Icons.nights_stay;
      case TefillinStatus.skipYomTov:
        return Icons.celebration_outlined;
      case TefillinStatus.skipCholHamoed:
        return Icons.auto_awesome;
      case TefillinStatus.wearTishaBavMincha:
        return Icons.local_fire_department_outlined;
      default:
        return Icons.info_outline;
    }
  }
}

class _ZmanItem {
  final String label;
  final DateTime? time;
  _ZmanItem(this.label, this.time);

  String get formatted {
    final t = time;
    if (t == null) return "—";
    return _formatTime(t);
  }
}

String _formatTime(DateTime t) {
  final h = t.hour.toString().padLeft(2, '0');
  final m = t.minute.toString().padLeft(2, '0');
  return "$h:$m";
}
