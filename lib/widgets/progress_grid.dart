import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// רשת 7×7 של כוכבים - הימים שנספרו דולקים בזהב, העתידיים עמומים
class ProgressGrid extends StatelessWidget {
  final int currentDay; // 0 = עוד לא, 1-49 יום נוכחי בעומר
  final int? lastCountedDay; // מה שהמשתמש לחץ עליו "ספרתי"

  const ProgressGrid({
    super.key,
    required this.currentDay,
    this.lastCountedDay,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      const spacing = 6.0;
      // 7 עמודות
      final cell = (constraints.maxWidth - spacing * 6) / 7;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        textDirection: TextDirection.ltr, // נייצר את הרשת בכיוון קבוע מ-1 שמאל עליון
        children: List.generate(49, (i) {
          final day = i + 1;
          final counted = lastCountedDay != null && day <= lastCountedDay!;
          final isToday = day == currentDay;
          final inRange = day <= currentDay;
          return _Star(
            size: cell,
            counted: counted,
            inRange: inRange,
            isToday: isToday,
            dayNumber: day,
          );
        }),
      );
    });
  }
}

class _Star extends StatelessWidget {
  final double size;
  final bool counted;
  final bool inRange;
  final bool isToday;
  final int dayNumber;

  const _Star({
    required this.size,
    required this.counted,
    required this.inRange,
    required this.isToday,
    required this.dayNumber,
  });

  @override
  Widget build(BuildContext context) {
    // ניתן משמעות חזותית:
    // counted → זהב מלא, ברק
    // inRange אבל לא counted → עדיין בעבר/היום אבל לא סומן → גוון חם חלש
    // עתידי → נקודה כהה

    Color fill;
    Color glow;
    if (counted) {
      fill = AppColors.accentGold;
      glow = AppColors.accentGold.withOpacity(0.55);
    } else if (isToday) {
      fill = AppColors.accentGold.withOpacity(0.55);
      glow = AppColors.accentGold.withOpacity(0.35);
    } else if (inRange) {
      fill = AppColors.accentRose.withOpacity(0.35);
      glow = Colors.transparent;
    } else {
      fill = Colors.white.withOpacity(0.10);
      glow = Colors.transparent;
    }

    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Container(
          width: size * 0.75,
          height: size * 0.75,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fill,
            border: isToday
                ? Border.all(color: AppColors.goldSoft, width: 1.5)
                : null,
            boxShadow: glow != Colors.transparent
                ? [
                    BoxShadow(
                      color: glow,
                      blurRadius: 8,
                      spreadRadius: 0.5,
                    ),
                  ]
                : null,
          ),
          child: counted
              ? const Icon(Icons.auto_awesome,
                  size: 9, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}
