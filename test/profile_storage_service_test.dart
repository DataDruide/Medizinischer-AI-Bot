import 'package:flutter_test/flutter_test.dart';
import 'package:medizinischer_ai_bot/models/app_settings.dart';
import 'package:medizinischer_ai_bot/models/chat_message.dart';
import 'package:medizinischer_ai_bot/models/health_intake.dart';
import 'package:medizinischer_ai_bot/services/open_fda_service.dart';
import 'package:medizinischer_ai_bot/services/profile_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'profiles encrypt and restore data without sharing between users',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final storage = ProfileStorageService(preferences: preferences);
      final alice = await storage.createProfile(name: 'Alice', pin: '123456');
      final bob = await storage.createProfile(name: 'Bob', pin: '654321');
      final intake = HealthIntake(
        ageGroup: '18–64',
        topic: 'Beschwerden',
        concern: 'Private health detail',
        duration: 'Seit heute',
        emergencyStatus: EmergencyStatus.none,
        medicationNotes: 'Private medication',
        allergyNotes: '',
      );
      final data = ProfileData(
        intake: intake,
        settings: const AppSettings(
          speechEnabled: false,
          speechLocale: 'en_US',
          openFdaEnabled: false,
          ollamaModel: 'test-model',
        ),
        messages: const [ChatMessage.user('Private chat message')],
        medicationCache: const {
          'ibuprofen': MedicationInfo(
            name: 'Ibuprofen',
            usage: 'Cached product information',
          ),
        },
      );

      await storage.saveProfileData(alice, data);
      final rawProfiles = preferences.getString('medi.encrypted_profiles.v1')!;
      expect(rawProfiles, isNot(contains('Private health detail')));
      expect(rawProfiles, isNot(contains('Private chat message')));
      expect(rawProfiles, isNot(contains('Cached product information')));

      final restoredAlice = await storage.unlockProfile(
        profileId: alice.summary.id,
        pin: '123456',
      );
      final restoredBob = bob.data;

      expect(restoredAlice.data.intake?.concern, 'Private health detail');
      expect(restoredAlice.data.messages.single.text, 'Private chat message');
      expect(restoredAlice.data.settings?.speechEnabled, isFalse);
      expect(restoredAlice.data.settings?.speechLocale, 'en_US');
      expect(restoredAlice.data.settings?.openFdaEnabled, isFalse);
      expect(restoredAlice.data.settings?.ollamaModel, 'test-model');
      expect(
        restoredAlice.data.medicationCache['ibuprofen']?.usage,
        'Cached product information',
      );
      expect(restoredBob.intake, isNull);
      expect(restoredBob.messages, isEmpty);

      await expectLater(
        storage.unlockProfile(profileId: alice.summary.id, pin: '000000'),
        throwsA(isA<InvalidProfilePinException>()),
      );
    },
  );
}
