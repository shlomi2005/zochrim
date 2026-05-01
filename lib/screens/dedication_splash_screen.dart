import 'package:flutter/material.dart';

import '../services/preferences_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

/// מסך הקדשה שמוצג בפעם הראשונה שפותחים את האפליקציה.
/// fade-in קל, ~2 שניות, ואז ניווט אוטומטי ל-HomeScreen.
class DedicationSplashScreen extends StatefulWidget {
  const DedicationSplashScreen({super.key});

  @override
  State<DedicationSplashScreen> createState() =>
      _DedicationSplashScreenState();
}

class _DedicationSplashScreenState extends State<DedicationSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
    _scheduleNavigation();
  }

  Future<void> _scheduleNavigation() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    try {
      await PreferencesService.markFirstLaunchDone();
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fade,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_fire_department_outlined,
                      color: AppColors.goldSoft,
                      size: 38,
                    ),
                    const SizedBox(height: 26),
                    _label("לעילוי נשמת"),
                    const SizedBox(height: 8),
                    _name("רבי יששכר שלמה בן יפה זצ״ל"),
                    const SizedBox(height: 20),
                    _label("ולעילוי נשמת"),
                    const SizedBox(height: 8),
                    _name("רבי חיים בן סוליקה זצ״ל"),
                    const SizedBox(height: 28),
                    Container(
                      width: 36,
                      height: 1,
                      color: AppColors.goldSoft.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "ת.נ.צ.ב.ה",
                      style: AppFonts.ui(
                        size: 11,
                        weight: FontWeight.w700,
                        color: AppColors.textMuted,
                        letterSpacing: 2.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String s) {
    return Text(
      s,
      textAlign: TextAlign.center,
      style: AppFonts.ui(
        size: 13,
        weight: FontWeight.w700,
        color: AppColors.goldSoft,
        letterSpacing: 1.6,
      ),
    );
  }

  Widget _name(String s) {
    return Text(
      s,
      textAlign: TextAlign.center,
      style: AppFonts.liturgical(
        size: 22,
        weight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.4,
      ),
    );
  }
}
