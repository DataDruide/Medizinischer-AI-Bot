import 'package:flutter/material.dart';

class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brandStart,
    required this.brandEnd,
    required this.primary,
    required this.rose,
    required this.background,
    required this.surface,
    required this.lavenderSurface,
    required this.roseSurface,
    required this.text,
    required this.secondaryText,
    required this.mutedText,
    required this.border,
    required this.error,
    required this.deepStart,
    required this.deepEnd,
  });

  static const light = AppPalette(
    brandStart: Color(0xFF967A9F),
    brandEnd: Color(0xFFB2737B),
    primary: Color(0xFF684E70),
    rose: Color(0xFF8D555F),
    background: Color(0xFFFBF8FB),
    surface: Color(0xFFFFFFFF),
    lavenderSurface: Color(0xFFF1EAF3),
    roseSurface: Color(0xFFF7EAED),
    text: Color(0xFF302832),
    secondaryText: Color(0xFF706671),
    mutedText: Color(0xFF817783),
    border: Color(0xFFE8E1E9),
    error: Color(0xFF9A4552),
    deepStart: Color(0xFF755A80),
    deepEnd: Color(0xFF8D555F),
  );

  static const dark = AppPalette(
    brandStart: Color(0xFF9A82A6),
    brandEnd: Color(0xFFC17E89),
    primary: Color(0xFFD8BCE2),
    rose: Color(0xFFE6AAB4),
    background: Color(0xFF17131A),
    surface: Color(0xFF241F28),
    lavenderSurface: Color(0xFF382F3D),
    roseSurface: Color(0xFF3B282E),
    text: Color(0xFFF3EDF5),
    secondaryText: Color(0xFFC5BAC9),
    mutedText: Color(0xFFA89BAE),
    border: Color(0xFF463B4B),
    error: Color(0xFFFFB4AB),
    deepStart: Color(0xFF80688C),
    deepEnd: Color(0xFF9E626F),
  );

  final Color brandStart;
  final Color brandEnd;
  final Color primary;
  final Color rose;
  final Color background;
  final Color surface;
  final Color lavenderSurface;
  final Color roseSurface;
  final Color text;
  final Color secondaryText;
  final Color mutedText;
  final Color border;
  final Color error;
  final Color deepStart;
  final Color deepEnd;

  LinearGradient get brandGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [brandStart, brandEnd],
  );

  LinearGradient get deepGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [deepStart, deepEnd],
  );

  @override
  AppPalette copyWith({
    Color? brandStart,
    Color? brandEnd,
    Color? primary,
    Color? rose,
    Color? background,
    Color? surface,
    Color? lavenderSurface,
    Color? roseSurface,
    Color? text,
    Color? secondaryText,
    Color? mutedText,
    Color? border,
    Color? error,
    Color? deepStart,
    Color? deepEnd,
  }) => AppPalette(
    brandStart: brandStart ?? this.brandStart,
    brandEnd: brandEnd ?? this.brandEnd,
    primary: primary ?? this.primary,
    rose: rose ?? this.rose,
    background: background ?? this.background,
    surface: surface ?? this.surface,
    lavenderSurface: lavenderSurface ?? this.lavenderSurface,
    roseSurface: roseSurface ?? this.roseSurface,
    text: text ?? this.text,
    secondaryText: secondaryText ?? this.secondaryText,
    mutedText: mutedText ?? this.mutedText,
    border: border ?? this.border,
    error: error ?? this.error,
    deepStart: deepStart ?? this.deepStart,
    deepEnd: deepEnd ?? this.deepEnd,
  );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      brandStart: Color.lerp(brandStart, other.brandStart, t)!,
      brandEnd: Color.lerp(brandEnd, other.brandEnd, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      rose: Color.lerp(rose, other.rose, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      lavenderSurface: Color.lerp(lavenderSurface, other.lavenderSurface, t)!,
      roseSurface: Color.lerp(roseSurface, other.roseSurface, t)!,
      text: Color.lerp(text, other.text, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      border: Color.lerp(border, other.border, t)!,
      error: Color.lerp(error, other.error, t)!,
      deepStart: Color.lerp(deepStart, other.deepStart, t)!,
      deepEnd: Color.lerp(deepEnd, other.deepEnd, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
