class ChatInputValidator {
  const ChatInputValidator._();

  static const maxLength = 500;

  static String? validate(String input) {
    final text = input.trim();
    if (text.isEmpty) return 'Bitte gib eine Frage ein.';
    if (text.length > maxLength) {
      return 'Deine Frage darf höchstens $maxLength Zeichen lang sein.';
    }
    if (RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]').hasMatch(text)) {
      return 'Bitte entferne nicht druckbare Zeichen aus deiner Frage.';
    }
    return null;
  }
}
