import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/city_preset.dart';
import '../models/zman_type.dart';
import '../services/daily_study_service.dart';
import '../services/jewish_day_service.dart';
import '../services/notification_service.dart';
import '../services/preferences_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import 'about_screen.dart';
import 'diagnostics_screen.dart';
import 'privacy_screen.dart';

/// מסך הגדרות - שם משתמש, עיר, שעות תזכורת.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  CityPreset _city = CityPreset.jerusalem;
  int _omerHour = 20;
  int _omerMinute = 15;
  int _tefillinHour = 7;
  int _tefillinMinute = 30;
  bool _tefillinEnabled = true;
  bool _omerEnabled = true;

  bool _dafYomiEnabled = false;
  int _dafYomiHour = PreferencesService.defaultDafYomiHour;
  int _dafYomiMinute = PreferencesService.defaultDafYomiMinute;

  final Map<ZmanType, bool> _zmanEnabled = {};
  final Map<ZmanType, int> _zmanLead = {};
  JewishDayService? _todayJd;

  bool _loading = true;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final name = await ProfileService.getName();
    final city = await ProfileService.getCity();
    final hour = await PreferencesService.getReminderHour();
    final minute = await PreferencesService.getReminderMinute();
    final tH = await PreferencesService.getTefillinHour();
    final tM = await PreferencesService.getTefillinMinute();
    final tefOn = await PreferencesService.isTefillinEnabled();
    final omerOn = await PreferencesService.isOmerEnabled();
    final dafOn = await PreferencesService.isDafYomiEnabled();
    final dafH = await PreferencesService.getDafYomiHour();
    final dafM = await PreferencesService.getDafYomiMinute();

    final zmanEnabled = <ZmanType, bool>{};
    final zmanLead = <ZmanType, int>{};
    for (final cfg in zmanimConfigs) {
      zmanEnabled[cfg.type] =
          await PreferencesService.isZmanEnabled(cfg.type);
      zmanLead[cfg.type] =
          await PreferencesService.getZmanLeadMinutes(cfg.type);
    }

    if (!mounted) return;
    setState(() {
      _nameController.text = name ?? '';
      _city = city;
      _omerHour = hour;
      _omerMinute = minute;
      _tefillinHour = tH;
      _tefillinMinute = tM;
      _tefillinEnabled = tefOn;
      _omerEnabled = omerOn;
      _dafYomiEnabled = dafOn;
      _dafYomiHour = dafH;
      _dafYomiMinute = dafM;
      _zmanEnabled
        ..clear()
        ..addAll(zmanEnabled);
      _zmanLead
        ..clear()
        ..addAll(zmanLead);
      _todayJd = JewishDayService(city: city, date: DateTime.now());
      _loading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      await ProfileService.setName(name);
    }
    await ProfileService.setCity(_city);
    await PreferencesService.setReminderTime(_omerHour, _omerMinute);
    await PreferencesService.setTefillinTime(_tefillinHour, _tefillinMinute);
    await PreferencesService.setTefillinEnabled(_tefillinEnabled);
    await PreferencesService.setOmerEnabled(_omerEnabled);
    await PreferencesService.setDafYomiEnabled(_dafYomiEnabled);
    await PreferencesService.setDafYomiTime(_dafYomiHour, _dafYomiMinute);
    for (final cfg in zmanimConfigs) {
      await PreferencesService.setZmanEnabled(
          cfg.type, _zmanEnabled[cfg.type] ?? false);
      await PreferencesService.setZmanLeadMinutes(
          cfg.type, _zmanLead[cfg.type] ?? defaultLeadMinutes);
    }
    await ProfileService.markOnboardingDone();

    try {
      await NotificationService.scheduleAllReminders();
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
    setState(() => _dirty = false);
    Navigator.of(context).pop(true);
  }

  Future<void> _pickOmerTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _omerHour, minute: _omerMinute),
    );
    if (picked == null) return;
    setState(() {
      _omerHour = picked.hour;
      _omerMinute = picked.minute;
      _dirty = true;
    });
  }

  Future<void> _pickTefillinTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _tefillinHour, minute: _tefillinMinute),
    );
    if (picked == null) return;
    setState(() {
      _tefillinHour = picked.hour;
      _tefillinMinute = picked.minute;
      _dirty = true;
    });
  }

  Future<void> _pickDafYomiTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _dafYomiHour, minute: _dafYomiMinute),
    );
    if (picked == null) return;
    setState(() {
      _dafYomiHour = picked.hour;
      _dafYomiMinute = picked.minute;
      _dirty = true;
    });
  }

  String _formatTime(int h, int m) =>
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _sectionTitle("פרופיל"),
                      _nameField(),
                      const SizedBox(height: 12),
                      _cityField(),
                      const SizedBox(height: 24),
                      _sectionTitle("תזכורות"),
                      _tefillinReminderField(),
                      const SizedBox(height: 12),
                      _omerReminderField(),
                      const SizedBox(height: 24),
                      _sectionTitle("זמני היום"),
                      _zmanimIntro(),
                      const SizedBox(height: 10),
                      for (final cfg in zmanimConfigs) ...[
                        _zmanRow(cfg),
                        const SizedBox(height: 10),
                      ],
                      const SizedBox(height: 14),
                      _sectionTitle("לימוד יומי"),
                      _dafYomiCard(),
                      const SizedBox(height: 14),
                      _sectionTitle("משפטי"),
                      _privacyTile(),
                      const SizedBox(height: 12),
                      _aboutTile(),
                      const SizedBox(height: 12),
                      _diagnosticsTile(),
                      const SizedBox(height: 30),
                      _saveButton(),
                      const SizedBox(height: 20),
                    ],
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
              "הגדרות",
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
      padding: const EdgeInsets.only(top: 6, bottom: 10, right: 6),
      child: Text(
        s,
        style: AppFonts.ui(
          size: 13,
          weight: FontWeight.w700,
          color: AppColors.goldSoft,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _nameField() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: 16,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: TextField(
          controller: _nameController,
          onChanged: (_) => setState(() => _dirty = true),
          textAlign: TextAlign.right,
          style: AppFonts.ui(
              size: 17,
              color: AppColors.textPrimary,
              weight: FontWeight.w500),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: "שמך (למשל: דוד)",
            hintStyle: AppFonts.ui(size: 17, color: AppColors.textMuted),
            labelText: "שם לפנייה אישית",
            labelStyle: AppFonts.ui(size: 13, color: AppColors.textSecondary),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            icon: const Icon(Icons.person_outline,
                color: AppColors.goldSoft, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _cityField() {
    final cities = CityPreset.sortedByName();
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      borderRadius: 16,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            const Icon(Icons.location_on_outlined,
                color: AppColors.goldSoft, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text("עיר (לחישוב זמני היום)",
                      style: AppFonts.ui(
                          size: 12, color: AppColors.textSecondary)),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<CityPreset>(
                      value: _city,
                      isExpanded: true,
                      dropdownColor: AppColors.bgMid,
                      iconEnabledColor: AppColors.textMuted,
                      style: AppFonts.ui(
                          size: 17,
                          color: AppColors.textPrimary,
                          weight: FontWeight.w500),
                      items: [
                        for (final c in cities)
                          DropdownMenuItem(
                            value: c,
                            child: Text(c.displayName,
                                textDirection: TextDirection.rtl),
                          ),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          _city = v;
                          _todayJd =
                              JewishDayService(city: v, date: DateTime.now());
                          _dirty = true;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tefillinReminderField() {
    return _reminderRow(
      icon: Icons.wb_sunny_outlined,
      label: "תזכורת תפילין (בוקר)",
      time: _formatTime(_tefillinHour, _tefillinMinute),
      enabled: _tefillinEnabled,
      onToggle: (v) => setState(() {
        _tefillinEnabled = v;
        _dirty = true;
      }),
      onTap: _pickTefillinTime,
    );
  }

  Widget _omerReminderField() {
    return _reminderRow(
      icon: Icons.nights_stay_outlined,
      label: "תזכורת ספירת העומר (ערב)",
      time: _formatTime(_omerHour, _omerMinute),
      enabled: _omerEnabled,
      onToggle: (v) => setState(() {
        _omerEnabled = v;
        _dirty = true;
      }),
      onTap: _pickOmerTime,
    );
  }

  Widget _reminderRow({
    required IconData icon,
    required String label,
    required String time,
    required bool enabled,
    required ValueChanged<bool> onToggle,
    required VoidCallback onTap,
  }) {
    final iconColor =
        enabled ? AppColors.goldSoft : AppColors.textMuted;
    final timeColor =
        enabled ? AppColors.textPrimary : AppColors.textMuted;
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      borderRadius: 16,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppFonts.ui(
                          size: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(
                    enabled ? time : "כבוי",
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
              onChanged: onToggle,
              activeColor: AppColors.accentGold,
            ),
          ],
        ),
      ),
    );
  }

  Widget _zmanimIntro() {
    return Padding(
      padding: const EdgeInsets.only(right: 6, bottom: 4),
      child: Text(
        "התראה X דקות לפני הזמן, לפי העיר שלך. מושתק בשבת/יו\"ט.",
        style: AppFonts.ui(
          size: 12,
          color: AppColors.textSecondary,
          height: 1.4,
        ),
      ),
    );
  }

  String? _todayZmanPreview(ZmanConfig cfg) {
    final jd = _todayJd;
    if (jd == null) return null;
    final t = cfg.compute(jd);
    if (t == null) return null;
    return _formatTime(t.hour, t.minute);
  }

  Widget _zmanRow(ZmanConfig cfg) {
    final enabled = _zmanEnabled[cfg.type] ?? false;
    final lead = _zmanLead[cfg.type] ?? defaultLeadMinutes;
    final iconColor = enabled ? AppColors.goldSoft : AppColors.textMuted;
    final todayTime = _todayZmanPreview(cfg);

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      borderRadius: 16,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Row(
              children: [
                Icon(cfg.icon, color: iconColor, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cfg.label,
                          style: AppFonts.ui(
                              size: 15,
                              weight: FontWeight.w600,
                              color: enabled
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted)),
                      if (todayTime != null) ...[
                        const SizedBox(height: 2),
                        Text("היום בשעה $todayTime",
                            style: AppFonts.ui(
                                size: 12,
                                color: AppColors.textSecondary)),
                      ],
                    ],
                  ),
                ),
                Switch(
                  value: enabled,
                  activeColor: AppColors.accentGold,
                  onChanged: (v) => setState(() {
                    _zmanEnabled[cfg.type] = v;
                    _dirty = true;
                  }),
                ),
              ],
            ),
            if (enabled) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const SizedBox(width: 34),
                  Text("התראה ",
                      style: AppFonts.ui(
                          size: 13, color: AppColors.textSecondary)),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: leadMinuteOptions.contains(lead)
                          ? lead
                          : defaultLeadMinutes,
                      isDense: true,
                      dropdownColor: AppColors.bgMid,
                      iconEnabledColor: AppColors.goldSoft,
                      style: AppFonts.ui(
                          size: 14,
                          weight: FontWeight.w700,
                          color: AppColors.textPrimary),
                      items: [
                        for (final m in leadMinuteOptions)
                          DropdownMenuItem(
                            value: m,
                            child: Text("$m דק'"),
                          ),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          _zmanLead[cfg.type] = v;
                          _dirty = true;
                        });
                      },
                    ),
                  ),
                  Text(" לפני הזמן",
                      style: AppFonts.ui(
                          size: 13, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dafYomiCard() {
    final dafText = DailyStudyService.getDafYomiBavli();
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: 16,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.menu_book_outlined,
                    color: AppColors.goldSoft, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "דף יומי",
                        style: AppFonts.ui(
                          size: 15,
                          weight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "היום: $dafText",
                        style: AppFonts.ui(
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _dafYomiEnabled,
                  activeColor: AppColors.accentGold,
                  onChanged: (v) => setState(() {
                    _dafYomiEnabled = v;
                    _dirty = true;
                  }),
                ),
              ],
            ),
            if (_dafYomiEnabled) ...[
              const SizedBox(height: 6),
              Divider(color: AppColors.glassBorder, height: 1),
              const SizedBox(height: 8),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: _pickDafYomiTime,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule,
                          color: AppColors.textMuted, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "שעת תזכורת",
                          style: AppFonts.ui(
                            size: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Text(
                        _formatTime(_dafYomiHour, _dafYomiMinute),
                        style: AppFonts.ui(
                          size: 15,
                          weight: FontWeight.w700,
                          color: AppColors.goldSoft,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_left,
                          color: AppColors.textMuted, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _privacyTile() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 16,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PrivacyScreen()),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              const Icon(Icons.shield_outlined,
                  color: AppColors.goldSoft, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("פרטיות ותנאים",
                        style: AppFonts.ui(
                            size: 16,
                            weight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text("מדיניות הפרטיות של האפליקציה",
                        style: AppFonts.ui(
                            size: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left,
                  color: AppColors.textMuted, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _aboutTile() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 16,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AboutScreen()),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              const Icon(Icons.info_outline,
                  color: AppColors.goldSoft, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("אודות וקרדיטים",
                        style: AppFonts.ui(
                            size: 16,
                            weight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text("גרסה, מפתח, ורישיונות ספריות",
                        style: AppFonts.ui(
                            size: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left,
                  color: AppColors.textMuted, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _diagnosticsTile() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 16,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DiagnosticsScreen()),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              const Icon(Icons.bug_report_outlined,
                  color: AppColors.textMuted, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("אבחון התראות",
                        style: AppFonts.ui(
                            size: 16,
                            weight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text("לבדיקה במקרה של תקלה",
                        style: AppFonts.ui(
                            size: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left,
                  color: AppColors.textMuted, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _saveButton() {
    return ElevatedButton(
      onPressed: _save,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentGold,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: Text(
        "שמור",
        style: AppFonts.ui(
          size: 17,
          weight: FontWeight.w800,
          color: AppColors.bgDeep,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
