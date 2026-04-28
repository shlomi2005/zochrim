import 'package:flutter/material.dart';

import '../data/privacy_text.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

/// מסך פרטיות ותנאים - תוכן מוטבע באפליקציה, ללא תקשורת רשת.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              _appBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _header(),
                      const SizedBox(height: 16),
                      _hebrewBlock(),
                      const SizedBox(height: 24),
                      _divider(),
                      const SizedBox(height: 24),
                      _englishBlock(),
                      const SizedBox(height: 28),
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

  Widget _appBar(BuildContext context) {
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
              "פרטיות ותנאים",
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

  Widget _header() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      borderRadius: 18,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "מדיניות פרטיות — זוכרים",
              textAlign: TextAlign.center,
              style: AppFonts.ui(
                size: 18,
                weight: FontWeight.w800,
                color: AppColors.goldSoft,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "תאריך תחולה: $privacyEffectiveDate",
              textAlign: TextAlign.center,
              style: AppFonts.ui(
                size: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.glassBorder,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            "English",
            style: AppFonts.ui(
              size: 12,
              weight: FontWeight.w700,
              color: AppColors.goldSoft,
              letterSpacing: 1.4,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.glassBorder,
          ),
        ),
      ],
    );
  }

  Widget _hebrewBlock() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final s in privacySectionsHe) ...[
            _sectionCard(s, rtl: true),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _englishBlock() {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              "Effective date: $privacyEffectiveDateEn",
              textAlign: TextAlign.center,
              style: AppFonts.ui(
                size: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          for (final s in privacySectionsEn) ...[
            _sectionCard(s, rtl: false),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _sectionCard(PrivacySection s, {required bool rtl}) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment:
            rtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            s.title,
            textAlign: rtl ? TextAlign.right : TextAlign.left,
            style: AppFonts.ui(
              size: 15,
              weight: FontWeight.w800,
              color: AppColors.goldSoft,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s.body,
            textAlign: rtl ? TextAlign.right : TextAlign.left,
            style: AppFonts.ui(
              size: 14,
              color: AppColors.textPrimary,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
