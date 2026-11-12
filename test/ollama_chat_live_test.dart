import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:medizinischer_ai_bot/models/health_intake.dart';
import 'package:medizinischer_ai_bot/services/ollama_chat_service.dart';

void main() {
  test(
    'local Ollama returns one recommendation for each intake point',
    () async {
      final service = OllamaChatService(
        baseUri: Uri.parse('http://127.0.0.1:11434'),
        model: 'qwen2.5:3b',
      );

      try {
        final response = await service.generateIntakeRecommendations(_intake);

        expect(response.split('\n\n'), hasLength(7));
        for (final point in const [
          'Altersgruppe',
          'Gesundheitsthema',
          'Dauer',
          'Anliegen',
          'Akute Warnzeichen',
          'Medikamente',
          'Allergien',
        ]) {
          expect(response, contains('• $point:'));
        }
      } finally {
        service.close();
      }
    },
    skip: Platform.environment['RUN_OLLAMA_INTEGRATION_TESTS'] != '1',
  );
}

const _intake = HealthIntake(
  ageGroup: '18–64',
  topic: 'Allgemeine Gesundheitsfrage',
  concern: 'Schlafprobleme',
  duration: 'Seit wenigen Tagen',
  emergencyStatus: EmergencyStatus.none,
  medicationNotes: '',
  allergyNotes: '',
);
