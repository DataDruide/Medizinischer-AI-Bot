import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:medizinischer_ai_bot/services/open_fda_service.dart';

void main() {
  test('looks up a medication name and parses FDA label fields', () async {
    late Uri requestedUri;
    final client = _RecordingClient((request) async {
      requestedUri = request.url;
      return _response(200, {
        'results': [
          {
            'openfda': {
              'brand_name': ['Advil'],
            },
            'indications_and_usage': ['Pain relief.'],
            'warnings': ['Read the label.'],
          },
        ],
      });
    });
    final service = OpenFdaService(client: client);

    final medication = await service.lookupMedication('Was ist Ibuprofen?');

    expect(requestedUri.host, 'api.fda.gov');
    expect(requestedUri.queryParameters['search'], contains('Ibuprofen'));
    expect(medication?.name, 'Advil');
    expect(medication?.usage, 'Pain relief.');
    expect(medication?.warnings, 'Read the label.');
    service.close();
  });

  test('does not send personal health details to the API', () async {
    var wasCalled = false;
    final client = _RecordingClient((request) async {
      wasCalled = true;
      return _response(200, const {});
    });
    final service = OpenFdaService(client: client);

    final result = await service.lookupMedication(
      'Ich nehme täglich Ibuprofen wegen Schmerzen',
    );

    expect(result, isNull);
    expect(wasCalled, isFalse);
    service.close();
  });

  test('does not treat general health questions as medication searches', () {
    final service = OpenFdaService(
      client: _RecordingClient((_) async {
        return _response(200, const {});
      }),
    );

    expect(
      service.medicationNameFromPrompt('Was hilft bei Schlafproblemen?'),
      isNull,
    );
    expect(service.medicationNameFromPrompt('Übelkeit'), isNull);
    expect(
      service.medicationNameFromPrompt('Ich nehme Ibuprofen wegen Schmerzen'),
      isNull,
    );
    expect(service.medicationNameFromPrompt('Was ist Ibuprofen?'), 'Ibuprofen');
    service.close();
  });
}

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
