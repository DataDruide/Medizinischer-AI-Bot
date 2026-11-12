import 'package:flutter_test/flutter_test.dart';
import 'package:medizinischer_ai_bot/models/health_intake.dart';

void main() {
  test('urgent warning answers produce emergency guidance', () {
    const intake = HealthIntake(
      ageGroup: '18–64',
      topic: 'Beschwerden',
      concern: 'Atemnot',
      duration: 'Seit heute',
      emergencyStatus: EmergencyStatus.yes,
      medicationNotes: '',
      allergyNotes: '',
    );

    expect(intake.hasWarningSigns, isTrue);
    expect(intake.feedback, contains('112'));
    expect(intake.feedback, contains('warte nicht'));
  });

  test('non-urgent feedback states the assistant limits', () {
    const intake = HealthIntake(
      ageGroup: 'Unter 18',
      topic: 'Ein Medikament',
      concern: 'Frage zu einem Präparat',
      duration: 'Seit heute',
      emergencyStatus: EmergencyStatus.none,
      medicationNotes: 'Beispielmedikament',
      allergyNotes: 'Keine bekannt',
    );

    expect(intake.hasWarningSigns, isFalse);
    expect(intake.feedback, contains('keine Diagnose'));
    expect(intake.feedback, contains('Vertrauensperson'));
    expect(intake.feedback, contains('Wechselwirkungen'));
  });
}
