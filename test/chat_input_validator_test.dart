import 'package:flutter_test/flutter_test.dart';
import 'package:medizinischer_ai_bot/services/chat_input_validator.dart';

void main() {
  test('rejects empty and whitespace-only input', () {
    expect(ChatInputValidator.validate(''), isNotNull);
    expect(ChatInputValidator.validate(' \n\t '), isNotNull);
  });

  test('accepts a trimmed follow-up question', () {
    expect(ChatInputValidator.validate('  Ja, seit gestern.  '), isNull);
  });

  test('rejects overlong and non-printable input', () {
    expect(
      ChatInputValidator.validate('a' * (ChatInputValidator.maxLength + 1)),
      contains('höchstens'),
    );
    expect(ChatInputValidator.validate('Frage\u0000'), contains('Zeichen'));
  });
}
