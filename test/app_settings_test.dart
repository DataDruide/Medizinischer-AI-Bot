import 'package:flutter_test/flutter_test.dart';
import 'package:medizinischer_ai_bot/models/app_settings.dart';

void main() {
  test('rejects unsupported speech locales from persisted settings', () {
    final json = const AppSettings().toJson()..['speechLocale'] = 'fr_FR';

    expect(() => AppSettings.fromJson(json), throwsFormatException);
  });
}
