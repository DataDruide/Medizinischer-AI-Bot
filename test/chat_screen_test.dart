import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:medizinischer_ai_bot/models/chat_message.dart';
import 'package:medizinischer_ai_bot/models/health_intake.dart';
import 'package:medizinischer_ai_bot/providers/app_settings_provider.dart';
import 'package:medizinischer_ai_bot/providers/operation_status_provider.dart';
import 'package:medizinischer_ai_bot/screens/chat_screen.dart';
import 'package:medizinischer_ai_bot/services/open_fda_service.dart';
import 'package:medizinischer_ai_bot/services/ollama_chat_service.dart';
import 'package:medizinischer_ai_bot/services/profile_storage_service.dart';

void main() {
  testWidgets('empty chat input shows a validation message', (tester) async {
    final client = _RecordingClient((_) async {
      return _response(200, {
        'message': {'content': jsonEncode(_recommendations)},
      });
    });
    final service = OllamaChatService(
      client: client,
      baseUri: Uri.parse('http://localhost:11434'),
      model: 'qwen2.5:3b',
    );
    await tester.pumpWidget(
      _testApp(
        ChatScreen(
          intake: HealthIntake(
            ageGroup: '18–64',
            topic: 'Allgemeine Gesundheitsfrage',
            concern: 'Schlafprobleme',
            duration: 'Seit wenigen Tagen',
            emergencyStatus: EmergencyStatus.none,
            medicationNotes: '',
            allergyNotes: '',
          ),
          ollamaService: service,
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Unverbindliche Orientierung'), findsOneWidget);
    expect(find.textContaining('• Allergien:'), findsOneWidget);
    await tester.tap(find.byTooltip('Senden'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Bitte gib eine Frage ein.'), findsOneWidget);
  });

  testWidgets('uses the profile cache when openFDA is offline', (tester) async {
    final offlineClient = _OfflineClient();
    final ollama = OllamaChatService(
      client: _RecordingClient((_) async {
        return _response(200, {
          'message': {'content': 'Allgemeine Antwort.'},
        });
      }),
      baseUri: Uri.parse('http://localhost:11434'),
      model: 'qwen2.5:3b',
    );
    await tester.pumpWidget(
      _testApp(
        ChatScreen(
          intake: _intake,
          ollamaService: ollama,
          openFdaService: OpenFdaService(client: offlineClient),
          initialData: const ProfileData(
            messages: [ChatMessage.assistant('Bisherige Unterhaltung.')],
            medicationCache: {
              'ibuprofen': MedicationInfo(
                name: 'Ibuprofen',
                usage: 'Cached use information.',
              ),
            },
            intakeAnalysisCompleted: true,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(TextField), 'Was ist Ibuprofen?');
    await tester.tap(find.byTooltip('Senden'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();

    expect(offlineClient.requestCount, 1);
    expect(find.textContaining('LOKALER CACHE'), findsOneWidget);
    expect(find.textContaining('möglicherweise veraltet'), findsWidgets);
    expect(find.textContaining('manuell erneut'), findsOneWidget);
  });
}

Widget _testApp(Widget home) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AppSettingsProvider()),
      ChangeNotifierProvider(create: (_) => OperationStatusProvider()),
    ],
    child: MaterialApp(home: home),
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

const _recommendations = {
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

class _OfflineClient extends http.BaseClient {
  int requestCount = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requestCount++;
    throw http.ClientException('Offline');
  }
}
