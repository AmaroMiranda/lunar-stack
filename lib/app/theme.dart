import 'package:flutter/material.dart';

/// Paleta "astrofotografia" da spec (seção 33): céu noturno, precisão, calma.
abstract class LunarColors {
  static const backgroundDark = Color(0xFF0A0D14);
  static const surfaceDark = Color(0xFF141924);
  static const surfaceElevatedDark = Color(0xFF1D2432);
  static const borderDark = Color(0xFF2B3344);

  static const backgroundLight = Color(0xFFF6F7FA);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceElevatedLight = Color(0xFFEDEFF4);
  static const borderLight = Color(0xFFDBDFE7);

  static const textPrimaryDark = Color(0xFFF2F4F7);
  static const textSecondaryDark = Color(0xFF9BA6B4);
  static const textPrimaryLight = Color(0xFF13161C);
  static const textSecondaryLight = Color(0xFF5B6472);

  static const lunarBlue = Color(0xFF5B8DEF);
  static const softCyan = Color(0xFF5FD3C4);
  static const silver = Color(0xFFC7CDD6);
  static const paleYellow = Color(0xFFE8D9A0);
  static const warningOrange = Color(0xFFE5A15C);
  static const errorRed = Color(0xFFE5735C);
}

ThemeData buildLunarDarkTheme() {
  final colorScheme = ColorScheme.dark(
    brightness: Brightness.dark,
    primary: LunarColors.lunarBlue,
    onPrimary: Colors.white,
    secondary: LunarColors.softCyan,
    onSecondary: const Color(0xFF03201D),
    tertiary: LunarColors.paleYellow,
    onTertiary: const Color(0xFF2B2409),
    surface: LunarColors.surfaceDark,
    onSurface: LunarColors.textPrimaryDark,
    onSurfaceVariant: LunarColors.textSecondaryDark,
    surfaceContainerHighest: LunarColors.surfaceElevatedDark,
    secondaryContainer: LunarColors.surfaceElevatedDark,
    onSecondaryContainer: LunarColors.textPrimaryDark,
    error: LunarColors.errorRed,
    onError: Colors.white,
    outline: LunarColors.borderDark,
    outlineVariant: LunarColors.borderDark,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: LunarColors.backgroundDark,
    fontFamily: 'Roboto',
    textTheme: _lunarTextTheme(
      brightness: Brightness.dark,
      primary: LunarColors.textPrimaryDark,
      secondary: LunarColors.textSecondaryDark,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: LunarColors.backgroundDark,
      foregroundColor: LunarColors.textPrimaryDark,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: LunarColors.surfaceElevatedDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: LunarColors.borderDark),
      ),
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: LunarColors.lunarBlue,
        foregroundColor: Colors.white,
        disabledBackgroundColor: LunarColors.surfaceElevatedDark,
        disabledForegroundColor: LunarColors.textSecondaryDark,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: LunarColors.textPrimaryDark,
        disabledForegroundColor: LunarColors.textSecondaryDark,
        side: BorderSide(color: LunarColors.borderDark),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: LunarColors.softCyan),
    ),
    iconTheme: IconThemeData(color: LunarColors.textPrimaryDark),
    sliderTheme: SliderThemeData(
      activeTrackColor: LunarColors.lunarBlue,
      inactiveTrackColor: LunarColors.borderDark,
      thumbColor: LunarColors.lunarBlue,
      overlayColor: LunarColors.lunarBlue.withValues(alpha: 0.15),
      valueIndicatorColor: LunarColors.lunarBlue,
      valueIndicatorTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
    ),
    dividerTheme: DividerThemeData(color: LunarColors.borderDark, space: 1),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: LunarColors.softCyan,
      linearTrackColor: LunarColors.surfaceElevatedDark,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: LunarColors.surfaceElevatedDark,
      selectedColor: LunarColors.lunarBlue.withValues(alpha: 0.28),
      disabledColor: LunarColors.surfaceElevatedDark,
      labelStyle: const TextStyle(color: LunarColors.textPrimaryDark, fontSize: 13),
      secondaryLabelStyle: const TextStyle(color: Colors.white, fontSize: 13),
      side: BorderSide(color: LunarColors.borderDark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: LunarColors.surfaceElevatedDark,
        foregroundColor: LunarColors.textPrimaryDark,
        selectedBackgroundColor: LunarColors.lunarBlue,
        selectedForegroundColor: Colors.white,
        side: BorderSide(color: LunarColors.borderDark),
      ),
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? LunarColors.lunarBlue
            : LunarColors.surfaceElevatedDark,
      ),
      trackOutlineColor: WidgetStateProperty.all(LunarColors.borderDark),
      thumbColor: WidgetStateProperty.all(Colors.white),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: LunarColors.surfaceElevatedDark,
      contentTextStyle: const TextStyle(color: LunarColors.textPrimaryDark),
      actionTextColor: LunarColors.softCyan,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    listTileTheme: ListTileThemeData(
      textColor: LunarColors.textPrimaryDark,
      iconColor: LunarColors.textSecondaryDark,
    ),
  );
}

