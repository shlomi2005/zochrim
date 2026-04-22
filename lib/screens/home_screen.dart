import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/compliments.dart';
import '../models/city_preset.dart';
import '../models/omer_day.dart';
import '../services/jewish_day_service.dart';
import '../services/notification_service.dart';
import '../services/omer_service.dart';
import '../services/preferences_service.dart';
import '../services/profile_service.dart';
import '../services/tefillin_service.dart';
import '../theme/app_theme.dart';
import '../widgets/blessing_dialog.dart';
import '../widgets/counted_animation.dart';
import '../widgets/glass_card.dart';
import '../widgets/harachaman_dialog.dart';
import '../widgets/omer_card.dart';
import '../widgets/progress_grid.dart';
import '../widgets/tefillin_card.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // מצב עומר
  late OmerDay _omerDay;
  int? _lastCountedDay;
  int _reminderHour = 20;
  int _reminderMinute = 15;

  // מצב תפילין
  late TefillinDecision _tefillinDecision;
  late JewishDayService _jewishDay;
  bool _tefillinDoneToday = false;
  int _tefillinStreak = 0;

  // פרופיל
  String? _userName;
  CityPreset _city = CityPreset.jerusalem;

  bool _loading = true;
  OverlayEntry? _overlay;

  // easter egg - 7 לחיצות על הכותרת מוביל לאבחון
  int _headerTapCount = 0;
  DateTime _lastHeaderTap = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _omerDay = OmerService.computeDay();
    _load();
  }

  Future<void> _load() async {
    final last = await PreferencesService.getLastCountedDayNumber();
    final rh = await PreferencesService.getReminderHour();
    final rm = await PreferencesService.getReminderMinute();
    final name = await ProfileService.getName();
    final city = await ProfileService.getCity();
    final tefillinDone = await PreferencesService.hasDoneTefillinToday();
    final streak = await PreferencesService.getTefillinStreak();

    setState(() {
      _lastCountedDay = last;
      _reminderHour = rh;
      _reminderMinute = rm;
      _userName = name;
      _city = city;
      _jewishDay = JewishDayService(city: city);
      _tefillinDecision = TefillinService.decide(city: city);
      _tefillinDoneToday = tefillinDone;
      _tefillinStreak = streak;
      _loading = false;
    });
  }

  Future<void> _openSettings() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    if (changed == true) {
      await _load();
    }
  }

  bool get _alreadyCountedToday {
    if (!_omerDay.isCounting) return false;
    return _lastCountedDay != null && _lastCountedDay! >= _omerDay.dayNumber!;
  }

  Future<void> _onCountedPressed() async {
    if (!_omerDay.isCounting) return;
    final day = _omerDay.dayNumber!;
    final compliment = compliments[math.Random().nextInt(compliments.length)];

    try {
      HapticFeedback.mediumImpact();
      await PreferencesService.markCounted(day, OmerService.dateForDay(day));
      try {
        await NotificationService.cancelDay(day);
      } catch (e) {
        debugPrint("cancelDay err: $e");
      }
    } catch (e) {
      debugPrint("mark counted err: $e");
    }

    if (!mounted) return;
    setState(() {
      _lastCountedDay = day;
    });

    try {
      _showCountedOverlay(compliment);
    } catch (e) {
      debugPrint("overlay err: $e");
      _snack("ספרת ✓  $compliment");
    }
  }

  Future<void> _onTefillinPressed() async {
    try {
      HapticFeedback.mediumImpact();
      await PreferencesService.markTefillinDone();
      try {
        await NotificationService.cancelTefillinToday();
      } catch (e) {
        debugPrint("cancel tefillin err: $e");
      }
    } catch (e) {
      debugPrint("mark tefillin err: $e");
    }

    if (!mounted) return;
    final streak = await PreferencesService.getTefillinStreak();
    if (!mounted) return;

    setState(() {
      _tefillinDoneToday = true;
      _tefillinStreak = streak;
    });

    final name = _userName ?? "";
    final greet = name.isNotEmpty ? "כל הכבוד, $name" : "כל הכבוד";
    _snack(streak >= 3
        ? "✓ $greet - $streak ימים ברציפות 🔥"
        : "✓ $greet. המצווה נעשתה.");
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.bgMid,
        duration: const Duration(seconds: 3),
        content: Text(
          msg,
          style: AppFonts.ui(size: 15, color: AppColors.goldSoft),
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }

  void _showCountedOverlay(String compliment) {
    _overlay?.remove();
    _overlay = OverlayEntry(
      builder: (_) => CountedAnimation(
        compliment: compliment,
        onDone: () {
          _overlay?.remove();
          _overlay = null;
        },
      ),
    );
    Overlay.of(context).insert(_overlay!);
  }

  // easter egg: 7 טאפים על הכותרת תוך 3 שניות פותחים אבחון
  void _onHeaderTap() {
    final now = DateTime.now();
    if (now.difference(_lastHeaderTap).inSeconds > 3) {
      _headerTapCount = 0;
    }
    _headerTapCount += 1;
    _lastHeaderTap = now;
    if (_headerTapCount >= 7) {
      _headerTapCount = 0;
      _openDiagnostics();
    }
  }

  Future<void> _openDiagnostics() async {
    final diag = await NotificationService.diagnose();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bgMid,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return _DiagnosticsSheet(initial: diag);
      },
    );
  }

  String _formatTime(int h, int m) =>
      "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.bgDeep,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.accentGold)),
      );
    }

    final showOmer = _omerDay.isCounting;

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(),
                const SizedBox(height: 20),

                // כרטיס תפילין - הגיבור הראשי כל השנה
                TefillinCard(
                  decision: _tefillinDecision,
                  dayService: _jewishDay,
                  doneToday: _tefillinDoneToday,
                  streak: _tefillinStreak,
                  onMarkDone: _onTefillinPressed,
                  userName: _userName,
                ),

                // ספירת העומר - רק בעונה (49 ימים)
                if (showOmer) ...[
                  const SizedBox(height: 16),
                  _omerSection(),
                ],

                const SizedBox(height: 16),

                // זמני היום - תמיד
                _zmanimCard(),

                // הדלקת נרות - רק לקראת שבת/יו"ט
                if (_jewishDay.isTomorrowShabbatOrYomTov &&
                    _jewishDay.candleLighting != null) ...[
                  const SizedBox(height: 14),
                  _candleLightingCard(),
                ],

                const SizedBox(height: 24),
                _reminderFooter(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final hour = DateTime.now().hour;
    final name = _userName;
    final comma = (name != null && name.isNotEmpty) ? ", $name" : "";
    String greeting = "ערב טוב$comma";
    if (hour >= 5 && hour < 12) {
      greeting = "בוקר טוב$comma";
    } else if (hour >= 12 && hour < 17) {
      greeting = "צהריים טובים$comma";
    } else if (hour >= 17 && hour < 20) {
      greeting = "ערב מבורך$comma";
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_outlined,
                color: AppColors.textSecondary),
            tooltip: "הגדרות",
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _onHeaderTap,
              child: Column(
                children: [
                  Text(greeting,
                      textAlign: TextAlign.center,
                      style: AppFonts.ui(
                          size: 22,
                          weight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(_dateLine(),
                      textAlign: TextAlign.center,
                      style: AppFonts.ui(
                          size: 13,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.4)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  String _dateLine() {
    final now = DateTime.now();
    final cityName = _city.displayName;
    const months = [
      "ינואר", "פברואר", "מרץ", "אפריל", "מאי", "יוני",
      "יולי", "אוגוסט", "ספטמבר", "אוקטובר", "נובמבר", "דצמבר"
    ];
    return "${now.day} ב${months[now.month - 1]} · $cityName";
  }

  Widget _omerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OmerCard(omerDay: _omerDay, userName: _userName),
        const SizedBox(height: 14),
        _countedButton(),
        const SizedBox(height: 12),
        _twoCardsRow(),
        const SizedBox(height: 14),
        _progressSection(),
      ],
    );
  }

  Widget _countedButton() {
    final disabled = !_omerDay.isCounting || _alreadyCountedToday;
    final label = _alreadyCountedToday
        ? "✓ ספרת הערב"
        : (!_omerDay.isCounting ? "—" : "ספרתי הערב ✓");

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: disabled ? null : _onCountedPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: _alreadyCountedToday
              ? const LinearGradient(colors: [
                  Color(0xFF2d5f3f),
                  Color(0xFF4a7c59),
                ])
              : (_omerDay.isCounting
                  ? AppColors.goldGradient
                  : LinearGradient(colors: [
                      Colors.grey.shade700,
                      Colors.grey.shade600
                    ])),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (!disabled)
              BoxShadow(
                color: AppColors.accentGold.withOpacity(0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: AppFonts.ui(
                size: 18,
                weight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.8),
          ),
        ),
      ),
    );
  }

  Widget _twoCardsRow() {
    return Row(
      children: [
        Expanded(
          child: _smallActionCard(
            icon: Icons.auto_stories_outlined,
            label: "הצג כוונה",
            onTap: () => showDialog(
                context: context,
                builder: (_) =>
                    BlessingDialog(dayNumber: _omerDay.dayNumber)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _smallActionCard(
            icon: Icons.spa_outlined,
            label: "אחרי הספירה",
            onTap: () => showDialog(
                context: context, builder: (_) => const HarachamanDialog()),
          ),
        ),
      ],
    );
  }

  Widget _smallActionCard(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        borderRadius: 18,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.goldSoft, size: 24),
            const SizedBox(height: 6),
            Text(label,
                style: AppFonts.ui(
                    size: 14,
                    weight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _progressSection() {
    final current = _omerDay.isCounting ? _omerDay.dayNumber! : 0;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("מסע הספירה",
                  style: AppFonts.ui(
                      size: 14,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5)),
              Text(
                  "${_lastCountedDay ?? 0} / 49",
                  style: AppFonts.ui(
                      size: 14,
                      weight: FontWeight.w700,
                      color: AppColors.goldSoft)),
            ],
          ),
          const SizedBox(height: 12),
          ProgressGrid(
            currentDay: current,
            lastCountedDay: _lastCountedDay,
          ),
        ],
      ),
    );
  }

  Widget _zmanimCard() {
    final items = <_ZmanLine>[
      _ZmanLine("זריחה", _jewishDay.sunrise),
      _ZmanLine("חצות", _jewishDay.chatzos),
      _ZmanLine("מנחה גדולה", _jewishDay.minchaGedola),
      _ZmanLine("שקיעה", _jewishDay.sunset),
      _ZmanLine("צאת הכוכבים", _jewishDay.tzais),
    ];

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.wb_twilight,
                  color: AppColors.goldSoft, size: 18),
              const SizedBox(width: 8),
              Text(
                "זמני ${_city.displayName}",
                style: AppFonts.ui(
                  size: 14,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(_zmanRow),
        ],
      ),
    );
  }

  Widget _zmanRow(_ZmanLine z) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(z.label,
              style: AppFonts.ui(
                size: 14,
                color: AppColors.textSecondary,
              )),
          const Spacer(),
          Text(
            z.formatted,
            style: AppFonts.ui(
              size: 15,
              color: AppColors.textPrimary,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _candleLightingCard() {
    final t = _jewishDay.candleLighting;
    if (t == null) return const SizedBox.shrink();
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      borderRadius: 18,
      fillColor: AppColors.accentGold.withOpacity(0.08),
      borderColor: AppColors.accentGold.withOpacity(0.3),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department,
              color: AppColors.accentGold, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "הדלקת נרות היום",
              style: AppFonts.ui(
                size: 15,
                color: AppColors.textPrimary,
                weight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            _formatTimeOf(t),
            style: AppFonts.ui(
              size: 18,
              color: AppColors.goldSoft,
              weight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeOf(DateTime t) =>
      "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";

  Widget _reminderFooter() {
    return GestureDetector(
      onTap: _openSettings,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        borderRadius: 16,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.alarm,
                color: AppColors.textMuted, size: 16),
            const SizedBox(width: 8),
            Text(
              _omerDay.isCounting
                  ? "תזכורת עומר: ${_formatTime(_reminderHour, _reminderMinute)}"
                  : "הגדרות תזכורות",
              style: AppFonts.ui(
                  size: 13,
                  weight: FontWeight.w500,
                  color: AppColors.textMuted),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_left,
                color: AppColors.textMuted, size: 16),
          ],
        ),
      ),
    );
  }
}

