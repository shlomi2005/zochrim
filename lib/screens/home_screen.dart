import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/compliments.dart';
import '../models/city_preset.dart';
import '../models/omer_day.dart';
import '../services/halachic_clock.dart';
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
import 'chizuk_consent_screen.dart';
import 'chizuk_screen.dart';
import '../services/chizuk_service.dart';
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

  // easter egg - 7 לחיצות על הכותרת פותחות את מסך החיזוק
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
    final name = await ProfileService.getName();
    final city = await ProfileService.getCity();
    final tefillinDone = await PreferencesService.hasDoneTefillinToday();
    final streak = await PreferencesService.getTefillinStreak();

    setState(() {
      _lastCountedDay = last;
      _userName = name;
      _city = city;
      _omerDay = OmerService.computeDay(city: city);
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

  // easter egg: 7 טאפים על הכותרת תוך 3 שניות פותחים "חיזוק יומי".
  // המסך מכוון לנוער שזקוקים לחיזוק בנושא התגברות עצמית. חבוי בכוונה.
  void _onHeaderTap() {
    final now = DateTime.now();
    if (now.difference(_lastHeaderTap).inSeconds > 3) {
      _headerTapCount = 0;
    }
    _headerTapCount += 1;
    _lastHeaderTap = now;
    if (_headerTapCount >= 7) {
      _headerTapCount = 0;
      _openChizuk();
    }
  }

  Future<void> _openChizuk() async {
    final consented = await ChizukService.hasConsented();
    if (!mounted) return;
    if (consented) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ChizukScreen()),
      );
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ChizukConsentScreen()),
      );
    }
  }

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
                  Text(_hebrewDateLine(),
                      textAlign: TextAlign.center,
                      style: AppFonts.liturgical(
                          size: 14,
                          weight: FontWeight.w600,
                          color: AppColors.goldSoft,
                          height: 1.3)),
                  const SizedBox(height: 2),
                  Text(_dateLine(),
                      textAlign: TextAlign.center,
                      style: AppFonts.ui(
                          size: 12,
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

  /// תאריך עברי, מודע לשעון ההלכתי — אחרי צאת הכוכבים מתקדם ליום הבא.
  String _hebrewDateLine() {
    try {
      final halachicDate = HalachicClock.halachicToday(_city);
      final jd = JewishDayService(city: _city, date: halachicDate);
      return jd.hebrewDateString;
    } catch (e) {
      debugPrint("hebrew date err: $e");
      return "";
    }
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