ThemeData buildLunarLightTheme() {
  final colorScheme = ColorScheme.light(
    brightness: Brightness.light,
    primary: LunarColors.lunarBlue,
    onPrimary: Colors.white,
    secondary: LunarColors.softCyan,
    onSecondary: const Color(0xFF03201D),
    tertiary: LunarColors.paleYellow,
    onTertiary: const Color(0xFF2B2409),
    surface: LunarColors.surfaceLight,
    onSurface: LunarColors.textPrimaryLight,
    onSurfaceVariant: LunarColors.textSecondaryLight,
    surfaceContainerHighest: LunarColors.surfaceElevatedLight,
    secondaryContainer: LunarColors.surfaceElevatedLight,
    onSecondaryContainer: LunarColors.textPrimaryLight,
    error: LunarColors.errorRed,
    onError: Colors.white,
    outline: LunarColors.borderLight,
    outlineVariant: LunarColors.borderLight,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: LunarColors.backgroundLight,
    textTheme: _lunarTextTheme(
      brightness: Brightness.light,
      primary: LunarColors.textPrimaryLight,
      secondary: LunarColors.textSecondaryLight,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: LunarColors.backgroundLight,
      foregroundColor: LunarColors.textPrimaryLight,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: LunarColors.surfaceElevatedLight,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: LunarColors.borderLight),
      ),
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: LunarColors.lunarBlue,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

TextTheme _lunarTextTheme({
  required Brightness brightness,
  required Color primary,
  required Color secondary,
}) {
  final base = ThemeData(useMaterial3: true, brightness: brightness).textTheme;
  return base.copyWith(
    displayLarge: base.displayLarge?.copyWith(color: primary),
    displayMedium: base.displayMedium?.copyWith(color: primary),
    displaySmall: base.displaySmall?.copyWith(color: primary),
    headlineLarge: base.headlineLarge?.copyWith(color: primary, fontWeight: FontWeight.w700),
    headlineMedium: base.headlineMedium?.copyWith(color: primary, fontWeight: FontWeight.w700),
    headlineSmall: base.headlineSmall?.copyWith(color: primary, fontWeight: FontWeight.w700),
    titleLarge: base.titleLarge?.copyWith(color: primary, fontWeight: FontWeight.w600),
    titleMedium: base.titleMedium?.copyWith(color: primary, fontWeight: FontWeight.w600),
    titleSmall: base.titleSmall?.copyWith(color: primary, fontWeight: FontWeight.w600),
    bodyLarge: base.bodyLarge?.copyWith(color: primary),
    bodyMedium: base.bodyMedium?.copyWith(color: secondary),
    bodySmall: base.bodySmall?.copyWith(color: secondary),
    labelLarge: base.labelLarge?.copyWith(color: primary, fontWeight: FontWeight.w600),
    labelMedium: base.labelMedium?.copyWith(color: secondary, fontWeight: FontWeight.w600),
    labelSmall: base.labelSmall?.copyWith(color: secondary, fontWeight: FontWeight.w600),
  );
}
