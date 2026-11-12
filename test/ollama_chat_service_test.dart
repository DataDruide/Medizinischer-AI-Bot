import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:medizinischer_ai_bot/models/chat_message.dart';
import 'package:medizinischer_ai_bot/models/health_intake.dart';
import 'package:medizinischer_ai_bot/services/ollama_chat_service.dart';

void main() {
  test(
    'generates one validated recommendation for every intake point',
    () async {
      late String requestBody;
      final client = _RecordingClient((value) async {
        if (value is! http.Request) {
          throw StateError('Expected an HTTP POST request.');
        }
        requestBody = value.body;
        return _response(200, {
          'message': {'content': jsonEncode(_recommendations)},
        });
      });
      final service = OllamaChatService(
        client: client,
        baseUri: Uri.parse('http://localhost:11434'),
        model: 'qwen2.5:3b',
      );

      final response = await service.generateIntakeRecommendations(_intake);

      final payload = jsonDecode(requestBody) as Map<String, dynamic>;
      final messages = payload['messages'] as List<dynamic>;
      final systemPrompt = messages.first['content'] as String;
      final userContext =
          jsonDecode(messages[1]['content'] as String) as Map<String, dynamic>;
      final safeGuidance =
          userContext['safeGuidanceByPoint'] as Map<String, dynamic>;

      expect(payload['format'], 'json');
      expect(
        systemPrompt,
        contains('genau sieben handlungsorientierte Empfehlungen'),
      );
      expect(systemPrompt, contains('Allergien'));
      expect(userContext['concern'], 'Schlafprobleme');
      expect(safeGuidance['Anliegen'], contains('Schlafenszeit'));
      expect(response.split('\n\n'), hasLength(7));
      expect(response, contains('• Altersgruppe:'));
      expect(response, contains('• Akute Warnzeichen:'));
      expect(response, contains('• Allergien:'));
      service.close();
    },
  );

  test('rejects incomplete point-by-point recommendations', () async {
    final client = _RecordingClient((_) async {
      return _response(200, {
        'message': {
          'content': jsonEncode({
            'recommendations': [
              {'point': 'Altersgruppe', 'recommendation': 'Eine Orientierung.'},
            ],
          }),
        },
      });
    });
    final service = OllamaChatService(
      client: client,
      baseUri: Uri.parse('http://localhost:11434'),
      model: 'qwen2.5:3b',
    );

    await expectLater(
      service.generateIntakeRecommendations(_intake),
      throwsA(isA<OllamaException>()),
    );
    service.close();
  });

  test('sends local profile context and conversation to Ollama', () async {
    late Uri requestedUri;
    late String requestBody;
    final client = _RecordingClient((value) async {
      requestedUri = value.url;
      if (value is! http.Request) {
        throw StateError('Expected an HTTP POST request.');
      }
      requestBody = value.body;
      return _response(200, {
        'message': {'content': 'Eine allgemeine, passende Antwort.'},
      });
    });
    final service = OllamaChatService(
      client: client,
      baseUri: Uri.parse('http://localhost:11434'),
      model: 'qwen2.5:3b',
    );

    final response = await service.generateReply(
      intake: _intake,
      conversation: [
        const ChatMessage.assistant('Startinformationen'),
        const ChatMessage.user('Was kann ich tun?'),
      ],
    );

    final payload = jsonDecode(requestBody) as Map<String, dynamic>;
    final messages = payload['messages'] as List<dynamic>;
    final systemPrompt = messages.first['content'] as String;

    expect(requestedUri, Uri.parse('http://localhost:11434/api/chat'));
    expect(payload['model'], 'qwen2.5:3b');
    expect(payload['stream'], isFalse);
    expect(systemPrompt, contains('Altersgruppe: 18–64'));
    expect(systemPrompt, contains('Beschreibung: Schlafprobleme'));
    expect(systemPrompt, contains('Akute Warnzeichen laut Erstabfrage: Nein'));
    expect(systemPrompt, contains('Stelle keine Diagnose'));
    expect(messages.last['content'], 'Was kann ich tun?');
    expect(response, 'Eine allgemeine, passende Antwort.');
    service.close();
  });

  test(
    'reports an unavailable model instead of returning a fake answer',
    () async {
      final client = _RecordingClient((_) async {
        return _response(404, {'error': "model 'qwen2.5:3b' not found"});
      });
      final service = OllamaChatService(
        client: client,
        baseUri: Uri.parse('http://localhost:11434'),
        model: 'qwen2.5:3b',
      );

      await expectLater(
        service.generateReply(intake: _intake, conversation: const []),
        throwsA(
          isA<OllamaException>().having(
            (error) => error.message,
            'message',
            contains('ollama pull qwen2.5:3b'),
          ),
        ),
      );
      service.close();
    },
  );
}

final _recommendations = {
  'recommendations': [
    {'point': 'Altersgruppe', 'recommendation': 'Allgemeine Orientierung.'},
    {'point': 'Gesundheitsthema', 'recommendation': 'Allgemeine Orientierung.'},
    {'point': 'Dauer', 'recommendation': 'Allgemeine Orientierung.'},
    {'point': 'Anliegen', 'recommendation': 'Allgemeine Orientierung.'},
    {
      'point': 'Akute Warnzeichen',
      'recommendation': 'Allgemeine Orientierung.',
    },
    {'point': 'Medikamente', 'recommendation': 'Keine Angaben.'},
    {'point': 'Allergien', 'recommendation': 'Keine Angaben.'},
  ],
};

const _intake = HealthIntake(
  ageGroup: '18–64',
  topic: 'Beschwerden',
  concern: 'Schlafprobleme',
  duration: 'Seit wenigen Tagen',
  emergencyStatus: EmergencyStatus.none,
  medicationNotes: '',
  allergyNotes: '',
);

http.StreamedResponse _response(int statusCode, Object body) {
  return http.StreamedResponse(
    Stream.value(utf8.encode(jsonEncode(body))),
    statusCode,
    headers: const {'content-type': 'application/json'},
  );
}

class _RecordingClient extends http.BaseClient {
  _RecordingClient(this._handler);

  final Future<http.StreamedResponse> Function(http.BaseRequest request)
  _handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _handler(request);
  }
}
