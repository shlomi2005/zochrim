import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/chizuk_milestones.dart';
import '../data/chizuk_quotes.dart';
import '../models/chizuk_status.dart';
import '../services/chizuk_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/medal_cabinet.dart';
import 'chizuk_settings_screen.dart';

/// מסך "חיזוק יומי" — הפיצ'ר החבוי אחרי 7 הקשות על כותרת הבית.
/// עקרונות: לעולם לא מאפס, שני כפתורים חיוביים, שום בושה.
class ChizukScreen extends StatefulWidget {
  const ChizukScreen({super.key});

  @override
  State<ChizukScreen> createState() => _ChizukScreenState();
}

class _ChizukScreenState extends State<ChizukScreen>
    with TickerProviderStateMixin {
  bool _loading = true;
  ChizukStatus? _todayStatus;
  int _total = 0;
  int _currentRun = 0;
  int _longest = 0;
  Map<String, ChizukStatus> _journeyStatuses = {};
  ChizukQuote? _shownQuote;
  DateTime? _journeyStart;
  int _daysSinceStart = 1;
  DateTime _logicalToday = DateTime.now();

  late final ConfettiController _confettiCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _glowCtrl;
  bool _justMarkedOvercame = false;

  @override
  void initState() {
    super.initState();
    _confettiCtrl = ConfettiController(duration: const Duration(milliseconds: 1400));
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _load();
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    _pulseCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final today = await ChizukService.logicalToday();
    // הכניסה הראשונה למסך = יום 1 של המסע. נשמר לתמיד.
    final journeyStart = await ChizukService.ensureJourneyStarted();
    final daysSinceStart = today.difference(journeyStart).inDays + 1;

    final status = await ChizukService.getStatus(today);
    final total = await ChizukService.getTotalOvercame();
    final run = await ChizukService.getCurrentRun();
    final longest = await ChizukService.getLongestRunEver();

    // טוענים את כל הסטטוסים מתחילת המסע — לא רק 30 יום.
    final spanDays = daysSinceStart < 1 ? 1 : daysSinceStart;
    final statuses = await ChizukService.getLastDays(spanDays);

    if (!mounted) return;
    setState(() {
      _todayStatus = status;
      _total = total;
      _currentRun = run;
      _longest = longest;
      _journeyStatuses = statuses;
      _journeyStart = journeyStart;
      _daysSinceStart = daysSinceStart < 1 ? 1 : daysSinceStart;
      _logicalToday = today;
      _loading = false;
    });
  }

  Future<void> _mark(ChizukStatus status) async {
    // לחיצה חוזרת על אותו מצב — אין פעולה.
    if (_todayStatus == status) {
      HapticFeedback.selectionClick();
      return;
    }

    final canCelebrate = status == ChizukStatus.overcame &&
        await ChizukService.shouldCelebrateOn(_logicalToday);

    if (status == ChizukStatus.overcame) {
      if (canCelebrate) {
        HapticFeedback.heavyImpact();
        _confettiCtrl.play();
        _pulseCtrl.forward(from: 0);
        _glowCtrl.forward(from: 0);
        setState(() => _justMarkedOvercame = true);
        await ChizukService.markCelebratedOn(_logicalToday);
      } else {
        HapticFeedback.lightImpact();
      }
    } else {
      HapticFeedback.mediumImpact();
    }

    await ChizukService.markDay(_logicalToday, status);
    // אחרי סימון — מתזמן מחדש את ההתראות כדי לא לשלוח אם כבר סומן.
    try {
      await NotificationService.scheduleAllChizukReminders();
    } catch (_) {}

    // ציטוט חדש רק כשחוגגים, או בשינוי מעוקם-נלחם.
    final shouldRotateQuote =
        canCelebrate || status == ChizukStatus.struggled;

    ChizukQuote? quote;
    if (shouldRotateQuote) {
      final quotes = status == ChizukStatus.overcame
          ? afterOvercame
          : afterStruggle;
      final idx = await ChizukService.nextQuoteIndex(quotes.length);
      quote = quotes[idx];
    }

    await _load();
    if (!mounted) return;
    if (shouldRotateQuote) {
      setState(() => _shownQuote = quote);
    }

    if (canCelebrate) {
      final milestone =
          await ChizukService.checkAndClaimMilestone(_currentRun);
      if (milestone != null && mounted) {
        await Future.delayed(const Duration(milliseconds: 700));
        if (!mounted) return;
        _showMilestoneCelebration(milestone);
      }
    }
  }

  Future<void> _clearToday() async {
    HapticFeedback.selectionClick();
    await ChizukService.clearDay(_logicalToday);
    await _load();
    if (!mounted) return;
    setState(() => _shownQuote = null);
  }

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
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  _appBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _identityBanner(),
                            const SizedBox(height: 14),
                            if (_recentUnmarkedShabbatDays().isNotEmpty) ...[
                              _shabbatBacklogCard(),
                              const SizedBox(height: 14),
                            ],
                            _todayCard(),
                            const SizedBox(height: 16),
                            if (nextMilestoneAfter(_currentRun) != null) ...[
                              _nextMilestoneCard(),
                              const SizedBox(height: 16),
                            ],
                            if (_shownQuote != null) ...[
                              _quoteCard(_shownQuote!),
                              const SizedBox(height: 16),
                            ],
                            _statsCard(),
                            const SizedBox(height: 16),
                            _calendarCard(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiCtrl,
                blastDirection: math.pi / 2,
                blastDirectionality: BlastDirectionality.explosive,
                particleDrag: 0.05,
                emissionFrequency: 0.04,
                numberOfParticles: 22,
                gravity: 0.25,
                shouldLoop: false,
                colors: const [
                  AppColors.accentGold,
                  AppColors.goldSoft,
                  Color(0xFFFFE9A8),
                  Color(0xFFFFD27A),
                  Colors.white,
                ],
              ),
            ),
            // המדליה הצפה: צמודה לפינה התחתונה־שמאלית, נשארת מעל ההגלגול
            // ומאפשרת למשתמש להציץ במדליות שצבר.
            Positioned(
              left: 16,
              bottom: MediaQuery.viewPaddingOf(context).bottom + 16,
              child: FloatingMedalButton(
                longestRun: _longest,
                currentRun: _currentRun,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _identityBanner() {
    final title = chizukTitleFor(_longest);
    final identity = chizukIdentityFor(_longest);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            AppColors.accentGold.withOpacity(0.18),
            AppColors.goldSoft.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.goldSoft.withOpacity(0.35),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            identity,
            textAlign: TextAlign.center,
            style: AppFonts.liturgical(
              size: 16,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          if (title.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppFonts.ui(
                size: 13,
                weight: FontWeight.w800,
                color: AppColors.goldSoft,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _nextMilestoneCard() {
    final next = nextMilestoneAfter(_currentRun);
    if (next == null) return const SizedBox.shrink();
    final remaining = next.days - _currentRun;
    final progress =
        next.days == 0 ? 0.0 : (_currentRun / next.days).clamp(0.0, 1.0);

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_outlined,
                  color: AppColors.goldSoft, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  remaining == 1
                      ? "עוד יום אחד ל־${next.title}"
                      : "עוד $remaining ימים ל־${next.title}",
                  style: AppFonts.ui(
                    size: 13,
                    weight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                "$_currentRun/${next.days}",
                style: AppFonts.ui(
                  size: 12,
                  weight: FontWeight.w700,
                  color: AppColors.goldSoft,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.glassBorder.withOpacity(0.5),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.accentGold),
            ),
          ),
        ],
      ),
    );
  }

  void _showMilestoneCelebration(ChizukMilestone m) {
    HapticFeedback.heavyImpact();
    _confettiCtrl.play();
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.bgLight,
                  AppColors.bgDeep,
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.accentGold.withOpacity(0.7),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentGold.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (m.medalAsset != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.accentGold.withOpacity(0.45),
                          AppColors.accentGold.withOpacity(0.0),
                        ],
                      ),
                    ),
                    child: Image.asset(
                      m.medalAsset!,
                      width: 180,
                      height: 180,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.accentGold.withOpacity(0.5),
                          AppColors.accentGold.withOpacity(0.0),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.emoji_events,
                      color: AppColors.accentGold,
                      size: 64,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  "הגעת ל${m.title}!",
                  textAlign: TextAlign.center,
                  style: AppFonts.liturgical(
                    size: 26,
                    weight: FontWeight.w800,
                    color: AppColors.goldSoft,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  m.subtitle,
                  textAlign: TextAlign.center,
                  style: AppFonts.ui(
                    size: 14,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.bgDeep.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.glassBorder, width: 1),
                  ),
                  child: Text(
                    m.quote,
                    textAlign: TextAlign.center,
                    style: AppFonts.liturgical(
                      size: 16,
                      color: AppColors.textPrimary,
                      height: 1.65,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGold,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      "ממשיכים",
                      style: AppFonts.ui(
                        size: 16,
                        weight: FontWeight.w800,
                        color: AppColors.bgDeep,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
              "חיזוק יומי",
              textAlign: TextAlign.center,
              style: AppFonts.ui(
                size: 20,
                weight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.tune,
                color: AppColors.textPrimary),
            tooltip: "הגדרות",
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ChizukSettingsScreen(),
                ),
              );
              if (!mounted) return;
              await _load();
            },
          ),
        ],
      ),
    );
  }

  Widget _todayCard() {
    final alreadyMarked = _todayStatus != null;
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            alreadyMarked ? "סומן היום" : "איך היה היום שלך?",
            textAlign: TextAlign.center,
            style: AppFonts.ui(
              size: 15,
              color: AppColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 16),
          _overcomeButton(),
          const SizedBox(height: 10),
          _struggleButton(),
          if (alreadyMarked) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: _clearToday,
                child: Text(
                  "אופס, לא התכוונתי — בטל סימון",
                  style: AppFonts.ui(
                    size: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _overcomeButton() {
    final selected = _todayStatus == ChizukStatus.overcame;
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, child) {
        // קפיצה קצרה: 1.0 -> 1.07 -> 1.0 בזמן לחיצה על התגברתי
        final t = _pulseCtrl.value;
        final scale = 1.0 + (t < 0.5 ? t * 0.14 : (1 - t) * 0.14);
        final glow = _justMarkedOvercame
            ? (1 - _glowCtrl.value).clamp(0.0, 1.0)
            : 0.0;
        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                if (glow > 0)
                  BoxShadow(
                    color: AppColors.accentGold.withOpacity(0.55 * glow),
                    blurRadius: 28 * glow,
                    spreadRadius: 4 * glow,
                  ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: ElevatedButton(
        onPressed: () => _mark(ChizukStatus.overcame),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentGold,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: selected ? 4 : 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? Icons.check_circle : Icons.check_circle_outline,
                color: AppColors.bgDeep, size: 24),
            const SizedBox(width: 10),
            Text(
              "היום התגברתי",
              style: AppFonts.ui(
                size: 17,
                weight: FontWeight.w800,
                color: AppColors.bgDeep,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _struggleButton() {
    final selected = _todayStatus == ChizukStatus.struggled;
    return OutlinedButton(
      onPressed: () => _mark(ChizukStatus.struggled),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(
          color: selected ? AppColors.goldSoft : AppColors.glassBorder,
          width: selected ? 2 : 1,
        ),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor:
            selected ? AppColors.glassFill : Colors.transparent,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            selected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: AppColors.goldSoft,
            size: 22,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              "היום היה לא פשוט — ממשיך",
              style: AppFonts.ui(
                size: 15,
                weight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quoteCard(ChizukQuote q) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            q.text,
            textAlign: TextAlign.center,
            style: AppFonts.liturgical(
              size: 18,
              color: AppColors.textPrimary,
              height: 1.65,
            ),
          ),
          if (q.attribution != null) ...[
            const SizedBox(height: 10),
            Text(
              "— ${q.attribution}",
              textAlign: TextAlign.center,
              style: AppFonts.ui(
                size: 12,
                color: AppColors.goldSoft,
                weight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statsCard() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      borderRadius: 18,
      child: Row(
        children: [
          Expanded(child: _stat("סה״כ ימים", "$_total")),
          _vDivider(),
          Expanded(child: _stat("רצף נוכחי", "$_currentRun")),
          _vDivider(),
          Expanded(child: _stat("שיא", "$_longest")),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: AppFonts.bigNumber(
            size: 26,
            color: AppColors.goldSoft,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppFonts.ui(
            size: 11,
            color: AppColors.textSecondary,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  Widget _vDivider() {
    return Container(
      width: 1,
      height: 36,
      color: AppColors.glassBorder,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  // ---------- שמות תאריכים ולוגיקת השלמות ----------

  static const _hebDayNames = [
    'ראשון', 'שני', 'שלישי', 'רביעי', 'חמישי', 'שישי', 'שבת',
  ];

  String _isoDate(DateTime d) =>
      "${d.year.toString().padLeft(4, '0')}-"
      "${d.month.toString().padLeft(2, '0')}-"
      "${d.day.toString().padLeft(2, '0')}";

  String _formatDay(DateTime d) {
    // weekday: Mon=1..Sun=7. רוצים Sun=0..Sat=6.
    final wIdx = d.weekday % 7;
    final isShabbat = wIdx == 6;
    final dayName = isShabbat ? 'שבת' : 'יום ${_hebDayNames[wIdx]}';
    return "$dayName, ${d.day}.${d.month}";
  }

  /// Friday/Saturday הקרובים האחרונים שעוד לא סומנו ושאינם היום (הלוגי).
  /// משמש לבאנר "במוצאי שבת — בא נשלים". מסונן לתחילת המסע.
  List<DateTime> _recentUnmarkedShabbatDays() {
    final out = <DateTime>[];
    for (int i = 1; i <= 7; i++) {
      final d = _logicalToday.subtract(Duration(days: i));
      if (d.weekday != DateTime.friday && d.weekday != DateTime.saturday) {
        continue;
      }
      if (_journeyStart != null && d.isBefore(_journeyStart!)) continue;
      if (_journeyStatuses[_isoDate(d)] != null) continue;
      out.add(d);
    }
    return out;
  }

  Widget _shabbatBacklogCard() {
    final missing = _recentUnmarkedShabbatDays();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            AppColors.goldSoft.withOpacity(0.14),
            AppColors.accentGold.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.goldSoft.withOpacity(0.32),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.history,
                  color: AppColors.goldSoft, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "בא נשלים את מה שהיה בשבת",
                  style: AppFonts.ui(
                    size: 14,
                    weight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "אי אפשר היה לסמן בזמן אמת — זה הזמן.",
            style: AppFonts.ui(
              size: 12,
              color: AppColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            textDirection: TextDirection.rtl,
            children: [
              for (final d in missing)
                ActionChip(
                  onPressed: () => _showPastDaySheet(d),
                  backgroundColor: AppColors.bgDeep.withOpacity(0.55),
                  side: BorderSide(
                    color: AppColors.goldSoft.withOpacity(0.45),
                    width: 1,
                  ),
                  label: Text(
                    _formatDay(d),
                    style: AppFonts.ui(
                      size: 12,
                      weight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// סימון יום שעבר — בלי קונפטי, בלי ציטוט. מילסטון כן (אם נפתח חדש).
  Future<void> _markPast(DateTime date, ChizukStatus status) async {
    HapticFeedback.selectionClick();
    await ChizukService.markDay(date, status);
    await _load();
    if (!mounted) return;
    final newRun = _currentRun;
    final milestone = await ChizukService.checkAndClaimMilestone(newRun);
    if (milestone != null && mounted) {
      _showMilestoneCelebration(milestone);
    }
  }

  Future<void> _clearPast(DateTime date) async {
    HapticFeedback.selectionClick();
    await ChizukService.clearDay(date);
    await _load();
  }

  void _showPastDaySheet(DateTime date) {
    final iso = _isoDate(date);
    final existing = _journeyStatuses[iso];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.bgLight, AppColors.bgDeep],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            border: Border.all(
              color: AppColors.goldSoft.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.glassBorder,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Text(
                "איך היה ב${_formatDay(date)}?",
                textAlign: TextAlign.center,
                style: AppFonts.ui(
                  size: 16,
                  weight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "בלי לחץ — אפשר לסמן עכשיו.",
                textAlign: TextAlign.center,
                style: AppFonts.ui(
                  size: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _markPast(date, ChizukStatus.overcame);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGold,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      existing == ChizukStatus.overcame
                          ? Icons.check_circle
                          : Icons.check_circle_outline,
                      color: AppColors.bgDeep,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "התגברתי",
                      style: AppFonts.ui(
                        size: 16,
                        weight: FontWeight.w800,
                        color: AppColors.bgDeep,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _markPast(date, ChizukStatus.struggled);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(
                    color: existing == ChizukStatus.struggled
                        ? AppColors.goldSoft
                        : AppColors.glassBorder,
                    width: existing == ChizukStatus.struggled ? 2 : 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  "היה לא פשוט",
                  style: AppFonts.ui(
                    size: 14,
                    weight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (existing != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _clearPast(date);
                  },
                  child: Text(
                    "בטל סימון",
                    style: AppFonts.ui(
                      size: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _calendarCard() {
    if (_journeyStart == null) return const SizedBox.shrink();

    // המשבצת הראשונה (ימין למעלה) = יום 1 = היום שבו פתחת את המסך לראשונה.
    // כל יום שעובר ממלא את המשבצת הבאה. אחרי 90 ימים — חלון של 90 האחרונים.
    const int softCap = 90;
    const int minVisible = 30;

    final start = _journeyStart!;
    final visibleCount = _daysSinceStart <= minVisible
        ? minVisible
        : (_daysSinceStart <= softCap ? _daysSinceStart : softCap);
    final DateTime gridStart;
    if (_daysSinceStart > softCap) {
      gridStart = _logicalToday.subtract(const Duration(days: softCap - 1));
    } else {
      gridStart = start;
    }

    final days = List.generate(
      visibleCount,
      (i) => gridStart.add(Duration(days: i)),
    );

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 4, bottom: 10),
            child: Row(
              children: [
                Text(
                  "המסע שלך",
                  style: AppFonts.ui(
                    size: 13,
                    weight: FontWeight.w700,
                    color: AppColors.goldSoft,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                Text(
                  _daysSinceStart == 1
                      ? "יום ראשון"
                      : "יום $_daysSinceStart",
                  style: AppFonts.ui(
                    size: 12,
                    weight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            textDirection: TextDirection.rtl,
            children: [
              for (final d in days) _dayDot(d),
            ],
          ),
          const SizedBox(height: 12),
          _legend(),
        ],
      ),
    );
  }

  Widget _dayDot(DateTime d) {
    final iso = _isoDate(d);
    final status = _journeyStatuses[iso];
    final isToday = d.isAtSameMomentAs(_logicalToday);
    final isFuture = d.isAfter(_logicalToday);

    Color color;
    if (isFuture) {
      // משבצת עתידית — חיוורת, מחכה.
      color = AppColors.glassBorder.withValues(alpha: 0.35);
    } else {
      switch (status) {
        case ChizukStatus.overcame:
          color = AppColors.accentGold;
          break;
        case ChizukStatus.struggled:
          color = AppColors.textMuted;
          break;
        case null:
          color = AppColors.glassBorder;
          break;
      }
    }

    final dot = Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: isToday
            ? Border.all(color: AppColors.goldSoft, width: 1.5)
            : null,
      ),
    );

    if (isFuture) return dot;

    return GestureDetector(
      onTap: () => _showPastDaySheet(d),
      child: dot,
    );
  }

  Widget _legend() {
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      textDirection: TextDirection.rtl,
      children: [
        _legendItem(AppColors.accentGold, "התגברות"),
        _legendItem(AppColors.textMuted, "היה קשה"),
        _legendItem(AppColors.glassBorder, "לא סומן"),
        _legendItem(
            AppColors.glassBorder.withValues(alpha: 0.35), "מחכה"),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppFonts.ui(
            size: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
