import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_settings_provider.dart';
import 'providers/operation_status_provider.dart';
import 'screens/splash_screen.dart';
import 'theme/app_colors.dart';

class MediApp extends StatelessWidget {
  const MediApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppSettingsProvider()),
        ChangeNotifierProvider(create: (_) => OperationStatusProvider()),
      ],
      child: Consumer<AppSettingsProvider>(
        builder: (context, settingsProvider, _) => MaterialApp(
          title: 'Medi – Gesundheitsassistent',
          debugShowCheckedModeBanner: false,
          theme: _theme(AppPalette.light, Brightness.light),
          darkTheme: _theme(AppPalette.dark, Brightness.dark),
          themeMode: settingsProvider.settings.themeMode,
          home: const SplashScreen(),
        ),
      ),
    );
  }

  ThemeData _theme(AppPalette palette, Brightness brightness) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: palette.brandStart,
          brightness: brightness,
        ).copyWith(
          primary: palette.primary,
          onPrimary: brightness == Brightness.dark
              ? const Color(0xFF302832)
              : Colors.white,
          secondary: palette.rose,
          surface: palette.surface,
          onSurface: palette.text,
          outline: palette.border,
          error: palette.error,
        );
    final baseTextTheme = ThemeData(brightness: brightness).textTheme.apply(
      fontFamily: 'NunitoSans',
      bodyColor: palette.text,
      displayColor: palette.text,
    );
    final textTheme = baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge!.copyWith(
        fontSize: 36,
        height: 1.12,
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
      ),
      displayMedium: baseTextTheme.displayMedium!.copyWith(
        fontSize: 32,
        height: 1.15,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
      ),
      headlineLarge: baseTextTheme.headlineLarge!.copyWith(
        fontSize: 28,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
      ),
      headlineMedium: baseTextTheme.headlineMedium!.copyWith(
        fontSize: 24,
        height: 1.25,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      titleLarge: baseTextTheme.titleLarge!.copyWith(
        fontSize: 19,
        height: 1.3,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: baseTextTheme.titleMedium!.copyWith(
        fontSize: 16,
        height: 1.35,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: baseTextTheme.bodyLarge!.copyWith(fontSize: 16, height: 1.5),
      bodyMedium: baseTextTheme.bodyMedium!.copyWith(fontSize: 14, height: 1.5),
      bodySmall: baseTextTheme.bodySmall!.copyWith(fontSize: 12, height: 1.4),
      labelLarge: baseTextTheme.labelLarge!.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      ),
      labelMedium: baseTextTheme.labelMedium!.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'NunitoSans',
      textTheme: textTheme,
      iconTheme: IconThemeData(color: palette.secondaryText, size: 21),
      scaffoldBackgroundColor: palette.background,
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: palette.text,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: palette.text),
        iconTheme: IconThemeData(color: palette.primary, size: 22),
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: palette.secondaryText,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: palette.mutedText),
        filled: true,
        fillColor: palette.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: palette.primary,
        selectionColor: palette.primary.withValues(alpha: 0.3),
        selectionHandleColor: palette.rose,
      ),
      extensions: [palette],
    );
  }
}
