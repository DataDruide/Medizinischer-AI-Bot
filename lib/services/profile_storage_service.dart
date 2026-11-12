import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_message.dart';
import '../models/app_settings.dart';
import '../models/health_intake.dart';
import 'open_fda_service.dart';

class ProfileStorageService {
  ProfileStorageService({SharedPreferences? preferences})
    : _providedPreferences = preferences;

  static const _storageKey = 'medi.encrypted_profiles.v1';
  static const _pbkdf2Iterations = 600000;

  final SharedPreferences? _providedPreferences;
  final _cipher = AesGcm.with256bits();
  final _kdf = Pbkdf2.hmacSha256(iterations: _pbkdf2Iterations, bits: 256);

  Future<SharedPreferences> get _preferences async =>
      _providedPreferences ?? SharedPreferences.getInstance();

  Future<List<LocalProfileSummary>> listProfiles() async {
    final storedProfiles = await _readProfiles();
    return storedProfiles.map(LocalProfileSummary.fromStored).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<UnlockedProfile> createProfile({
    required String name,
    required String pin,
  }) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty || normalizedName.length > 32) {
      throw const ProfileStorageException(
        'Der Profilname muss 1 bis 32 Zeichen lang sein.',
      );
    }
    if (!RegExp(r'^\d{6,12}$').hasMatch(pin)) {
      throw const ProfileStorageException(
        'Die PIN muss aus 6 bis 12 Ziffern bestehen.',
      );
    }

    final profiles = await _readProfiles();
    if (profiles.any(
      (profile) =>
          LocalProfileSummary.fromStored(profile).name.toLowerCase() ==
          normalizedName.toLowerCase(),
    )) {
      throw const ProfileStorageException(
        'Ein Profil mit diesem Namen existiert bereits.',
      );
    }

    final id = base64Url.encode(_secureRandomBytes(16)).replaceAll('=', '');
    final salt = _secureRandomBytes(16);
    final key = await _deriveKey(pin, salt);
    const data = ProfileData();
    final encrypted = await _encrypt(id, data, key);
    final stored = {
      'id': id,
      'name': normalizedName,
      'salt': base64Encode(salt),
      ...encrypted,
    };
    await _writeProfiles([...profiles, stored]);
    return UnlockedProfile(
      summary: LocalProfileSummary(id: id, name: normalizedName),
      key: key,
      data: data,
    );
  }

  Future<UnlockedProfile> unlockProfile({
    required String profileId,
    required String pin,
  }) async {
    final profiles = await _readProfiles();
    final stored = profiles.where((profile) => profile['id'] == profileId);
    if (stored.isEmpty) {
      throw const ProfileStorageException('Das Profil wurde nicht gefunden.');
    }

    final profile = stored.first;
    final summary = LocalProfileSummary.fromStored(profile);
    final salt = _decodeBase64(profile, 'salt');
    final nonce = _decodeBase64(profile, 'nonce');
    final cipherText = _decodeBase64(profile, 'cipherText');
    final mac = _decodeBase64(profile, 'mac');
    if (salt.length != 16 ||
        nonce.length != _cipher.nonceLength ||
        mac.length != _cipher.macAlgorithm.macLength) {
      throw const ProfileStorageException(
        'Das gespeicherte Profil ist beschädigt.',
      );
    }
    final key = await _deriveKey(pin, salt);
    final secretBox = SecretBox(cipherText, nonce: nonce, mac: Mac(mac));

    late final List<int> clearText;
    try {
      clearText = await _cipher.decrypt(
        secretBox,
        secretKey: key,
        aad: utf8.encode(summary.id),
      );
    } on SecretBoxAuthenticationError {
      throw const InvalidProfilePinException();
    }

    late final ProfileData data;
    try {
      final decoded = jsonDecode(utf8.decode(clearText));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Unerwartetes Datenformat');
      }
      data = ProfileData.fromJson(decoded);
    } on FormatException {
      throw const ProfileStorageException(
        'Die Profildaten sind beschädigt und konnten nicht gelesen werden.',
      );
    } on TypeError {
      throw const ProfileStorageException(
        'Die Profildaten sind unvollständig und konnten nicht gelesen werden.',
      );
    }

    return UnlockedProfile(summary: summary, key: key, data: data);
  }

  Future<void> saveProfileData(
    UnlockedProfile profile,
    ProfileData data,
  ) async {
    final profiles = await _readProfiles();
    final index = profiles.indexWhere(
      (stored) => stored['id'] == profile.summary.id,
    );
    if (index < 0) {
      throw const ProfileStorageException(
        'Das Profil wurde gelöscht. Die Änderungen konnten nicht gespeichert '
        'werden.',
      );
    }

    profiles[index] = {
      ...profiles[index],
      ...await _encrypt(profile.summary.id, data, profile.key),
    };
    await _writeProfiles(profiles);
  }

  Future<void> deleteProfile(String profileId) async {
    final profiles = await _readProfiles();
    final remaining = profiles
        .where((profile) => profile['id'] != profileId)
        .toList();
    if (remaining.length == profiles.length) {
      throw const ProfileStorageException('Das Profil wurde nicht gefunden.');
    }
    await _writeProfiles(remaining);
  }

  Future<SecretKey> _deriveKey(String pin, List<int> salt) {
    return _kdf.deriveKey(secretKey: SecretKey(utf8.encode(pin)), nonce: salt);
  }

  Future<Map<String, String>> _encrypt(
    String profileId,
    ProfileData data,
    SecretKey key,
  ) async {
    final secretBox = await _cipher.encrypt(
      utf8.encode(jsonEncode(data.toJson())),
      secretKey: key,
      nonce: _cipher.newNonce(),
      aad: utf8.encode(profileId),
    );
    return {
      'nonce': base64Encode(secretBox.nonce),
      'cipherText': base64Encode(secretBox.cipherText),
      'mac': base64Encode(secretBox.mac.bytes),
    };
  }

  Future<List<Map<String, dynamic>>> _readProfiles() async {
    late final String? value;
    try {
      value = (await _preferences).getString(_storageKey);
    } on PlatformException {
      throw const ProfileStorageException(
        'Der lokale Profilspeicher ist nicht verfügbar.',
      );
    }
    if (value == null) return [];

    try {
      final decoded = jsonDecode(value);
      if (decoded is! List) throw const FormatException();
      return decoded.map((entry) {
        if (entry is! Map<String, dynamic>) throw const FormatException();
        LocalProfileSummary.fromStored(entry);
        return entry;
      }).toList();
    } on FormatException {
      throw const ProfileStorageException(
        'Der lokale Profilspeicher ist beschädigt.',
      );
    }
  }

  Future<void> _writeProfiles(List<Map<String, dynamic>> profiles) async {
    late final bool saved;
    try {
      saved = await (await _preferences).setString(
        _storageKey,
        jsonEncode(profiles),
      );
    } on PlatformException {
      throw const ProfileStorageException(
        'Der lokale Profilspeicher ist nicht verfügbar.',
      );
    }
    if (!saved) {
      throw const ProfileStorageException(
        'Die Änderungen konnten nicht dauerhaft gespeichert werden.',
      );
    }
  }

  List<int> _decodeBase64(Map<String, dynamic> profile, String key) {
    final value = profile[key];
    if (value is! String) {
      throw const ProfileStorageException(
        'Das gespeicherte Profil ist unvollständig.',
      );
    }
    try {
      return base64Decode(value);
    } on FormatException {
      throw const ProfileStorageException(
        'Das gespeicherte Profil ist beschädigt.',
      );
    }
  }

  List<int> _secureRandomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }
}

