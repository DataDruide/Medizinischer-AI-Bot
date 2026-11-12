import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:medizinischer_ai_bot/models/health_intake.dart';
import 'package:medizinischer_ai_bot/providers/app_settings_provider.dart';
import 'package:medizinischer_ai_bot/providers/operation_status_provider.dart';
import 'package:medizinischer_ai_bot/screens/health_intake_screen.dart';

void main() {
  testWidgets('the bot cannot start before required answers are completed', (
    tester,
  ) async {
    HealthIntake? completedIntake;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppSettingsProvider()),
          ChangeNotifierProvider(create: (_) => OperationStatusProvider()),
        ],
        child: MaterialApp(
          home: HealthIntakeScreen(
            onCompleted: (intake) => completedIntake = intake,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Antworten prüfen und Bot starten'));
    await tester.pumpAndSettle();

    expect(completedIntake, isNull);
    expect(find.text('Bitte wähle eine Antwort.'), findsNWidgets(4));
    expect(find.text('Bitte beschreibe dein Anliegen kurz.'), findsOneWidget);
  });
}
