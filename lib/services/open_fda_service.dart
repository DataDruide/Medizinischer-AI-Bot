import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class OpenFdaService {
  OpenFdaService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<MedicationInfo?> lookupMedication(String prompt) async {
    final medicationName = medicationNameFromPrompt(prompt);
    if (medicationName == null) return null;

    final escapedName = medicationName
        .replaceAll(r'\', r'\\')
        .replaceAll('"', r'\"');
    final search =
        'openfda.brand_name:"$escapedName" OR '
        'openfda.generic_name:"$escapedName"';
    final uri = Uri.https('api.fda.gov', '/drug/label.json', {
      'search': search,
      'limit': '1',
    });

    late final http.Response response;
    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 12));
    } on TimeoutException {
      throw const OpenFdaException(
        'Die Suche hat zu lange gedauert. Bitte versuche es erneut.',
      );
    } on http.ClientException {
      throw const OpenFdaException(
        'Keine Verbindung zur Medikamentendatenbank. '
        'Bitte prüfe deine Internetverbindung.',
      );
    }

    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw OpenFdaException(
        'Die Medikamentendatenbank antwortet gerade nicht '
        '(HTTP ${response.statusCode}).',
      );
    }

    late final Map<String, dynamic> payload;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Unerwartetes Antwortformat');
      }
      payload = decoded;
    } on FormatException {
      throw const OpenFdaException(
        'Die Antwort der Medikamentendatenbank konnte nicht gelesen werden.',
      );
    }

    final results = payload['results'];
    if (results is! List || results.isEmpty || results.first is! Map) {
      return null;
    }

    final result = Map<String, dynamic>.from(results.first as Map);
    final openFda = result['openfda'];
    final harmonized = openFda is Map ? openFda : const <String, dynamic>{};
    final brandName = _firstText(harmonized['brand_name']);
    final genericName = _firstText(harmonized['generic_name']);
    final displayName = brandName ?? genericName ?? medicationName;
    final usage =
        _firstText(result['indications_and_usage']) ??
        _firstText(result['purpose']);
    final warnings =
        _firstText(result['boxed_warning']) ??
        _firstText(result['warnings']) ??
        _firstText(result['warnings_and_cautions']);

    return MedicationInfo(
      name: displayName,
      usage: usage == null ? null : _cleanText(usage),
      warnings: warnings == null ? null : _cleanText(warnings),
    );
  }

  void close() => _client.close();

  String? medicationNameFromPrompt(String prompt) =>
      _extractMedicationName(prompt);

  String? _extractMedicationName(String prompt) {
    var name = prompt.trim();
    if (name.isEmpty || name.length > 100) return null;

    name = name.replaceFirst(
      RegExp(
        r'^(?:was ist|was macht|informationen zu|information zu|infos zu|'
        r'info zu|details zu|detail zu|mehr über|mehr zu|wirkung von|'
        r'wirkstoff von|nebenwirkungen von|anwendung von|zu)\s+',
        caseSensitive: false,
      ),
      '',
    );
    name = name.replaceAll(RegExp(r'[?!.,;:]+$'), '').trim();

    final words = name.split(RegExp(r'\s+'));
    final containsPersonalHealthDetails = RegExp(
      r'\b(ich|mein|meine|mir|habe|nehme|schmerz|symptom|allergie)\b',
      caseSensitive: false,
    ).hasMatch(name);
    final containsQuestionOrSymptom = RegExp(
      r'(^|[^A-Za-zÄÖÜäöüß0-9])'
      r'(was|wie|hilft|kann|soll|darf|wofür|bei|gegen|für|'
      r'schlaf|husten|fieber|schwindel|übelkeit|brech|durchfall|'
      r'blut|atem|krampf|migräne|kopfweh|ausschlag|juck|'
      r'beschwerde|symptom)'
      r'(?=$|[^A-Za-zÄÖÜäöüß0-9])',
      caseSensitive: false,
    ).hasMatch(name);
    final isMedicationLike = RegExp(
      r"^[A-Za-zÄÖÜäöüß0-9][A-Za-zÄÖÜäöüß0-9\s'’./+-]*$",
    ).hasMatch(name);

    if (name.isEmpty ||
        name.length > 48 ||
        words.length > 4 ||
        containsPersonalHealthDetails ||
        containsQuestionOrSymptom ||
        !isMedicationLike) {
      return null;
    }
    return name;
  }

  String? _firstText(dynamic value) {
    if (value is String && value.trim().isNotEmpty) return value;
    if (value is List) {
      for (final item in value) {
        if (item is String && item.trim().isNotEmpty) return item;
      }
    }
    return null;
  }

  String _cleanText(String value) {
    final text = value
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return text.length <= 520 ? text : '${text.substring(0, 517)}…';
  }
}

class MedicationInfo {
  const MedicationInfo({
    required this.name,
    this.usage,
    this.warnings,
    this.isCached = false,
  });

  final String name;
  final String? usage;
  final String? warnings;
  final bool isCached;

  MedicationInfo asCached() => MedicationInfo(
    name: name,
    usage: usage,
    warnings: warnings,
    isCached: true,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'usage': usage,
    'warnings': warnings,
    'isCached': isCached,
  };

  factory MedicationInfo.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final usage = json['usage'];
    final warnings = json['warnings'];
    if (name is! String ||
        (usage != null && usage is! String) ||
        (warnings != null && warnings is! String) ||
        (json['isCached'] != null && json['isCached'] is! bool)) {
      throw const FormatException('Ungültige Medikamenteninformation');
    }
    return MedicationInfo(
      name: name,
      usage: usage as String?,
      warnings: warnings as String?,
      isCached: json['isCached'] == true,
    );
  }
}

class OpenFdaException implements Exception {
  const OpenFdaException(this.message);

  final String message;
}
