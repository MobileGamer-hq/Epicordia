import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppPrimaryColor {
  blue,
  emerald,
  purple,
  amber,
  rose,
  teal;

  PrimaryColorPalette get palette {
    switch (this) {
      case AppPrimaryColor.blue:
        return const PrimaryColorPalette(
          label: 'Blue',
          swatchColor: Color(0xFF3D68EE),
          shade50: Color(0xFFEEF3FF),
          shade100: Color(0xFFDCE6FF),
          shade200: Color(0xFFB7CCFF),
          shade300: Color(0xFF8FAEFF),
          shade400: Color(0xFF5C87F7),
          shade500: Color(0xFF3D68EE),
          shade600: Color(0xFF2F53DB),
          shade700: Color(0xFF243FB0),
          shade800: Color(0xFF1C3186),
          shade900: Color(0xFF152660),
        );
      case AppPrimaryColor.emerald:
        return const PrimaryColorPalette(
          label: 'Emerald',
          swatchColor: Color(0xFF10B981),
          shade50: Color(0xFFECFDF5),
          shade100: Color(0xFFD1FAE5),
          shade200: Color(0xFFA7F3D0),
          shade300: Color(0xFF6EE7B7),
          shade400: Color(0xFF34D399),
          shade500: Color(0xFF10B981),
          shade600: Color(0xFF059669),
          shade700: Color(0xFF047857),
          shade800: Color(0xFF065F46),
          shade900: Color(0xFF064E3B),
        );
      case AppPrimaryColor.purple:
        return const PrimaryColorPalette(
          label: 'Purple',
          swatchColor: Color(0xFF8B5CF6),
          shade50: Color(0xFFF5F3FF),
          shade100: Color(0xFFEDE9FE),
          shade200: Color(0xFFDDD6FE),
          shade300: Color(0xFFC4B5FD),
          shade400: Color(0xFFA78BFA),
          shade500: Color(0xFF8B5CF6),
          shade600: Color(0xFF7C3AED),
          shade700: Color(0xFF6D28D9),
          shade800: Color(0xFF5B21B6),
          shade900: Color(0xFF4C1D95),
        );
      case AppPrimaryColor.amber:
        return const PrimaryColorPalette(
          label: 'Amber',
          swatchColor: Color(0xFFF59E0B),
          shade50: Color(0xFFFFFBEB),
          shade100: Color(0xFFFEF3C7),
          shade200: Color(0xFFFDE68A),
          shade300: Color(0xFFFCD34D),
          shade400: Color(0xFFFBBF24),
          shade500: Color(0xFFF59E0B),
          shade600: Color(0xFFD97706),
          shade700: Color(0xFFB45309),
          shade800: Color(0xFF92400E),
          shade900: Color(0xFF78350F),
        );
      case AppPrimaryColor.rose:
        return const PrimaryColorPalette(
          label: 'Rose',
          swatchColor: Color(0xFFEC4899),
          shade50: Color(0xFFFDF2F8),
          shade100: Color(0xFFFCE7F3),
          shade200: Color(0xFFFBCFE8),
          shade300: Color(0xFFF9A8D4),
          shade400: Color(0xFFF472B6),
          shade500: Color(0xFFEC4899),
          shade600: Color(0xFFDB2777),
          shade700: Color(0xFFBE185D),
          shade800: Color(0xFF9D174D),
          shade900: Color(0xFF831843),
        );
      case AppPrimaryColor.teal:
        return const PrimaryColorPalette(
          label: 'Teal',
          swatchColor: Color(0xFF14B8A6),
          shade50: Color(0xFFF0FDFA),
          shade100: Color(0xFFCCFBF1),
          shade200: Color(0xFF99F6E4),
          shade300: Color(0xFF5EEAD4),
          shade400: Color(0xFF2DD4BF),
          shade500: Color(0xFF14B8A6),
          shade600: Color(0xFF0D9488),
          shade700: Color(0xFF0F766E),
          shade800: Color(0xFF115E59),
          shade900: Color(0xFF134E4A),
        );
    }
  }
}

class PrimaryColorPalette {
  final String label;
  final Color swatchColor;
  final Color shade50;
  final Color shade100;
  final Color shade200;
  final Color shade300;
  final Color shade400;
  final Color shade500;
  final Color shade600;
  final Color shade700;
  final Color shade800;
  final Color shade900;

  const PrimaryColorPalette({
    required this.label,
    required this.swatchColor,
    required this.shade50,
    required this.shade100,
    required this.shade200,
    required this.shade300,
    required this.shade400,
    required this.shade500,
    required this.shade600,
    required this.shade700,
    required this.shade800,
    required this.shade900,
  });
}

class EpicordiaColors {
  static AppPrimaryColor currentPrimaryColor = AppPrimaryColor.blue;

  // Primary Palette — Dynamic based on active theme primary color selection
  static Color get blue50  => currentPrimaryColor.palette.shade50;
  static Color get blue100 => currentPrimaryColor.palette.shade100;
  static Color get blue200 => currentPrimaryColor.palette.shade200; // Heatmap level 1
  static Color get blue300 => currentPrimaryColor.palette.shade300; // Heatmap level 2
  static Color get blue400 => currentPrimaryColor.palette.shade400; // Heatmap level 3
  static Color get blue500 => currentPrimaryColor.palette.shade500; // Heatmap level 4 (max)
  static Color get blue600 => currentPrimaryColor.palette.shade600; // Primary accent — light mode
  static Color get blue700 => currentPrimaryColor.palette.shade700; // Pressed/active, brand navy
  static Color get blue800 => currentPrimaryColor.palette.shade800;
  static Color get blue900 => currentPrimaryColor.palette.shade900;

  // Dark mode primary
  static Color get primary => blue500;
  static Color get Primary => blue500; // Legacy alias

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

