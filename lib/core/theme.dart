import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EpicordiaColors {
  // Primary
  static const Color blue50 = Color(0xFFEEF3FF);
  static const Color blue100 = Color(0xFFDCE6FF);
  static const Color blue200 = Color(0xFFB7CCFF);
  static const Color blue300 = Color(0xFF8FAEFF);
  static const Color blue400 = Color(0xFF5C87F7);
  static const Color blue500 = Color(0xFF3D68EE);
  static const Color blue600 = Color(0xFF2F53DB);
  static const Color blue700 = Color(0xFF243FB0);
  static const Color blue800 = Color(0xFF1C3186);
  static const Color blue900 = Color(0xFF152660);

  // Dark mode primary
  static const Color darkPrimary = Color(0xFF6E96FF);

  // Semantic
  static const Color successLight = Color(0xFF1A9A5B);
  static const Color successDark = Color(0xFF33C077);
  static const Color warningLight = Color(0xFFB5730A);
  static const Color warningDark = Color(0xFFE5A030);
  static const Color errorLight = Color(0xFFC6362E);
  static const Color errorDark = Color(0xFFF0685F);
}

class EpicordiaTheme {
  static ThemeData get lightTheme {
    final base = ThemeData.light();
    return base.copyWith(
      primaryColor: EpicordiaColors.blue600,
      scaffoldBackgroundColor: const Color(0xFFFAFAF8),
      cardColor: const Color(0xFFFFFFFF),
      canvasColor: const Color(0xFFF2F2EF),
      colorScheme: base.colorScheme.copyWith(
        primary: EpicordiaColors.blue600,
        secondary: EpicordiaColors.blue400,
        surface: const Color(0xFFFFFFFF),
        error: EpicordiaColors.errorLight,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: const Color(0xFF16181C)),
        displayMedium: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: const Color(0xFF16181C)),
        titleLarge: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF16181C)),
        bodyLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: const Color(0xFF16181C)),
        bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF16181C)),
        bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: const Color(0xFF585E68)),
        labelSmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF585E68), letterSpacing: 1.0),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFFFFF),
        foregroundColor: Color(0xFF16181C),
        elevation: 0,
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    return base.copyWith(
      primaryColor: EpicordiaColors.darkPrimary,
      scaffoldBackgroundColor: const Color(0xFF101216),
      cardColor: const Color(0xFF1A1D22),
      canvasColor: const Color(0xFF0B0D10),
      colorScheme: base.colorScheme.copyWith(
        primary: EpicordiaColors.darkPrimary,
        secondary: EpicordiaColors.blue400,
        surface: const Color(0xFF1A1D22),
        error: EpicordiaColors.errorDark,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: const Color(0xFFF3F4F6)),
        displayMedium: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: const Color(0xFFF3F4F6)),
        titleLarge: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFFF3F4F6)),
        bodyLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: const Color(0xFFF3F4F6)),
        bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFFF3F4F6)),
        bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: const Color(0xFFA6ABB4)),
        labelSmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFA6ABB4), letterSpacing: 1.0),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A1D22),
        foregroundColor: Color(0xFFF3F4F6),
        elevation: 0,
      ),
    );
  }
}
