import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

/// בודק הרשאת התראות במערכת. אם פתוחה — מחזיר true.
/// אם כבויה — מציג דיאלוג בסגנון האפליקציה עם כפתור פתיחת הגדרות,
/// ומחזיר false. נועד לעטוף לחיצות "הפעל התראה" בכל המסכים.
Future<bool> ensureNotificationPermission(BuildContext context) async {
  if (await NotificationService.areNotificationsEnabled()) return true;

  if (!context.mounted) return false;
  await showDialog<void>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.6),
    builder: (ctx) => const _PermissionDialog(),
  );
  return false;
}

class _PermissionDialog extends StatelessWidget {
  const _PermissionDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: GlassCard(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 18),
          borderRadius: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentGold.withOpacity(0.14),
                  border: Border.all(
                      color: AppColors.accentGold.withOpacity(0.4)),
                ),
                child: const Icon(
                  Icons.notifications_off_outlined,
                  color: AppColors.accentGold,
                  size: 32,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                "ההתראות כבויות",
                textAlign: TextAlign.center,
                style: AppFonts.liturgical(
                  size: 22,
                  weight: FontWeight.w700,
                  color: AppColors.goldSoft,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "כדי להפעיל תזכורות צריך לאשר התראות לאפליקציה בהגדרות הטלפון.\n"
                "מהמסך שייפתח — סמן ״הצג התראות״ ואז חזור לאפליקציה.",
                textAlign: TextAlign.center,
                style: AppFonts.ui(
                  size: 14,
                  color: AppColors.textSecondary,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await NotificationService.openSystemNotificationSettings();
                  },
                  icon: const Icon(Icons.settings, size: 18),
                  label: Text(
                    "פתיחת הגדרות",
                    style: AppFonts.ui(
                      size: 16,
                      weight: FontWeight.w800,
                      color: AppColors.bgDeep,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGold,
                    foregroundColor: AppColors.bgDeep,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  "לא עכשיו",
                  style: AppFonts.ui(
                    size: 14,
                    color: AppColors.textMuted,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
