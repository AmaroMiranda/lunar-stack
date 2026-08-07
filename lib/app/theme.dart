import 'package:flutter/material.dart';

/// Design system "Observatory Dark": instrumento óptico noturno — fundo neutro
/// profundo, UM acento dominante (Orbit Blue), a FOTO é sempre o elemento mais
/// colorido. Nada de "carnaval".
abstract class LunarColors {
  // Neutros (do mais escuro ao mais claro).
  static const void950 = Color(0xFF05070D); // fundo (instrumento)
  static const obs900 = Color(0xFF090E18);
  static const obs850 = Color(0xFF0D1421); // superfície (card)
  static const obs800 = Color(0xFF121B2A); // superfície elevada
  static const obs750 = Color(0xFF182337);
  static const border = Color(0xFF1E293F); // borda sutil
  static const borderStrong = Color(0xFF283753);

  // Texto (névoa).
  static const mist100 = Color(0xFFEDF4FF);
  static const mist300 = Color(0xFFAEBBD0);
  static const mist500 = Color(0xFF738098);

  // Acentos.
  static const orbitBlue = Color(0xFF79B8FF); // ação principal / foco / panorama
  static const lunarGold = Color(0xFFE8C87A); // Lua
  static const lunarPearl = Color(0xFFD9E2F0);
  static const solarAmber = Color(0xFFFFB44C);
  static const deepViolet = Color(0xFFA991FF); // deep-sky
  static const onAccent = Color(0xFF04101E); // texto sobre acento claro

  // Estados.
  static const success = Color(0xFF68D7A1);
  static const warning = Color(0xFFFFC96B);
  static const error = Color(0xFFFF7D88);

  // Claro (secundário — o app é dark-first).
  static const bgLight = Color(0xFFF5F7FB);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const borderLight = Color(0xFFDBE1EC);
  static const textLight = Color(0xFF10151F);
  static const textLight2 = Color(0xFF5A6577);

  /// Dados técnicos (dimensões, %, MP, bit) — fonte mono, dígitos tabulares.
  static const monoFallback = <String>['RobotoMono', 'monospace'];
}

