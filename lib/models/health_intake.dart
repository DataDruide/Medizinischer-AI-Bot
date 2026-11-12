enum EmergencyStatus { none, yes, unsure }

class HealthIntake {
  const HealthIntake({
    required this.ageGroup,
    required this.topic,
    required this.concern,
    required this.duration,
    required this.emergencyStatus,
    required this.medicationNotes,
    required this.allergyNotes,
  });

  final String ageGroup;
  final String topic;
  final String concern;
  final String duration;
  final EmergencyStatus emergencyStatus;
  final String medicationNotes;
  final String allergyNotes;

  bool get hasWarningSigns => emergencyStatus != EmergencyStatus.none;

  Map<String, String> toJson() => {
    'ageGroup': ageGroup,
    'topic': topic,
    'concern': concern,
    'duration': duration,
    'emergencyStatus': emergencyStatus.name,
    'medicationNotes': medicationNotes,
    'allergyNotes': allergyNotes,
  };

  factory HealthIntake.fromJson(Map<String, dynamic> json) {
    final emergencyStatus = EmergencyStatus.values.where(
      (status) => status.name == json['emergencyStatus'],
    );
    if (json['ageGroup'] is! String ||
        json['topic'] is! String ||
        json['concern'] is! String ||
        json['duration'] is! String ||
        emergencyStatus.isEmpty ||
        json['medicationNotes'] is! String ||
        json['allergyNotes'] is! String) {
      throw const FormatException('Ungültiger Gesundheits-Check');
    }
    return HealthIntake(
      ageGroup: json['ageGroup'] as String,
      topic: json['topic'] as String,
      concern: json['concern'] as String,
      duration: json['duration'] as String,
      emergencyStatus: emergencyStatus.first,
      medicationNotes: json['medicationNotes'] as String,
      allergyNotes: json['allergyNotes'] as String,
    );
  }

  String get feedback {
    final summary =
        'Danke. Für die Altersgruppe „$ageGroup“ hast du „$topic“ angegeben: '
        '„$concern“ '
        '(${duration.toLowerCase()}). Ich kann diese Angaben nicht medizinisch '
        'bewerten und keine Diagnose stellen.';
    final detailsNote = medicationNotes.isNotEmpty || allergyNotes.isNotEmpty
        ? 'Nenne deine Angaben zu Medikamenten und Allergien bei einem '
              'Gespräch mit medizinischem Fachpersonal; Medi prüft keine '
              'Wechselwirkungen.'
        : '';
    const privacyNote =
        'Dein Fragebogen und Chatverlauf werden verschlüsselt in diesem '
        'lokalen Profil gespeichert. Für Chatantworten gehen deine Angaben an '
        'den konfigurierten Ollama-Dienst; passende Medikamentensuchbegriffe '
        'können zusätzlich online an openFDA übertragen werden. Es gibt keine '
        'Cloud-Synchronisierung.';

    if (hasWarningSigns) {
      return [
        summary,
        'Wichtig: Du hast bei den akuten Warnzeichen „'
            '${emergencyStatus == EmergencyStatus.yes ? 'Ja' : 'Unsicher'}“ '
            'gewählt. Wenn starke Atemnot, Brustschmerz, Bewusstlosigkeit oder '
            'starke Blutung gerade auftreten: rufe sofort 112 und warte nicht '
            'auf eine Antwort im Chat.',
        if (detailsNote.isNotEmpty) detailsNote,
        privacyNote,
      ].join('\n\n');
    }

    final advice = switch (ageGroup) {
      'Unter 18' =>
        'Bitte besprich Beschwerden und Medikamente mit einer erwachsenen '
            'Vertrauensperson und medizinischem Fachpersonal.',
      '65 oder älter' =>
        'Bei neuen, anhaltenden, starken oder zunehmenden Beschwerden lass '
            'dich ärztlich beraten. Lass mögliche Wechselwirkungen in einer '
            'Apotheke oder Praxis prüfen.',
      _ =>
        'Bei neuen, anhaltenden, starken oder zunehmenden Beschwerden lass '
            'dich ärztlich beraten. Fragen zu Präparaten kann auch eine '
            'Apotheke klären.',
    };

    return [
      summary,
      advice,
      'Ändere oder starte Medikamente nicht allein aufgrund dieses Chats.',
      if (detailsNote.isNotEmpty) detailsNote,
      privacyNote,
    ].join('\n\n');
  }
}
