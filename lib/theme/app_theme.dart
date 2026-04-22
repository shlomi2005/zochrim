import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// פלטת צבעים - שמיים ערביים, מיסטיים, עם זהב חם
class AppColors {
  // רקע - גרדיאנט שמיים לילה
  static const Color bgDeep = Color(0xFF1A1A2E);
  static const Color bgMid = Color(0xFF16213E);
  static const Color bgLight = Color(0xFF0F3460);

  // זהב / אקצנט חם
  static const Color accentRose = Color(0xFFE94560);
  static const Color accentGold = Color(0xFFF5A623);
  static const Color goldSoft = Color(0xFFFFD27F);

  // טקסטים
  static const Color textPrimary = Color(0xFFF8F4E3);
  static const Color textSecondary = Color(0xFFB8B8D1);
  static const Color textMuted = Color(0xFF7A7A95);

  // כרטיסי זכוכית
  static Color glassFill = Colors.white.withOpacity(0.08);
  static Color glassBorder = Colors.white.withOpacity(0.12);

  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgDeep, bgMid, bgLight],
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentRose, accentGold],
  );
}

/// טיפוגרפיה - פונטים עבריים יפים
class AppFonts {
  /// לטקסט הספירה והתפילות - פונט ספרדי/רבני קלאסי
  static TextStyle liturgical({
    double size = 18,
    FontWeight weight = FontWeight.w500,
    Color? color,
    double? height,
  }) {
    return GoogleFonts.frankRuhlLibre(
      fontSize: size,
      fontWeight: weight,
      color: color ?? AppColors.textPrimary,
      height: height ?? 1.8,
    );
  }

  /// ל-UI כללי - פונט עברי מודרני ונקי
  static TextStyle ui({
    double size = 16,
    FontWeight weight = FontWeight.w500,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.heebo(
      fontSize: size,
      fontWeight: weight,
      color: color ?? AppColors.textPrimary,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// מספרים ענקיים/דרמטיים
  static TextStyle bigNumber({
    double size = 140,
    Color? color,
  }) {
    return GoogleFonts.frankRuhlLibre(
      fontSize: size,
      fontWeight: FontWeight.w900,
      color: color ?? AppColors.textPrimary,
      height: 1.0,
    );
  }
}

class AppTheme {
  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDeep,
      primaryColor: AppColors.accentGold,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentGold,
        secondary: AppColors.accentRose,
        surface: AppColors.bgMid,
      ),
      textTheme: GoogleFonts.heeboTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      useMaterial3: true,
    );
  }
}