/// Estilo para números/medidas técnicas (mono + tabular).
TextStyle monoStyle({double size = 13, Color? color, FontWeight weight = FontWeight.w500}) =>
    TextStyle(
      fontFamilyFallback: LunarColors.monoFallback,
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: 0.2,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

ThemeData buildLunarDarkTheme() {
  const scheme = ColorScheme.dark(
    brightness: Brightness.dark,
    primary: LunarColors.orbitBlue,
    onPrimary: LunarColors.onAccent,
    primaryContainer: Color(0xFF16324F),
    onPrimaryContainer: LunarColors.mist100,
    secondary: LunarColors.lunarGold,
    onSecondary: Color(0xFF241B04),
    tertiary: LunarColors.deepViolet,
    onTertiary: Color(0xFF150A2E),
    surface: LunarColors.obs850,
    onSurface: LunarColors.mist100,
    onSurfaceVariant: LunarColors.mist300,
    surfaceContainerHighest: LunarColors.obs800,
    surfaceContainerHigh: LunarColors.obs800,
    surfaceContainer: LunarColors.obs850,
    surfaceContainerLow: LunarColors.obs900,
    secondaryContainer: LunarColors.obs800,
    onSecondaryContainer: LunarColors.mist100,
    error: LunarColors.error,
    onError: LunarColors.onAccent,
    outline: LunarColors.border,
    outlineVariant: LunarColors.border,
  );

  return _base(scheme, LunarColors.void950, LunarColors.mist100, LunarColors.mist300);
}

ThemeData buildLunarLightTheme() {
  const scheme = ColorScheme.light(
    brightness: Brightness.light,
    primary: Color(0xFF2E6FD6),
    onPrimary: Colors.white,
    secondary: Color(0xFFB68A2E),
    onSecondary: Colors.white,
    surface: LunarColors.surfaceLight,
    onSurface: LunarColors.textLight,
    onSurfaceVariant: LunarColors.textLight2,
    surfaceContainerHighest: Color(0xFFEDF0F6),
    error: Color(0xFFCB4A4A),
    onError: Colors.white,
    outline: LunarColors.borderLight,
    outlineVariant: LunarColors.borderLight,
  );
  return _base(scheme, LunarColors.bgLight, LunarColors.textLight, LunarColors.textLight2);
}

ThemeData _base(ColorScheme scheme, Color bg, Color textPrimary, Color textSecondary) {
  final radiusCard = BorderRadius.circular(18);
  final radiusBtn = BorderRadius.circular(14);

  return ThemeData(
    useMaterial3: true,
    brightness: scheme.brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    fontFamily: 'Roboto',
    splashFactory: InkSparkle.splashFactory,
    textTheme: _textTheme(textPrimary, textSecondary),
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      foregroundColor: textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 19,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: radiusCard,
        side: BorderSide(color: scheme.outline),
      ),
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        disabledBackgroundColor: scheme.surfaceContainerHighest,
        disabledForegroundColor: textSecondary,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: radiusBtn),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.1),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: textPrimary,
        disabledForegroundColor: textSecondary,
        side: BorderSide(color: scheme.outline),
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: radiusBtn),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: scheme.primary,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    iconTheme: IconThemeData(color: textPrimary),
    sliderTheme: SliderThemeData(
      activeTrackColor: scheme.primary,
      inactiveTrackColor: scheme.outline,
      thumbColor: scheme.primary,
      overlayColor: scheme.primary.withValues(alpha: 0.14),
      trackHeight: 3,
      valueIndicatorColor: scheme.primary,
      valueIndicatorTextStyle: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.w700),
    ),
    dividerTheme: DividerThemeData(color: scheme.outline, space: 1, thickness: 1),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: scheme.surfaceContainerHighest,
      linearMinHeight: 6,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: scheme.surfaceContainerHighest,
      selectedColor: scheme.primary.withValues(alpha: 0.22),
      disabledColor: scheme.surfaceContainerHighest,
      labelStyle: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
      secondaryLabelStyle: TextStyle(color: scheme.primary, fontSize: 13, fontWeight: FontWeight.w600),
      side: BorderSide(color: scheme.outline),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: scheme.surfaceContainerHighest,
        foregroundColor: textPrimary,
        selectedBackgroundColor: scheme.primary,
        selectedForegroundColor: scheme.onPrimary,
        side: BorderSide(color: scheme.outline),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? scheme.primary : scheme.surfaceContainerHighest,
      ),
      trackOutlineColor: WidgetStateProperty.all(scheme.outline),
      thumbColor: WidgetStateProperty.all(Colors.white),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: scheme.surfaceContainerHighest,
      contentTextStyle: TextStyle(color: textPrimary),
      actionTextColor: scheme.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: radiusBtn, borderSide: BorderSide(color: scheme.outline)),
      enabledBorder: OutlineInputBorder(borderRadius: radiusBtn, borderSide: BorderSide(color: scheme.outline)),
      focusedBorder: OutlineInputBorder(borderRadius: radiusBtn, borderSide: BorderSide(color: scheme.primary, width: 1.5)),
      hintStyle: TextStyle(color: textSecondary),
    ),
    listTileTheme: ListTileThemeData(textColor: textPrimary, iconColor: textSecondary),
  );
}

TextTheme _textTheme(Color p, Color s) {
  TextStyle t(double size, FontWeight w, Color c, {double ls = 0, double h = 1.2}) =>
      TextStyle(fontSize: size, fontWeight: w, color: c, letterSpacing: ls, height: h);
  return TextTheme(
    displaySmall: t(30, FontWeight.w700, p, ls: -0.6),
    headlineMedium: t(26, FontWeight.w700, p, ls: -0.5),
    headlineSmall: t(22, FontWeight.w700, p, ls: -0.3),
    titleLarge: t(19, FontWeight.w700, p, ls: -0.2),
    titleMedium: t(16, FontWeight.w600, p),
    titleSmall: t(14, FontWeight.w600, p),
    bodyLarge: t(16, FontWeight.w400, p, h: 1.4),
    bodyMedium: t(14, FontWeight.w400, s, h: 1.45),
    bodySmall: t(13, FontWeight.w400, s, h: 1.4),
    labelLarge: t(14, FontWeight.w600, p, ls: 0.1),
    labelMedium: t(12, FontWeight.w700, s, ls: 0.9),
    labelSmall: t(11, FontWeight.w700, s, ls: 1.0),
  );
}
