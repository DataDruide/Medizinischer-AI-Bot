import 'package:flutter_test/flutter_test.dart';
import 'package:medizinischer_ai_bot/providers/operation_status_provider.dart';

void main() {
  test('publishes progress, replaces it with completion, and dismisses', () {
    final provider = OperationStatusProvider();
    addTearDown(provider.dispose);

    provider.working('Analyse läuft');
    expect(provider.notice?.phase, OperationPhase.working);
    expect(provider.notice?.title, 'Analyse läuft');

    provider.success('Analyse fertig', detail: 'Sieben Angaben geprüft.');
    expect(provider.notice?.phase, OperationPhase.success);
    expect(provider.notice?.detail, 'Sieben Angaben geprüft.');

    provider.dismiss();
    expect(provider.notice, isNull);
  });
}
