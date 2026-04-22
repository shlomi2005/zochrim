import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/city_preset.dart';
import '../services/notification_service.dart';
import '../services/preferences_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

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
    if (!mounted) return;
    setState(() {
      _nameController.text = name ?? '';
      _city = city;
      _omerHour = hour;
      _omerMinute = minute;
      _tefillinHour = tH;
      _tefillinMinute = tM;
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
    return _timeRow(
      icon: Icons.wb_sunny_outlined,
      label: "תזכורת תפילין (בוקר)",
      time: _formatTime(_tefillinHour, _tefillinMinute),
      onTap: _pickTefillinTime,
    );
  }

  Widget _omerReminderField() {
    return _timeRow(
      icon: Icons.nights_stay_outlined,
      label: "תזכורת ספירת העומר (ערב)",
      time: _formatTime(_omerHour, _omerMinute),
      onTap: _pickOmerTime,
    );
  }

  Widget _timeRow({
    required IconData icon,
    required String label,
    required String time,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: 16,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: AppColors.goldSoft, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppFonts.ui(
                          size: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(time,
                      style: AppFonts.ui(
                          size: 18,
                          weight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_left,
                color: AppColors.textMuted, size: 20),
          ],
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