class _ZmanLine {
  final String label;
  final DateTime? time;
  _ZmanLine(this.label, this.time);

  String get formatted {
    final t = time;
    if (t == null) return "—";
    return "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
  }
}

/// לוח אבחון להתראות - מוצג דרך showModalBottomSheet.
class _DiagnosticsSheet extends StatefulWidget {
  final NotificationDiagnostic initial;
  const _DiagnosticsSheet({required this.initial});

  @override
  State<_DiagnosticsSheet> createState() => _DiagnosticsSheetState();
}

class _DiagnosticsSheetState extends State<_DiagnosticsSheet> {
  late NotificationDiagnostic _diag;
  String? _statusMsg;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _diag = widget.initial;
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
      _statusMsg = "✓ תוזמנו מחדש כל ההתראות (עומר + תפילין).";
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
    final pendingPreview = _diag.pendingIds.take(8).join(", ");
    final pendingSuffix =
        _diag.pendingIds.length > 8 ? "... (סך הכל ${_diag.pendingCount})" : "";

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text("אבחון התראות",
                textAlign: TextAlign.center,
                style: AppFonts.ui(
                    size: 20,
                    weight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            _row("הרשאת התראות (Android 13+)",
                _boolLabel(_diag.notificationsEnabled),
                _boolColor(_diag.notificationsEnabled)),
            const SizedBox(height: 8),
            _row("אזעקות מדויקות (SCHEDULE_EXACT_ALARM)",
                _boolLabel(_diag.canScheduleExactAlarms),
                _boolColor(_diag.canScheduleExactAlarms)),
            const SizedBox(height: 8),
            _row(
                "התראות מתוזמנות בתור",
                "${_diag.pendingCount}${_diag.pendingCount > 0 ? " (ids: $pendingPreview$pendingSuffix)" : ""}",
                AppColors.goldSoft),
            const SizedBox(height: 18),
            if (_statusMsg != null) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.bgLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_statusMsg!,
                    textDirection: TextDirection.rtl,
                    style: AppFonts.ui(
                        size: 14, color: AppColors.textPrimary, height: 1.5)),
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
              "אם ההתראה המיידית לא מגיעה - הבעיה בהרשאות או באופטימיזציית סוללה של אנדרואיד.",
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
