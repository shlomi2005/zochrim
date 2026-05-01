import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/chizuk_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/notification_permission_gate.dart';

/// הגדרות פרטיות של מסך החיזוק:
/// - שעת סוף-יום מבחינת המשתמש (חלון 24 שעות שהוא בודק את עצמו עליו).
/// - תזכורת קטנה ב-on/off, שעה, וטקסט מותאם.
/// כניסה למסך הזה רק דרך גלגל-השיניים שבמסך החיזוק.
class ChizukSettingsScreen extends StatefulWidget {
  const ChizukSettingsScreen({super.key});

  @override
  State<ChizukSettingsScreen> createState() => _ChizukSettingsScreenState();
}

class _ChizukSettingsScreenState extends State<ChizukSettingsScreen> {
  bool _loading = true;
  bool _dirty = false;

  int _dayEndHour = 0;
  int _dayEndMinute = 0;
  bool _reminderEnabled = false;
  int _reminderHour = ChizukService.defaultReminderHour;
  int _reminderMinute = ChizukService.defaultReminderMinute;
  final TextEditingController _textCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final dh = await ChizukService.getDayEndHour();
    final dm = await ChizukService.getDayEndMinute();
    final on = await ChizukService.isReminderEnabled();
    final rh = await ChizukService.getReminderHour();
    final rm = await ChizukService.getReminderMinute();
    final text = await ChizukService.getReminderText();
    if (!mounted) return;
    setState(() {
      _dayEndHour = dh;
      _dayEndMinute = dm;
      _reminderEnabled = on;
      _reminderHour = rh;
      _reminderMinute = rm;
      _textCtrl.text = text == ChizukService.defaultReminderText ? '' : text;
      _loading = false;
    });
  }

  Future<void> _save() async {
    await ChizukService.setDayEnd(_dayEndHour, _dayEndMinute);
    await ChizukService.setReminderEnabled(_reminderEnabled);
    await ChizukService.setReminderTime(_reminderHour, _reminderMinute);
    final raw = _textCtrl.text.trim();
    await ChizukService.setReminderText(
        raw.isEmpty ? ChizukService.defaultReminderText : raw);

    try {
      await NotificationService.scheduleAllChizukReminders();
    } catch (_) {}

    if (!mounted) return;
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.bgMid,
        content: Text(
          "ההגדרות נשמרו ✓",
          style: AppFonts.ui(size: 15),
          textDirection: TextDirection.rtl,
        ),
      ),
    );
    Navigator.of(context).pop(true);
  }

  Future<void> _pickDayEnd() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _dayEndHour, minute: _dayEndMinute),
      helpText: "מבחינתי יום מסתיים ב…",
    );
    if (picked == null) return;
    setState(() {
      _dayEndHour = picked.hour;
      _dayEndMinute = picked.minute;
      _dirty = true;
    });
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminderHour, minute: _reminderMinute),
      helpText: "שעת התזכורת",
    );
    if (picked == null) return;
    setState(() {
      _reminderHour = picked.hour;
      _reminderMinute = picked.minute;
      _dirty = true;
    });
  }

  String _fmt(int h, int m) =>
      "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.bgDeep,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accentGold),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              _appBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionTitle("מתי מבחינתך מסתיים יום?"),
                        _dayEndExplanation(),
                        const SizedBox(height: 10),
                        _dayEndCard(),
                        const SizedBox(height: 24),
                        _sectionTitle("תזכורת קטנה"),
                        _reminderExplanation(),
                        const SizedBox(height: 10),
                        _reminderToggleAndTimeCard(),
                        if (_reminderEnabled) ...[
                          const SizedBox(height: 12),
                          _reminderTextCard(),
                        ],
                        const SizedBox(height: 30),
                        _saveButton(),
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

  Widget _appBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_forward,
                color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(_dirty),
          ),
          Expanded(
            child: Text(
              "הגדרות חיזוק",
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

  Widget _sectionTitle(String s) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 6, right: 6),
      child: Text(
        s,
        style: AppFonts.ui(
          size: 13,
          weight: FontWeight.w700,
          color: AppColors.goldSoft,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _dayEndExplanation() {
    return Padding(
      padding: const EdgeInsets.only(right: 6, bottom: 4),
      child: Text(
        "החלון של 24 השעות שאתה בודק את עצמו עליו. "
        "אם בחרת 12:00 — היום נמדד מ־12:00 אתמול עד 12:00 היום. "
        "אחרי השעה הזו תוכל לסמן.",
        style: AppFonts.ui(
          size: 12,
          color: AppColors.textSecondary,
          height: 1.55,
        ),
      ),
    );
  }

  Widget _dayEndCard() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      borderRadius: 16,
      child: InkWell(
        onTap: _pickDayEnd,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            const Icon(Icons.access_time,
                color: AppColors.goldSoft, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("שעת סוף-יום",
                      style: AppFonts.ui(
                          size: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(
                    _fmt(_dayEndHour, _dayEndMinute),
                    style: AppFonts.ui(
                        size: 18,
                        weight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit, color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _reminderExplanation() {
    return Padding(
      padding: const EdgeInsets.only(right: 6, bottom: 4),
      child: Text(
        "תזכורת קצרה שתעלה לך בשעה שתבחר. הטקסט שתרשום הוא מה שיופיע בהתראה.\n"
        "לחיצה על ההתראה לא פותחת את מסך החיזוק — רק את האפליקציה.",
        style: AppFonts.ui(
          size: 12,
          color: AppColors.textSecondary,
          height: 1.55,
        ),
      ),
    );
  }

  Widget _reminderToggleAndTimeCard() {
    final enabled = _reminderEnabled;
    final iconColor = enabled ? AppColors.goldSoft : AppColors.textMuted;
    final timeColor =
        enabled ? AppColors.textPrimary : AppColors.textMuted;
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      borderRadius: 16,
      child: InkWell(
        onTap: enabled ? _pickReminderTime : null,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Icon(Icons.notifications_outlined, color: iconColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("תזכורת יומית",
                      style: AppFonts.ui(
                          size: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(
                    enabled ? _fmt(_reminderHour, _reminderMinute) : "כבויה",
                    style: AppFonts.ui(
                        size: 18,
                        weight: FontWeight.w700,
                        color: timeColor),
                  ),
                ],
              ),
            ),
            Switch(
              value: enabled,
              onChanged: (v) async {
                if (v && !await ensureNotificationPermission(context)) return;
                if (!mounted) return;
                setState(() {
                  _reminderEnabled = v;
                  _dirty = true;
                });
              },
              activeColor: AppColors.accentGold,
            ),
          ],
        ),
      ),
    );
  }

  Widget _reminderTextCard() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      borderRadius: 16,
      child: TextField(
        controller: _textCtrl,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        maxLength: 60,
        style: AppFonts.ui(
            size: 16,
            color: AppColors.textPrimary,
            weight: FontWeight.w500),
        onChanged: (_) => setState(() => _dirty = true),
        decoration: InputDecoration(
          border: InputBorder.none,
          counterStyle:
              AppFonts.ui(size: 11, color: AppColors.textMuted),
          hintText: "למשל: זוכר את עצמי",
          hintStyle: AppFonts.ui(size: 16, color: AppColors.textMuted),
          labelText: "מה ירשם בהתראה",
          labelStyle:
              AppFonts.ui(size: 12, color: AppColors.textSecondary),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          icon: const Icon(Icons.edit_note,
              color: AppColors.goldSoft, size: 22),
        ),
      ),
    );
  }

  Widget _saveButton() {
    return ElevatedButton(
      onPressed: _save,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentGold,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(
        "שמירה",
        style: AppFonts.ui(
          size: 16,
          weight: FontWeight.w800,
          color: AppColors.bgDeep,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
