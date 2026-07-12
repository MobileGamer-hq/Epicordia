import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EpicordiaColors {
  // Primary Palette
  static const Color blue50 = Color(0xFFCAF0F8);
  static const Color blue100 = Color(0xFF90E0EF);
  static const Color blue200 = Color(0xFF90E0EF);
  static const Color blue300 = Color(0xFF00B4D8);
  static const Color blue400 = Color(0xFF00B4D8);
  static const Color blue500 = Color(0xFF0077B6);
  static const Color blue600 = Color(0xFF0077B6);
  static const Color blue700 = Color(0xFF03045E);
  static const Color blue800 = Color(0xFF03045E);
  static const Color blue900 = Color(0xFF03045E);

  // Dark mode primary
  static const Color darkPrimary = Color(0xFF00B4D8);

  // Semantic
  static const Color successLight = Color(0xFF1A9A5B);
  static const Color successDark = Color(0xFF33C077);
  static const Color warningLight = Color(0xFFB5730A);
  static const Color warningDark = Color(0xFFE5A030);
  static const Color errorLight = Color(0xFFC6362E);
  static const Color errorDark = Color(0xFFF0685F);

  // Neutrals - Light
  static const Color surfaceAppLight = Color(0xFFFAFAF8);
  static const Color surfaceCardLight = Color(0xFFFFFFFF);
  static const Color surfaceSunkenLight = Color(0xFFF2F2EF);
  static const Color borderSubtleLight = Color(0xFFE7E7E2);
  static const Color borderStrongLight = Color(0xFFD6D6CF);
  static const Color textPrimaryLight = Color(0xFF16181C);
  static const Color textSecondaryLight = Color(0xFF585E68);
  static const Color textTertiaryLight = Color(0xFF8A8F98);

  // Neutrals - Dark
  static const Color surfaceAppDark = Color(0xFF101216);
  static const Color surfaceCardDark = Color(0xFF1A1D22);
  static const Color surfaceSunkenDark = Color(0xFF0B0D10);
  static const Color borderSubtleDark = Color(0xFF2B2E34);
  static const Color borderStrongDark = Color(0xFF3B3F47);
  static const Color textPrimaryDark = Color(0xFFF3F4F6);
  static const Color textSecondaryDark = Color(0xFFA6ABB4);
  static const Color textTertiaryDark = Color(0xFF6E737C);
}

class EpicordiaTheme {
  static ThemeData get lightTheme {
    final base = ThemeData.light();
    return base.copyWith(
      primaryColor: EpicordiaColors.blue600,
      scaffoldBackgroundColor: EpicordiaColors.surfaceAppLight,
      cardColor: EpicordiaColors.surfaceCardLight,
      canvasColor: EpicordiaColors.surfaceSunkenLight,
      colorScheme: base.colorScheme.copyWith(
        primary: EpicordiaColors.blue600,
        secondary: EpicordiaColors.blue400,
        surface: EpicordiaColors.surfaceCardLight,
        error: EpicordiaColors.errorLight,
      ),
      dividerColor: EpicordiaColors.borderSubtleLight,
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, color: EpicordiaColors.textPrimaryLight, height: 1.2),
        displayMedium: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: EpicordiaColors.textPrimaryLight, height: 1.2),
        titleLarge: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: EpicordiaColors.textPrimaryLight, height: 1.2),
        bodyLarge: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w400, color: EpicordiaColors.textPrimaryLight, height: 1.5),
        bodyMedium: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: EpicordiaColors.textPrimaryLight, height: 1.5),
        bodySmall: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, color: EpicordiaColors.textSecondaryLight, height: 1.4),
        labelSmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: EpicordiaColors.textSecondaryLight, letterSpacing: 1.0),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: EpicordiaColors.surfaceCardLight,
        foregroundColor: EpicordiaColors.textPrimaryLight,
        elevation: 0,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: EpicordiaColors.blue600,
        selectionColor: EpicordiaColors.blue100,
        selectionHandleColor: EpicordiaColors.blue600,
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    return base.copyWith(
      primaryColor: EpicordiaColors.darkPrimary,
      scaffoldBackgroundColor: EpicordiaColors.surfaceAppDark,
      cardColor: EpicordiaColors.surfaceCardDark,
      canvasColor: EpicordiaColors.surfaceSunkenDark,
      colorScheme: base.colorScheme.copyWith(
        primary: EpicordiaColors.darkPrimary,
        secondary: EpicordiaColors.blue400,
        surface: EpicordiaColors.surfaceCardDark,
        error: EpicordiaColors.errorDark,
      ),
      dividerColor: EpicordiaColors.borderSubtleDark,
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, color: EpicordiaColors.textPrimaryDark, height: 1.2),
        displayMedium: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: EpicordiaColors.textPrimaryDark, height: 1.2),
        titleLarge: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: EpicordiaColors.textPrimaryDark, height: 1.2),
        bodyLarge: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w400, color: EpicordiaColors.textPrimaryDark, height: 1.5),
        bodyMedium: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: EpicordiaColors.textPrimaryDark, height: 1.5),
        bodySmall: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, color: EpicordiaColors.textSecondaryDark, height: 1.4),
        labelSmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: EpicordiaColors.textSecondaryDark, letterSpacing: 1.0),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: EpicordiaColors.surfaceCardDark,
        foregroundColor: EpicordiaColors.textPrimaryDark,
        elevation: 0,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: EpicordiaColors.darkPrimary,
        selectionColor: EpicordiaColors.blue900,
        selectionHandleColor: EpicordiaColors.darkPrimary,
      ),
    );
  }
}
