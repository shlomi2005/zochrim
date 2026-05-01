import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/chizuk_milestones.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

/// כפתור צף קטן שמראה את המדליה הגבוהה ביותר שהמשתמש השיג.
/// לחיצה פותחת את "ארון המדליות" — דיאלוג עם כל המדליות,
/// כשהנעולות בצבע עמום והמשוחררות בזהב מלא.
class FloatingMedalButton extends StatefulWidget {
  /// הרצף הארוך ביותר שהמשתמש הגיע אליו אי פעם — קובע אילו מדליות נפתחו.
  final int longestRun;

  /// הרצף הנוכחי — מוצג בארון המדליות כדי להראות התקדמות.
  final int currentRun;

  const FloatingMedalButton({
    super.key,
    required this.longestRun,
    required this.currentRun,
  });

  @override
  State<FloatingMedalButton> createState() => _FloatingMedalButtonState();
}

class _FloatingMedalButtonState extends State<FloatingMedalButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambientCtrl;

  @override
  void initState() {
    super.initState();
    _ambientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ambientCtrl.dispose();
    super.dispose();
  }

  ChizukMilestone? _highestEarned() {
    ChizukMilestone? best;
    for (final m in chizukMilestones) {
      if (m.medalAsset != null && widget.longestRun >= m.days) {
        best = m;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final medal = _highestEarned();
    if (medal == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        showDialog(
          context: context,
          barrierColor: Colors.black.withOpacity(0.78),
          builder: (_) => MedalCabinetDialog(
            longestRun: widget.longestRun,
            currentRun: widget.currentRun,
          ),
        );
      },
      child: AnimatedBuilder(
        animation: _ambientCtrl,
        builder: (_, child) {
          final t = _ambientCtrl.value;
          final scale = 1.0 + 0.05 * t;
          final glowAlpha = 0.32 + 0.18 * t;
          return Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentGold.withOpacity(glowAlpha),
                  blurRadius: 22 + 6 * t,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Transform.scale(scale: scale, child: child),
          );
        },
        child: Image.asset(
          medal.medalAsset!,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

/// דיאלוג מלא ש-מציג את כל המדליות. הנעולות מוצגות בצבע עמום
/// עם המספר של הימים שצריך להגיע אליהם.
/// המדליה הגבוהה ביותר שהושגה — גדולה במרכז, עם אנימציה לכיף.
class MedalCabinetDialog extends StatefulWidget {
  final int longestRun;
  final int currentRun;

  const MedalCabinetDialog({
    super.key,
    required this.longestRun,
    required this.currentRun,
  });

  @override
  State<MedalCabinetDialog> createState() => _MedalCabinetDialogState();
}

class _MedalCabinetDialogState extends State<MedalCabinetDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinCtrl;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }

  void _playWithMedal() {
    HapticFeedback.mediumImpact();
    _spinCtrl.forward(from: 0);
  }

  ChizukMilestone? _highestEarned(List<ChizukMilestone> withMedals) {
    ChizukMilestone? best;
    for (final m in withMedals) {
      if (widget.longestRun >= m.days) best = m;
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final withMedals =
        chizukMilestones.where((m) => m.medalAsset != null).toList();
    final highest = _highestEarned(withMedals);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: GlassCard(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
          borderRadius: 26,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "ארון המדליות שלך",
                textAlign: TextAlign.center,
                style: AppFonts.liturgical(
                  size: 22,
                  weight: FontWeight.w800,
                  color: AppColors.goldSoft,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                highest == null
                    ? "המשך — המדליה הראשונה ממש קרובה"
                    : "${highest.title} • $_motivationLine",
                textAlign: TextAlign.center,
                style: AppFonts.ui(
                  size: 12,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 20),

              // מדליה גדולה במרכז — המשוחררת ביותר. אם אין — מציג את הראשונה
              // בצבע עמום כתמריץ.
              _bigCenterpiece(highest, withMedals),

              const SizedBox(height: 22),
              Container(
                height: 1,
                color: AppColors.glassBorder.withOpacity(0.6),
              ),
              const SizedBox(height: 14),

              Text(
                "כל המדליות",
                textAlign: TextAlign.center,
                style: AppFonts.ui(
                  size: 12,
                  weight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 12),

              // רשת קטנה של כל 7 המדליות
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 14,
                children: [
                  for (final m in withMedals) _smallMedalTile(m),
                ],
              ),

              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGold,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    "סגירה",
                    style: AppFonts.ui(
                      size: 15,
                      weight: FontWeight.w800,
                      color: AppColors.bgDeep,
                      letterSpacing: 0.6,
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

  String get _motivationLine {
    final next = chizukMilestones.firstWhere(
      (m) => m.medalAsset != null && m.days > widget.longestRun,
      orElse: () => chizukMilestones.last,
    );
    if (next.days <= widget.longestRun) {
      return "אספת את כל המדליות ✨";
    }
    final remaining = next.days - widget.currentRun;
    if (remaining <= 0) return "המדליה הבאה ממש כאן";
    return "עוד $remaining ימים ל${next.title}";
  }

  Widget _bigCenterpiece(
      ChizukMilestone? highest, List<ChizukMilestone> all) {
    final medal = highest ?? all.first;
    final unlocked = highest != null;

    return GestureDetector(
      onTap: unlocked ? _playWithMedal : null,
      child: AnimatedBuilder(
        animation: _spinCtrl,
        builder: (_, child) {
          final t = _spinCtrl.value;
          // ספין עם השעיה — מסתובב ועוצר עם בלימה
          final eased = Curves.easeOutCubic.transform(t);
          final angle = eased * math.pi * 2;
          final wobble = math.sin(t * math.pi) * 0.08;
          return Transform.rotate(
            angle: angle,
            child: Transform.scale(scale: 1.0 + wobble, child: child),
          );
        },
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: unlocked
                ? [
                    BoxShadow(
                      color: AppColors.accentGold.withOpacity(0.45),
                      blurRadius: 32,
                      spreadRadius: 4,
                    ),
                  ]
                : const [],
          ),
          child: ColorFiltered(
            colorFilter: unlocked
                ? const ColorFilter.mode(
                    Colors.transparent, BlendMode.dst)
                : const ColorFilter.matrix(<double>[
                    0.25, 0.25, 0.25, 0, 0,
                    0.25, 0.25, 0.25, 0, 0,
                    0.25, 0.25, 0.25, 0, 0,
                    0, 0, 0, 0.55, 0,
                  ]),
            child: Image.asset(
              medal.medalAsset!,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ),
    );
  }

  Widget _smallMedalTile(ChizukMilestone m) {
    final earned = widget.longestRun >= m.days;
    return SizedBox(
      width: 78,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: earned
                  ? [
                      BoxShadow(
                        color: AppColors.accentGold.withOpacity(0.3),
                        blurRadius: 10,
                      ),
                    ]
                  : const [],
            ),
            child: ColorFiltered(
              colorFilter: earned
                  ? const ColorFilter.mode(
                      Colors.transparent, BlendMode.dst)
                  : const ColorFilter.matrix(<double>[
                      0.2, 0.2, 0.2, 0, 0,
                      0.2, 0.2, 0.2, 0, 0,
                      0.2, 0.2, 0.2, 0, 0,
                      0, 0, 0, 0.5, 0,
                    ]),
              child: Image.asset(
                m.medalAsset!,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "${m.days} ימים",
            textAlign: TextAlign.center,
            style: AppFonts.ui(
              size: 11,
              weight: FontWeight.w700,
              color: earned ? AppColors.goldSoft : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