class LocalProfileSummary {
  const LocalProfileSummary({required this.id, required this.name});

  factory LocalProfileSummary.fromStored(Map<String, dynamic> stored) {
    final id = stored['id'];
    final name = stored['name'];
    if (id is! String || name is! String) {
      throw const ProfileStorageException(
        'Ein gespeichertes Profil ist unvollständig.',
      );
    }
    return LocalProfileSummary(id: id, name: name);
  }

  final String id;
  final String name;
}

class UnlockedProfile {
  const UnlockedProfile({
    required this.summary,
    required this.key,
    required this.data,
  });

  final LocalProfileSummary summary;
  final SecretKey key;
  final ProfileData data;
}

class ProfileData {
  const ProfileData({
    this.intake,
    this.settings,
    this.messages = const [],
    this.medicationCache = const {},
    this.chatCleared = false,
    this.intakeAnalysisCompleted = false,
  });

  final HealthIntake? intake;
  final AppSettings? settings;
  final List<ChatMessage> messages;
  final Map<String, MedicationInfo> medicationCache;
  final bool chatCleared;
  final bool intakeAnalysisCompleted;

  Map<String, dynamic> toJson() => {
    'intake': intake?.toJson(),
    'settings': settings?.toJson(),
    'messages': messages.map((message) => message.toJson()).toList(),
    'medicationCache': medicationCache.map(
      (key, value) => MapEntry(key, value.toJson()),
    ),
    'chatCleared': chatCleared,
    'intakeAnalysisCompleted': intakeAnalysisCompleted,
  };

  ProfileData copyWith({
    HealthIntake? intake,
    AppSettings? settings,
    List<ChatMessage>? messages,
    Map<String, MedicationInfo>? medicationCache,
    bool? chatCleared,
    bool? intakeAnalysisCompleted,
  }) => ProfileData(
    intake: intake ?? this.intake,
    settings: settings ?? this.settings,
    messages: messages ?? this.messages,
    medicationCache: medicationCache ?? this.medicationCache,
    chatCleared: chatCleared ?? this.chatCleared,
    intakeAnalysisCompleted:
        intakeAnalysisCompleted ?? this.intakeAnalysisCompleted,
  );

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    final intakeJson = json['intake'];
    final settingsJson = json['settings'];
    final messagesJson = json['messages'];
    final cacheJson = json['medicationCache'];
    if ((intakeJson != null && intakeJson is! Map<String, dynamic>) ||
        (settingsJson != null && settingsJson is! Map<String, dynamic>) ||
        messagesJson is! List ||
        cacheJson is! Map<String, dynamic>) {
      throw const FormatException('Ungültige Profildaten');
    }
    return ProfileData(
      intake: intakeJson == null ? null : HealthIntake.fromJson(intakeJson),
      settings: settingsJson == null
          ? null
          : AppSettings.fromJson(settingsJson),
      messages: messagesJson
          .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
          .toList(),
      medicationCache: cacheJson.map(
        (key, value) => MapEntry(
          key,
          MedicationInfo.fromJson(value as Map<String, dynamic>),
        ),
      ),
      chatCleared: json['chatCleared'] == true,
      intakeAnalysisCompleted: json['intakeAnalysisCompleted'] == true,
    );
  }
}

class ProfileStorageException implements Exception {
  const ProfileStorageException(this.message);

  final String message;

  @override
  String toString() => message;
}

class InvalidProfilePinException implements Exception {
  const InvalidProfilePinException();
}