  // Neutrals - Dark (Rich Dark Navy / Slate theme from design)
  static const Color surfaceAppDark    = Color(0xFF0F1420); // Dark navy slate app background
  static const Color surfaceCardDark   = Color(0xFF1E283A); // Sleek slate blue card background
  static const Color surfaceSunkenDark = Color(0xFF141A26); // Dark sunken sidebar / canvas background
  static const Color borderSubtleDark  = Color(0xFF273349); // Subtle slate border
  static const Color borderStrongDark  = Color(0xFF3A4B68); // Strong slate border
  static const Color textPrimaryDark   = Color(0xFFF1F5F9); // Crisp white primary text
  static const Color textSecondaryDark = Color(0xFF94A3B8); // Muted slate secondary text
  static const Color textTertiaryDark  = Color(0xFF64748B); // Muted slate tertiary text
}

class EpicordiaTheme {
  static ThemeData lightTheme([AppPrimaryColor primaryOption = AppPrimaryColor.blue]) {
    final palette = primaryOption.palette;
    final base = ThemeData.light();
    return base.copyWith(
      primaryColor: palette.shade500,
      scaffoldBackgroundColor: EpicordiaColors.surfaceAppLight,
      cardColor: EpicordiaColors.surfaceCardLight,
      canvasColor: EpicordiaColors.surfaceAppLight,
      colorScheme: base.colorScheme.copyWith(
        primary: palette.shade500,
        onPrimary: Colors.white,
        primaryContainer: palette.shade100,
        onPrimaryContainer: palette.shade700,
        secondary: palette.shade700,
        onSecondary: Colors.white,
        secondaryContainer: palette.shade100,
        onSecondaryContainer: palette.shade700,
        tertiary: palette.shade600,
        tertiaryContainer: palette.shade100,
        onTertiaryContainer: palette.shade700,
        surface: EpicordiaColors.surfaceCardLight,
        onSurface: EpicordiaColors.textPrimaryLight,
        error: EpicordiaColors.errorLight,
        onError: Colors.white,
      ),
      dividerColor: EpicordiaColors.borderSubtleLight,
      dialogTheme: const DialogThemeData(
        backgroundColor: EpicordiaColors.surfaceCardLight,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: EpicordiaColors.surfaceCardLight,
        headerBackgroundColor: palette.shade500,
        headerForegroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: EpicordiaColors.surfaceCardLight,
        hourMinuteColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return palette.shade600;
          return palette.shade50;
        }),
        hourMinuteTextColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return EpicordiaColors.textPrimaryLight;
        }),
        dayPeriodColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return palette.shade600;
          return palette.shade50;
        }),
        dayPeriodTextColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return EpicordiaColors.textPrimaryLight;
        }),
        dialHandColor: palette.shade600,
        dialBackgroundColor: palette.shade50,
        dialTextColor: EpicordiaColors.textPrimaryLight,
        entryModeIconColor: palette.shade600,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.shade500,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
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
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: palette.shade500,
        selectionColor: palette.shade100,
        selectionHandleColor: palette.shade500,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: const CircleBorder(),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return palette.shade500;
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
          borderSide: BorderSide(color: palette.shade500, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: EpicordiaColors.textTertiaryLight),
      ),
    );
  }

  static ThemeData darkTheme([AppPrimaryColor primaryOption = AppPrimaryColor.blue]) {
    final palette = primaryOption.palette;
    final base = ThemeData.dark();
    return base.copyWith(
      primaryColor: palette.shade500,
      scaffoldBackgroundColor: EpicordiaColors.surfaceAppDark,
      cardColor: EpicordiaColors.surfaceCardDark,
      canvasColor: EpicordiaColors.surfaceAppDark,
      colorScheme: base.colorScheme.copyWith(
        primary: palette.shade500,
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFF273349),
        onPrimaryContainer: palette.shade300,
        secondary: palette.shade300,
        onSecondary: Colors.white,
        secondaryContainer: const Color(0xFF273349),
        onSecondaryContainer: palette.shade300,
        tertiary: palette.shade500,
        tertiaryContainer: const Color(0xFF273349),
        onTertiaryContainer: palette.shade300,
        surface: EpicordiaColors.surfaceCardDark,
        onSurface: EpicordiaColors.textPrimaryDark,
        error: EpicordiaColors.errorDark,
        onError: Colors.white,
      ),
      dividerColor: EpicordiaColors.borderSubtleDark,
      dialogTheme: const DialogThemeData(
        backgroundColor: EpicordiaColors.surfaceCardDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: EpicordiaColors.surfaceCardDark,
        headerBackgroundColor: palette.shade500,
        headerForegroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: EpicordiaColors.surfaceCardDark,
        hourMinuteColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return palette.shade600;
          return const Color(0xFF273349);
        }),
        hourMinuteTextColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return EpicordiaColors.textPrimaryDark;
        }),
        dayPeriodColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return palette.shade600;
          return const Color(0xFF273349);
        }),
        dayPeriodTextColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return EpicordiaColors.textPrimaryDark;
        }),
        dialHandColor: palette.shade600,
        dialBackgroundColor: const Color(0xFF141A26),
        dialTextColor: EpicordiaColors.textPrimaryDark,
        entryModeIconColor: palette.shade300,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.shade500,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
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
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: palette.shade500,
        selectionColor: const Color(0xFF2A3A5E),
        selectionHandleColor: palette.shade500,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: const CircleBorder(),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return palette.shade500;
          return Colors.transparent;
        }),
        side: const BorderSide(color: EpicordiaColors.borderStrongDark, width: 1.5),
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
          borderSide: BorderSide(color: palette.shade500, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: EpicordiaColors.textTertiaryDark),
      ),
    );
  }
}

