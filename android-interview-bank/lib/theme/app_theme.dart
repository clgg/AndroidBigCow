import 'package:flutter/material.dart';

import '../state/app_controller.dart';

class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.accent,
    required this.accentMuted,
    required this.success,
    required this.warning,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.onAccent,
  });

  final Color accent;
  final Color accentMuted;
  final Color success;
  final Color warning;
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color onAccent;

  @override
  AppPalette copyWith({
    Color? accent,
    Color? accentMuted,
    Color? success,
    Color? warning,
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? onAccent,
  }) {
    return AppPalette(
      accent: accent ?? this.accent,
      accentMuted: accentMuted ?? this.accentMuted,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      onAccent: onAccent ?? this.onAccent,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) {
      return this;
    }
    return AppPalette(
      accent: Color.lerp(accent, other.accent, t)!,
      accentMuted: Color.lerp(accentMuted, other.accentMuted, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
    );
  }
}

class AppTheme {
  static ThemeData data(AppThemeStyle style) {
    final palette = _palette(style);
    final brightness = style == AppThemeStyle.dark
        ? Brightness.dark
        : Brightness.light;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: palette.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: palette.accent,
        brightness: brightness,
        primary: palette.accent,
        surface: palette.surface,
      ),
      fontFamily: 'Arial',
      textTheme: TextTheme(
        headlineMedium: TextStyle(
          color: palette.textPrimary,
          fontSize: 26,
          fontWeight: FontWeight.w800,
          height: 1.12,
        ),
        titleLarge: TextStyle(
          color: palette.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          height: 1.18,
        ),
        titleMedium: TextStyle(
          color: palette.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
        bodyMedium: TextStyle(
          color: palette.textPrimary,
          fontSize: 14,
          height: 1.45,
        ),
        bodySmall: TextStyle(
          color: palette.textSecondary,
          fontSize: 12,
          height: 1.4,
        ),
        labelMedium: TextStyle(
          color: palette.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      extensions: [palette],
    );
  }

  static AppPalette _palette(AppThemeStyle style) {
    switch (style) {
      case AppThemeStyle.purple:
        return const AppPalette(
          accent: Color(0xFF6F52B5),
          accentMuted: Color(0xFFF1EAF9),
          success: Color(0xFF007A56),
          warning: Color(0xFFB07300),
          background: Color(0xFFFFFAFD),
          surface: Color(0xFFFFFFFF),
          surfaceAlt: Color(0xFFF6EEF8),
          border: Color(0xFFE5D9E9),
          textPrimary: Color(0xFF221B2E),
          textSecondary: Color(0xFF81758A),
          onAccent: Color(0xFFFFFFFF),
        );
      case AppThemeStyle.orange:
        return const AppPalette(
          accent: Color(0xFFFF741F),
          accentMuted: Color(0xFFFFF1DA),
          success: Color(0xFF16A05D),
          warning: Color(0xFFFF741F),
          background: Color(0xFFFFFCF6),
          surface: Color(0xFFFFFFFF),
          surfaceAlt: Color(0xFFFFF7E9),
          border: Color(0xFFEFE0C8),
          textPrimary: Color(0xFF34291D),
          textSecondary: Color(0xFF887B6D),
          onAccent: Color(0xFFFFFFFF),
        );
      case AppThemeStyle.dark:
        return const AppPalette(
          accent: Color(0xFF39BDEC),
          accentMuted: Color(0xFF122234),
          success: Color(0xFFA6F02A),
          warning: Color(0xFFFFC048),
          background: Color(0xFF070B12),
          surface: Color(0xFF0D1420),
          surfaceAlt: Color(0xFF101B2B),
          border: Color(0xFF1E2A3A),
          textPrimary: Color(0xFFEAF3FF),
          textSecondary: Color(0xFF8EA1B8),
          onAccent: Color(0xFF001018),
        );
      case AppThemeStyle.blue:
        return const AppPalette(
          accent: Color(0xFF2E68E8),
          accentMuted: Color(0xFFEAF0FF),
          success: Color(0xFF17BF86),
          warning: Color(0xFFEA9A18),
          background: Color(0xFFF6F8FC),
          surface: Color(0xFFFFFFFF),
          surfaceAlt: Color(0xFFF0F4FA),
          border: Color(0xFFE2E7F0),
          textPrimary: Color(0xFF151A24),
          textSecondary: Color(0xFF778294),
          onAccent: Color(0xFFFFFFFF),
        );
    }
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
