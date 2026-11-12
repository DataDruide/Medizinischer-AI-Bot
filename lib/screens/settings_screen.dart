import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_settings.dart';
import '../providers/app_settings_provider.dart';
import '../providers/operation_status_provider.dart';
import '../services/profile_storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/operation_status_banner.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.profile,
    required this.storage,
    required this.onClearChat,
    required this.onClearMedicationCache,
    super.key,
  });

  final UnlockedProfile profile;
  final ProfileStorageService storage;
  final Future<void> Function() onClearChat;
  final Future<void> Function() onClearMedicationCache;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _baseUrlController;
  late final TextEditingController _modelController;

  @override
  void initState() {
    super.initState();
    final settings = context.read<AppSettingsProvider>().settings;
    _baseUrlController = TextEditingController(text: settings.ollamaBaseUrl);
    _modelController = TextEditingController(text: settings.ollamaModel);
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings(AppSettings settings) async {
    final operations = context.read<OperationStatusProvider>();
    operations.working(
      'Einstellungen werden gespeichert',
      detail: 'Die Änderungen werden verschlüsselt in deinem Profil abgelegt.',
    );
    try {
      await context.read<AppSettingsProvider>().saveSettings(settings);
      if (!mounted) return;
      operations.success(
        'Einstellungen gespeichert',
        detail: 'Sie gelten für dein lokales Profil.',
      );
    } on ProfileStorageException catch (error) {
      if (!mounted) return;
      operations.error('Speichern fehlgeschlagen', detail: error.message);
      _showNotice(error.message);
    }
  }

  Future<void> _saveOllamaConfig() async {
    final model = _modelController.text.trim();
    final baseUrl = _baseUrlController.text.trim();
    if (model.isEmpty || model.length > 100) {
      _showNotice('Bitte gib einen Modellnamen mit maximal 100 Zeichen ein.');
      return;
    }
    if (baseUrl.isNotEmpty) {
      final uri = Uri.tryParse(baseUrl);
      if (uri == null ||
          !const ['http', 'https'].contains(uri.scheme) ||
          uri.host.isEmpty ||
          uri.userInfo.isNotEmpty) {
        _showNotice(
          'Bitte gib eine gültige Ollama-Adresse ohne Zugangsdaten ein.',
        );
        return;
      }
    }
    await _saveSettings(
      context.read<AppSettingsProvider>().settings.copyWith(
        ollamaBaseUrl: baseUrl,
        ollamaModel: model,
      ),
    );
  }

  Future<void> _clearCache() async {
    if (!await _confirm(
      title: 'Medikamenten-Cache löschen?',
      message: 'Gespeicherte openFDA-Treffer dieses Profils werden entfernt.',
      confirmLabel: 'Cache löschen',
    )) {
      return;
    }
    if (!mounted) return;
    final operations = context.read<OperationStatusProvider>();
    operations.working('Medikamenten-Cache wird gelöscht');
    await widget.onClearMedicationCache();
  }

  Future<void> _clearChat() async {
    if (!await _confirm(
      title: 'Chatverlauf löschen?',
      message:
          'Alle Nachrichten und KI-Antworten dieses Profils werden entfernt. '
          'Der Gesundheits-Check bleibt erhalten.',
      confirmLabel: 'Verlauf löschen',
    )) {
      return;
    }
    await widget.onClearChat();
  }

  Future<void> _deleteProfile() async {
    if (!await _confirm(
      title: 'Profil dauerhaft löschen?',
      message:
          'Gesundheits-Check, Einstellungen, Chat und Cache dieses Profils '
          'werden unwiderruflich gelöscht.',
      confirmLabel: 'Profil löschen',
    )) {
      return;
    }
    if (!mounted) return;
    final operations = context.read<OperationStatusProvider>();
    operations.working('Profil wird dauerhaft gelöscht');
    try {
      await widget.storage.deleteProfile(widget.profile.summary.id);
      if (!mounted) return;
      context.read<AppSettingsProvider>().lockProfile();
      operations.success(
        'Profil gelöscht',
        detail: 'Die lokalen Profildaten wurden entfernt.',
      );
      await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => ProfileScreen(storage: widget.storage),
        ),
        (_) => false,
      );
    } on ProfileStorageException catch (error) {
      if (!mounted) return;
      operations.error(
        'Profil konnte nicht gelöscht werden',
        detail: error.message,
      );
      _showNotice(error.message);
    }
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Abbrechen'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showNotice(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final provider = context.watch<AppSettingsProvider>();
    final settings = provider.settings;
    final enabled = !provider.isSaving;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
              child: Text(
                widget.profile.summary.name,
                style: TextStyle(color: palette.secondaryText, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                const OperationStatusBanner(),
                _section(
                  context,
                  title: 'Ollama',
                  subtitle: 'Die Werte aus .env werden als Startwerte genutzt.',
                  icon: Icons.memory_rounded,
                  children: [
                    TextField(
                      controller: _baseUrlController,
                      enabled: enabled,
                      keyboardType: TextInputType.url,
                      decoration: InputDecoration(
                        labelText: 'Ollama-Adresse',
                        hintText:
                            'Leer lassen für plattformspezifischen Standard',
                        helperText:
                            'Android-Emulator: 10.0.2.2 · iOS/Web: 127.0.0.1',
                        filled: true,
                        fillColor: palette.background,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _modelController,
                      enabled: enabled,
                      decoration: InputDecoration(
                        labelText: 'Modell',
                        hintText: 'z. B. qwen2.5:3b',
                        filled: true,
                        fillColor: palette.background,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: enabled ? _saveOllamaConfig : null,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('KI-Einstellungen speichern'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _section(
                  context,
                  title: 'Darstellung',
                  subtitle:
                      'Dein Farbschema bleibt auch im Dunkelmodus erhalten.',
                  icon: Icons.palette_outlined,
                  children: [
                    DropdownButtonFormField<ThemeMode>(
                      initialValue: settings.themeMode,
                      decoration: const InputDecoration(
                        labelText: 'Farbschema',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text('Wie auf dem Gerät'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text('Hell'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text('Dunkel'),
                        ),
                      ],
                      onChanged: !enabled
                          ? null
                          : (mode) {
                              if (mode != null) {
                                _saveSettings(
                                  settings.copyWith(themeMode: mode),
                                );
                              }
                            },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _section(
                  context,
                  title: 'Spracheingabe',
                  subtitle: 'Steuere, ob und in welcher Sprache du diktierst.',
                  icon: Icons.mic_none_rounded,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Spracheingabe aktivieren'),
                      value: settings.speechEnabled,
                      onChanged: enabled
                          ? (value) => _saveSettings(
                              settings.copyWith(speechEnabled: value),
                            )
                          : null,
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: settings.speechLocale,
                      decoration: const InputDecoration(
                        labelText: 'Erkennungssprache',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'de_DE',
                          child: Text('Deutsch'),
                        ),
                        DropdownMenuItem(
                          value: 'en_US',
                          child: Text('English (US)'),
                        ),
                      ],
                      onChanged: !enabled || !settings.speechEnabled
                          ? null
                          : (locale) {
                              if (locale != null) {
                                _saveSettings(
                                  settings.copyWith(speechLocale: locale),
                                );
                              }
                            },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _section(
                  context,
                  title: 'Datenschutz',
                  subtitle: 'Externe Medikamentensuche ist optional.',
                  icon: Icons.shield_outlined,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('openFDA-Suche erlauben'),
                      subtitle: const Text(
                        'Nur passende Medikamentensuchbegriffe werden online '
                        'übertragen.',
                      ),
                      value: settings.openFdaEnabled,
                      onChanged: enabled
                          ? (value) => _saveSettings(
                              settings.copyWith(openFdaEnabled: value),
                            )
                          : null,
                    ),
                    OutlinedButton.icon(
                      onPressed: enabled ? _clearCache : null,
                      icon: const Icon(Icons.delete_sweep_outlined),
                      label: const Text('Medikamenten-Cache löschen'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _section(
                  context,
                  title: 'Lokale Daten',
                  subtitle: 'Alle Aktionen betreffen nur dieses Profil.',
                  icon: Icons.storage_outlined,
                  children: [
                    OutlinedButton.icon(
                      onPressed: enabled ? _clearChat : null,
                      icon: const Icon(Icons.forum_outlined),
                      label: const Text('Chatverlauf löschen'),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: enabled ? _deleteProfile : null,
                      icon: const Icon(Icons.person_remove_outlined),
                      label: const Text('Profil dauerhaft löschen'),
                      style: TextButton.styleFrom(
                        foregroundColor: palette.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: palette.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: palette.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: palette.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
