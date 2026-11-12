import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_settings_provider.dart';
import '../providers/operation_status_provider.dart';
import '../services/profile_storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/profile_access_dialogs.dart';
import '../widgets/operation_status_banner.dart';
import '../widgets/profile_tile.dart';
import 'chat_screen.dart';
import 'health_intake_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.storage});

  final ProfileStorageService? storage;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileStorageService _storage;
  List<LocalProfileSummary> _profiles = [];
  bool _isLoading = true;
  bool _isWorking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _storage = widget.storage ?? ProfileStorageService();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    try {
      final profiles = await _storage.listProfiles();
      if (!mounted) return;
      setState(() {
        _profiles = profiles;
        _isLoading = false;
        _error = null;
      });
    } on ProfileStorageException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = error.message;
      });
    }
  }

  Future<void> _createProfile() async {
    final credentials = await showDialog<ProfileCredentials>(
      context: context,
      builder: (_) => const CreateProfileDialog(),
    );
    if (credentials == null || !mounted) return;

    final operations = context.read<OperationStatusProvider>();
    final settingsProvider = context.read<AppSettingsProvider>();
    operations.working(
      'Profil wird eingerichtet',
      detail: 'Deine PIN schützt den lokalen Profilspeicher.',
    );
    setState(() => _isWorking = true);
    try {
      final profile = await _storage.createProfile(
        name: credentials.name,
        pin: credentials.pin,
      );
      if (!mounted) return;
      settingsProvider.activateProfile(profile, _storage);
      operations.success(
        'Profil bereit',
        detail: 'Jetzt richten wir deinen Gesundheits-Check ein.',
      );
      await _loadProfiles();
      if (mounted) await _openProfile(profile);
    } on ProfileStorageException catch (error) {
      operations.error(
        'Profil konnte nicht erstellt werden',
        detail: error.message,
      );
      if (mounted) _showNotice(error.message);
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _unlockProfile(LocalProfileSummary summary) async {
    final pin = await showDialog<String>(
      context: context,
      builder: (_) => UnlockProfileDialog(profileName: summary.name),
    );
    if (pin == null || !mounted) return;

    final operations = context.read<OperationStatusProvider>();
    final settingsProvider = context.read<AppSettingsProvider>();
    operations.working(
      'Profil wird entsperrt',
      detail: 'Deine verschlüsselten Daten werden geladen.',
    );
    setState(() => _isWorking = true);
    try {
      final profile = await _storage.unlockProfile(
        profileId: summary.id,
        pin: pin,
      );
      if (!mounted) return;
      settingsProvider.activateProfile(profile, _storage);
      operations.success(
        'Willkommen zurück, ${summary.name}',
        detail: 'Dein Chat wurde geladen.',
      );
      if (mounted) await _openProfile(profile);
    } on InvalidProfilePinException {
      operations.error(
        'PIN stimmt nicht',
        detail: 'Bitte prüfe deine PIN und versuche es erneut.',
      );
      if (mounted) _showNotice('Die PIN ist nicht korrekt.');
    } on ProfileStorageException catch (error) {
      operations.error(
        'Profil konnte nicht geöffnet werden',
        detail: error.message,
      );
      if (mounted) _showNotice(error.message);
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _openProfile(UnlockedProfile profile) async {
    final navigator = Navigator.of(context);
    final intake = profile.data.intake;
    if (intake != null) {
      await navigator.pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ChatScreen(
            intake: intake,
            profile: profile,
            initialData: profile.data,
            storage: _storage,
          ),
        ),
      );
      return;
    }

    await navigator.pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => HealthIntakeScreen(
          onCompleted: (completedIntake) async {
            final data = profile.data.copyWith(intake: completedIntake);
            try {
              await _storage.saveProfileData(profile, data);
              if (!navigator.mounted) return;
              await navigator.pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => ChatScreen(
                    intake: completedIntake,
                    profile: profile,
                    initialData: data,
                    storage: _storage,
                  ),
                ),
              );
            } on ProfileStorageException catch (error) {
              if (navigator.mounted) {
                ScaffoldMessenger.of(navigator.context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(error.message)));
              }
            }
          },
        ),
      ),
    );
  }

  Future<void> _deleteProfile(LocalProfileSummary profile) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profil löschen?'),
        content: Text(
          'Alle verschlüsselten Gesundheitsangaben und Chatnachrichten von '
          '${profile.name} werden dauerhaft gelöscht.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) return;

    final operations = context.read<OperationStatusProvider>();
    operations.working('Profil wird gelöscht');
    setState(() => _isWorking = true);
    try {
      await _storage.deleteProfile(profile.id);
      operations.success(
        'Profil gelöscht',
        detail: 'Die lokalen Profildaten wurden entfernt.',
      );
      await _loadProfiles();
    } on ProfileStorageException catch (error) {
      operations.error(
        'Profil konnte nicht gelöscht werden',
        detail: error.message,
      );
      if (mounted) _showNotice(error.message);
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  void _showNotice(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 28),
                  _brandMark(context),
                  const SizedBox(height: 12),
                  const OperationStatusBanner(),
                  const SizedBox(height: 24),
                  Text(
                    'Wer nutzt Medi?',
                    style: TextStyle(
                      color: palette.text,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Jedes Profil hat einen getrennten, PIN-geschützten '
                    'Speicher auf diesem Gerät.',
                    style: TextStyle(
                      color: palette.secondaryText,
                      height: 1.45,
                    ),
                  ),
                  if (_isWorking) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    Text(
                      'Profil wird sicher verarbeitet …',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: palette.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  if (_isLoading)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else ...[
                    if (_error != null)
                      Expanded(
                        child: Center(
                          child: Text(
                            _error!,
                            style: TextStyle(color: palette.error),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: _profiles.isEmpty
                            ? Center(
                                child: Text(
                                  'Noch kein Profil vorhanden. '
                                  'Erstelle ein Profil, um zu starten.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: palette.secondaryText,
                                    height: 1.5,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                itemCount: _profiles.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final profile = _profiles[index];
                                  return ProfileTile(
                                    profile: profile,
                                    enabled: !_isWorking,
                                    onTap: () => _unlockProfile(profile),
                                    onDelete: () => _deleteProfile(profile),
                                  );
                                },
                              ),
                      ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _isWorking ? null : _createProfile,
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: const Text('Lokales Profil erstellen'),
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'PIN vergessen? Profile lassen sich nicht '
                      'wiederherstellen. Es gibt keine Cloud-Sicherung.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: palette.mutedText,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _brandMark(BuildContext context) {
    final palette = context.palette;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: palette.brandGradient,
          borderRadius: BorderRadius.all(Radius.circular(17)),
        ),
        child: const Icon(
          Icons.health_and_safety_outlined,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
