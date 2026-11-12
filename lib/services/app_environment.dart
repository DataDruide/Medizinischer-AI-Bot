import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class AppEnvironment {
  static String get ollamaBaseUrl {
    const defined = String.fromEnvironment('OLLAMA_BASE_URL');
    return defined.isNotEmpty ? defined : _value('OLLAMA_BASE_URL') ?? '';
  }

  static String get ollamaModel {
    const defined = String.fromEnvironment('OLLAMA_MODEL');
    return defined.isNotEmpty
        ? defined
        : _value('OLLAMA_MODEL') ?? 'qwen2.5:3b';
  }

  static String? _value(String key) {
    if (!dotenv.isInitialized) return null;
    final value = dotenv.env[key]?.trim();
    return value == null || value.isEmpty ? null : value;
  }
}
