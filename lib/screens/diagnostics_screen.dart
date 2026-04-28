import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import '../theme/app_theme.dart';

/// מסך אבחון התראות — כלי לבדיקת תקלות. מונגש דרך הגדרות.
class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  NotificationDiagnostic? _diag;
  String? _statusMsg;
  bool _busy = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh().then((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  Future<void> _refresh() async {
    final d = await NotificationService.diagnose();
    if (!mounted) return;
    setState(() => _diag = d);
  }

  Future<void> _runTestNow() async {
    setState(() {
      _busy = true;
      _statusMsg = null;
    });
    try {
      await NotificationService.showTestNow();
      _statusMsg = "✓ נשלחה התראה מיידית. בדוק את מגש ההתראות.";
    } catch (e) {
      _statusMsg = "✗ שגיאה: $e";
    }
    await _refresh();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _runTestInMinute() async {
    setState(() {
      _busy = true;
      _statusMsg = null;
    });
    try {
      final when = await NotificationService.scheduleTestInMinute();
      final hh = when.hour.toString().padLeft(2, '0');
      final mm = when.minute.toString().padLeft(2, '0');
      final ss = when.second.toString().padLeft(2, '0');
      _statusMsg = "✓ מתוזמן ל־$hh:$mm:$ss. השאר את המכשיר פתוח וחכה.";
    } catch (e) {
      _statusMsg = "✗ שגיאה: $e";
    }
    await _refresh();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _requestPerms() async {
    setState(() => _busy = true);
    try {
      await NotificationService.requestPermissionsAgain();
      _statusMsg = "בקשת הרשאות נשלחה. בדוק אם הופיעה חלונית הרשאה.";
    } catch (e) {
      _statusMsg = "שגיאה: $e";
    }
    await _refresh();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _rescheduleAll() async {
    setState(() => _busy = true);
    try {
      await NotificationService.scheduleAllReminders();
      _statusMsg = "✓ תוזמנו מחדש כל ההתראות.";
    } catch (e) {
      _statusMsg = "✗ שגיאה: $e";
    }
    await _refresh();
    if (mounted) setState(() => _busy = false);
  }

  String _boolLabel(bool? v) {
    if (v == null) return "לא ידוע";
    return v ? "✓ פעיל" : "✗ חסום";
  }

  Color _boolColor(bool? v) {
    if (v == null) return AppColors.textMuted;
    return v ? const Color(0xFF7CCB8F) : const Color(0xFFE27D7D);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              _appBar(),
              Expanded(
                child: _loading || _diag == null
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.accentGold))
                    : _content(_diag!),
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
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              "אבחון התראות",
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

  Widget _content(NotificationDiagnostic diag) {
    final pendingPreview = diag.pendingIds.take(8).join(", ");
    final pendingSuffix = diag.pendingIds.length > 8
        ? "... (סך הכל ${diag.pendingCount})"
        : "";

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _row("הרשאת התראות (Android 13+)",
                _boolLabel(diag.notificationsEnabled),
                _boolColor(diag.notificationsEnabled)),
            const SizedBox(height: 8),
            _row("אזעקות מדויקות (SCHEDULE_EXACT_ALARM)",
                _boolLabel(diag.canScheduleExactAlarms),
                _boolColor(diag.canScheduleExactAlarms)),
            const SizedBox(height: 8),
            _row(
                "התראות מתוזמנות בתור",
                "${diag.pendingCount}${diag.pendingCount > 0 ? " (ids: $pendingPreview$pendingSuffix)" : ""}",
                AppColors.goldSoft),
            const SizedBox(height: 18),
            if (_statusMsg != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.bgLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_statusMsg!,
                    textDirection: TextDirection.rtl,
                    style: AppFonts.ui(
                        size: 14,
                        color: AppColors.textPrimary,
                        height: 1.5)),
              ),
              const SizedBox(height: 12),
            ],
            _actionBtn(
                icon: Icons.notifications_active,
                label: "שלח התראת בדיקה עכשיו",
                onPressed: _busy ? null : _runTestNow),
            const SizedBox(height: 8),
            _actionBtn(
                icon: Icons.schedule,
                label: "תזמן התראת בדיקה לעוד דקה",
                onPressed: _busy ? null : _runTestInMinute),
            const SizedBox(height: 8),
            _actionBtn(
                icon: Icons.lock_open,
                label: "בקש הרשאות שוב",
                onPressed: _busy ? null : _requestPerms),
            const SizedBox(height: 8),
            _actionBtn(
                icon: Icons.refresh,
                label: "תזמן מחדש את כל ההתראות",
                onPressed: _busy ? null : _rescheduleAll),
            const SizedBox(height: 14),
            Text(
              "אם ההתראה המיידית לא מגיעה — הבעיה בהרשאות או באופטימיזציית סוללה של אנדרואיד.",
              textAlign: TextAlign.center,
              style: AppFonts.ui(
                  size: 12, color: AppColors.textMuted, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, Color valueColor) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: AppFonts.ui(
                  size: 14,
                  color: AppColors.textSecondary,
                  weight: FontWeight.w500)),
        ),
        const SizedBox(width: 8),
        Text(value,
            style: AppFonts.ui(
                size: 14, color: valueColor, weight: FontWeight.w700)),
      ],
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: AppColors.bgDeep),
        label: Text(label,
            style: AppFonts.ui(
                size: 15,
                weight: FontWeight.w700,
                color: AppColors.bgDeep)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.goldSoft,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
