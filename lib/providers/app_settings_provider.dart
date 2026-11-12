import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../services/app_environment.dart';
import '../services/profile_storage_service.dart';

class AppSettingsProvider extends ChangeNotifier {
  AppSettingsProvider({AppSettings? defaults})
    : _defaults =
          defaults ??
          AppSettings(
            ollamaBaseUrl: AppEnvironment.ollamaBaseUrl,
            ollamaModel: AppEnvironment.ollamaModel,
          ) {
    _settings = _defaults;
  }

  final AppSettings _defaults;
  late AppSettings _settings;
  UnlockedProfile? _profile;
  ProfileStorageService? _storage;
  ProfileData? _activeData;
  bool _isSaving = false;

  AppSettings get settings => _settings;
  LocalProfileSummary? get activeProfile => _profile?.summary;
  bool get isSaving => _isSaving;

  void activateProfile(UnlockedProfile profile, ProfileStorageService storage) {
    _profile = profile;
    _storage = storage;
    _activeData = profile.data;
    _settings = profile.data.settings ?? _defaults;
    notifyListeners();
  }

  Future<void> saveSettings(AppSettings settings) async {
    if (_isSaving) return;
    final profile = _profile;
    final storage = _storage;
    if (profile == null || storage == null) {
      _settings = settings;
      notifyListeners();
      return;
    }

    _isSaving = true;
    notifyListeners();
    final updatedData = (_activeData ?? profile.data).copyWith(
      settings: settings,
    );
    try {
      await storage.saveProfileData(profile, updatedData);
    } finally {
      _isSaving = false;
      notifyListeners();
    }
    _settings = settings;
    _activeData = updatedData;
    notifyListeners();
  }

  void recordProfileData(ProfileData data) {
    _activeData = data;
  }

  void lockProfile() {
    _profile = null;
    _storage = null;
    _activeData = null;
    _settings = _defaults;
    notifyListeners();
  }
}
