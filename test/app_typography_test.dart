import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medizinischer_ai_bot/app.dart';
import 'package:medizinischer_ai_bot/screens/splash_screen.dart';

void main() {
  testWidgets('uses the bundled Nunito Sans font across the app theme', (
    tester,
  ) async {
    await tester.pumpWidget(const MediApp());

    final theme = Theme.of(tester.element(find.byType(SplashScreen)));
    expect(theme.textTheme.bodyMedium?.fontFamily, 'NunitoSans');
    expect(theme.textTheme.displayMedium?.fontFamily, 'NunitoSans');
    expect(theme.iconTheme.size, 21);
  });
}
