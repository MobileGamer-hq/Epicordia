import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EpicordiaColors {
  // Primary Palette — Epicordia Blue (per UI design doc §1.1)
  static const Color blue50  = Color(0xFFEEF3FF);
  static const Color blue100 = Color(0xFFDCE6FF);
  static const Color blue200 = Color(0xFFB7CCFF); // Heatmap level 1
  static const Color blue300 = Color(0xFF8FAEFF); // Heatmap level 2
  static const Color blue400 = Color(0xFF5C87F7); // Heatmap level 3
  static const Color blue500 = Color(0xFF3D68EE); // Heatmap level 4 (max)
  static const Color blue600 = Color(0xFF2F53DB); // Primary accent — light mode
  static const Color blue700 = Color(0xFF243FB0); // Pressed/active, brand navy
  static const Color blue800 = Color(0xFF1C3186);
  static const Color blue900 = Color(0xFF152660);


  // Dark mode primary
  static const Color Primary = blue500;

  // Semantic
  static const Color successLight = Color(0xFF1A9A5B);
  static const Color successDark  = Color(0xFF33C077);
  static const Color warningLight = Color(0xFFB5730A);
  static const Color warningDark  = Color(0xFFE5A030);
  static const Color errorLight   = Color(0xFFC6362E);
  static const Color errorDark    = Color(0xFFF0685F);

  // Neutrals - Light (clean, warm)
  static const Color surfaceAppLight    = Color(0xFFF8F7F4); // warm off-white
  static const Color surfaceCardLight   = Color(0xFFFFFFFF);
  static const Color surfaceSunkenLight = Color(0xFFF1F0EC);
  static const Color borderSubtleLight  = Color(0xFFEAEAE5);
  static const Color borderStrongLight  = Color(0xFFD4D4CF);
  static const Color textPrimaryLight   = Color(0xFF1A1A2E);
  static const Color textSecondaryLight = Color(0xFF5A5A72);
  static const Color textTertiaryLight  = Color(0xFF9090A8);

  // Neutrals - Dark
  static const Color surfaceAppDark    = Color(0xFF101216);
  static const Color surfaceCardDark   = Color(0xFF1A1D22);
  static const Color surfaceSunkenDark = Color(0xFF0B0D10);
  static const Color borderSubtleDark  = Color(0xFF16191C);
  static const Color borderStrongDark  = Color(0xFF3B3F47);
  static const Color textPrimaryDark   = Color(0xFFF3F4F6);
  static const Color textSecondaryDark = Color(0xFFA6ABB4);
  static const Color textTertiaryDark  = Color(0xFF6E737C);
}

class EpicordiaTheme {
  static ThemeData get lightTheme {
    final base = ThemeData.light();
    return base.copyWith(
      primaryColor: EpicordiaColors.blue500,
      scaffoldBackgroundColor: EpicordiaColors.surfaceAppLight,
      cardColor: EpicordiaColors.surfaceCardLight,
      canvasColor: EpicordiaColors.surfaceAppLight,
      colorScheme: base.colorScheme.copyWith(
        primary: EpicordiaColors.blue500,
        secondary: EpicordiaColors.blue700,
        surface: EpicordiaColors.surfaceCardLight,
        error: EpicordiaColors.errorLight,
      ),
      dividerColor: EpicordiaColors.borderSubtleLight,
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge:  GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: EpicordiaColors.textPrimaryLight, height: 1.2),
        displayMedium: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: EpicordiaColors.textPrimaryLight, height: 1.2),
        titleLarge:    GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: EpicordiaColors.textPrimaryLight, height: 1.3),
        titleMedium:   GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: EpicordiaColors.textPrimaryLight, height: 1.3),
        titleSmall:    GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: EpicordiaColors.textPrimaryLight, height: 1.3),
        bodyLarge:     GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w400, color: EpicordiaColors.textPrimaryLight, height: 1.5),
        bodyMedium:    GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: EpicordiaColors.textPrimaryLight, height: 1.5),
        bodySmall:     GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: EpicordiaColors.textSecondaryLight, height: 1.4),
        labelLarge:    GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: EpicordiaColors.textPrimaryLight),
        labelSmall:    GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: EpicordiaColors.textSecondaryLight, letterSpacing: 0.8),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: EpicordiaColors.surfaceAppLight,
        foregroundColor: EpicordiaColors.textPrimaryLight,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: EpicordiaColors.blue500,
        selectionColor: EpicordiaColors.blue100,
        selectionHandleColor: EpicordiaColors.blue500,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: const CircleBorder(),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return EpicordiaColors.blue500;
          return Colors.transparent;
        }),
        side: const BorderSide(color: EpicordiaColors.borderStrongLight, width: 1.5),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: EpicordiaColors.surfaceCardLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: EpicordiaColors.borderSubtleLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: EpicordiaColors.borderSubtleLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: EpicordiaColors.blue500, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: EpicordiaColors.textTertiaryLight),
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    return base.copyWith(
      primaryColor: EpicordiaColors.Primary,
      scaffoldBackgroundColor: EpicordiaColors.surfaceAppDark,
      cardColor: EpicordiaColors.surfaceCardDark,
      canvasColor: EpicordiaColors.surfaceAppDark,
      colorScheme: base.colorScheme.copyWith(
        primary: EpicordiaColors.Primary,
        secondary: EpicordiaColors.blue300,
        surface: EpicordiaColors.surfaceCardDark,
        error: EpicordiaColors.errorDark,
      ),
      dividerColor: EpicordiaColors.borderSubtleDark,
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge:  GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: EpicordiaColors.textPrimaryDark, height: 1.2),
        displayMedium: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: EpicordiaColors.textPrimaryDark, height: 1.2),
        titleLarge:    GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: EpicordiaColors.textPrimaryDark, height: 1.3),
        titleMedium:   GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: EpicordiaColors.textPrimaryDark, height: 1.3),
        titleSmall:    GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: EpicordiaColors.textPrimaryDark, height: 1.3),
        bodyLarge:     GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w400, color: EpicordiaColors.textPrimaryDark, height: 1.5),
        bodyMedium:    GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: EpicordiaColors.textPrimaryDark, height: 1.5),
        bodySmall:     GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: EpicordiaColors.textSecondaryDark, height: 1.4),
        labelLarge:    GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: EpicordiaColors.textPrimaryDark),
        labelSmall:    GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: EpicordiaColors.textSecondaryDark, letterSpacing: 0.8),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: EpicordiaColors.surfaceAppDark,
        foregroundColor: EpicordiaColors.textPrimaryDark,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: EpicordiaColors.surfaceCardDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: EpicordiaColors.borderSubtleDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: EpicordiaColors.borderSubtleDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: EpicordiaColors.Primary, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: EpicordiaColors.textTertiaryDark),
      ),
    );
  }
}
