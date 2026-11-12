import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../models/chat_message.dart';
import '../models/app_settings.dart';
import '../models/health_intake.dart';
import '../providers/app_settings_provider.dart';
import '../providers/operation_status_provider.dart';
import '../services/chat_input_validator.dart';
import '../services/open_fda_service.dart';
import '../services/ollama_chat_service.dart';
import '../services/profile_storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/chat_composer.dart';
import '../widgets/chat_message_tile.dart';
import '../widgets/chat_welcome.dart';
import '../widgets/operation_status_banner.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    required this.intake,
    this.ollamaService,
    this.openFdaService,
    this.profile,
    this.initialData,
    this.storage,
    super.key,
  });

  final HealthIntake intake;
  final OllamaChatService? ollamaService;
  final OpenFdaService? openFdaService;
  final UnlockedProfile? profile;
  final ProfileData? initialData;
  final ProfileStorageService? storage;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final OpenFdaService _service;
  late OllamaChatService _ollamaService;
  final _speech = SpeechToText();
  final _inputController = TextEditingController();
  final _inputFocusNode = FocusNode();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final Map<String, MedicationInfo> _medicationCache = {};

  bool _isLoading = true;
  bool _chatCleared = false;
  bool _intakeAnalysisCompleted = false;
  bool _speechAvailable = false;
  bool _isInitializingSpeech = true;
  bool _isListening = false;
  String _localeId = 'de_DE';

  @override
  void initState() {
    super.initState();
    _service = widget.openFdaService ?? OpenFdaService();
    final settings = context.read<AppSettingsProvider>().settings;
    _ollamaService = _createOllamaService(settings);
    final initialData = widget.initialData;
    if (initialData != null) {
      _messages.addAll(initialData.messages);
      _medicationCache.addAll(initialData.medicationCache);
      _chatCleared = initialData.chatCleared;
      _intakeAnalysisCompleted = initialData.intakeAnalysisCompleted;
    }
    _initializeSpeech();
    if (_messages.isEmpty && !_chatCleared) {
      _messages.add(_intakeFeedbackMessage());
    }
    if (!_intakeAnalysisCompleted && !_chatCleared) {
      unawaited(_startConversation());
    } else {
      _isLoading = false;
    }
  }

  @override
  void dispose() {
    _speech.cancel();
    _service.close();
    _ollamaService.close();
    _inputController.dispose();
    _inputFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeSpeech() async {
    final settings = context.read<AppSettingsProvider>().settings;
    if (!settings.speechEnabled) {
      setState(() => _isInitializingSpeech = false);
      return;
    }
    try {
      final available = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: (error) {
          if (!mounted) return;
          setState(() => _isListening = false);
          _showNotice('Spracheingabe: ${error.errorMsg}');
        },
      );
      if (!mounted) return;

      var localeId = settings.speechLocale;
      if (available) {
        final locales = await _speech.locales();
        for (final locale in locales) {
          if (locale.localeId.toLowerCase().startsWith(
            settings.speechLocale.split('_').first.toLowerCase(),
          )) {
            localeId = locale.localeId;
            break;
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _speechAvailable = available;
        _isInitializingSpeech = false;
        _localeId = localeId;
      });
    } on PlatformException {
      if (!mounted) return;
      setState(() {
        _speechAvailable = false;
        _isInitializingSpeech = false;
      });
    } on MissingPluginException {
      if (!mounted) return;
      setState(() {
        _speechAvailable = false;
        _isInitializingSpeech = false;
      });
    }
  }

  void _onSpeechStatus(String status) {
    if (!mounted) return;
    setState(() => _isListening = status == 'listening');
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    _inputController
      ..text = result.recognizedWords
      ..selection = TextSelection.collapsed(
        offset: result.recognizedWords.length,
      );
    if (mounted) setState(() {});
  }

  Future<void> _analyzeIntake() async {
    final operations = context.read<OperationStatusProvider>();
    operations.working(
      'Medi analysiert deinen Gesundheits-Check',
      detail: 'Die Auswertung erfolgt über den konfigurierten Ollama-Dienst.',
    );
    try {
      final recommendations = await _ollamaService
          .generateIntakeRecommendations(widget.intake);
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage.assistant(
            'Unverbindliche Orientierung zu deinen Angaben:\n\n'
            '$recommendations',
          ),
        );
        _intakeAnalysisCompleted = true;
        _isLoading = false;
      });
      operations.success(
        'Deine Orientierung ist bereit',
        detail: 'Alle sieben Angaben wurden einzeln berücksichtigt.',
      );
      _scrollToBottom();
      await _persist();
    } on OllamaException catch (error) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage.assistant(
            'Die Auswertung ist nicht verfügbar. ${error.message}',
          ),
        );
        _isLoading = false;
      });
      operations.error(
        'Die Analyse ist gerade nicht verfügbar',
        detail: error.message,
      );
      _scrollToBottom();
      await _persist();
    }
  }

  Future<void> _startConversation() async {
    if (!await _persist()) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    await _analyzeIntake();
  }

  Future<void> _toggleListening() async {
    if (_isInitializingSpeech) return;
    final settings = context.read<AppSettingsProvider>().settings;
    final operations = context.read<OperationStatusProvider>();
    if (!settings.speechEnabled) {
      operations.info(
        'Spracheingabe ist ausgeschaltet',
        detail: 'Du kannst sie in den Einstellungen wieder aktivieren.',
      );
      return;
    }
    if (!_speechAvailable) {
      _showNotice(
        'Spracherkennung ist auf diesem Gerät oder Browser nicht verfügbar.',
      );
      return;
    }

    try {
      if (_speech.isListening) {
        await _speech.stop();
        if (mounted) setState(() => _isListening = false);
        operations.success('Spracheingabe beendet');
        return;
      }
      operations.working(
        'Ich höre zu',
        detail: 'Sprich jetzt deine Gesundheitsfrage ein.',
      );
      await _speech.listen(
        onResult: _onSpeechResult,
        listenOptions: SpeechListenOptions(
          localeId: _localeId,
          listenFor: const Duration(seconds: 45),
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.dictation,
        ),
      );
      if (mounted) setState(() => _isListening = _speech.isListening);
    } on PlatformException {
      operations.error(
        'Mikrofonzugriff nicht möglich',
        detail: 'Prüfe bitte die Berechtigungen.',
      );
      _showNotice(
        'Mikrofonzugriff nicht möglich. Prüfe bitte die Berechtigungen.',
      );
    } on MissingPluginException {
      operations.error(
        'Spracheingabe ist nicht verfügbar',
        detail: 'Diese Plattform stellt keine Spracherkennung bereit.',
      );
      _showNotice('Spracheingabe ist auf dieser Plattform nicht verfügbar.');
    }
  }

  Future<void> _sendMessage([String? suggestion]) async {
    if (_isLoading) return;
    final text = (suggestion ?? _inputController.text).trim();
    final validationError = ChatInputValidator.validate(text);
    if (validationError != null) {
      _showNotice(validationError);
      return;
    }

    _inputFocusNode.unfocus();
    final operations = context.read<OperationStatusProvider>();
    final settings = context.read<AppSettingsProvider>().settings;
    operations.working(
      'Deine Nachricht wird sicher gespeichert',
      detail: 'Der Verlauf bleibt deinem lokalen Profil zugeordnet.',
    );
    setState(() {
      _messages.add(ChatMessage.user(text));
      _chatCleared = false;
      _inputController.clear();
      _isLoading = true;
    });
    _scrollToBottom();
    if (!await _persist()) {
      operations.error(
        'Nachricht konnte nicht gespeichert werden',
        detail: 'Sie wurde nicht an Ollama gesendet.',
      );
      if (!mounted) return;
      setState(() {
        _messages.removeLast();
        _inputController.text = text;
        _isLoading = false;
      });
      return;
    }

    ChatMessage reply;
    MedicationInfo? medicationInfo;
    String? medicationContext;
    String? medicationStatusMessage;
    final medicationName = _service.medicationNameFromPrompt(text);
    if (medicationName != null && !settings.openFdaEnabled) {
      medicationStatusMessage =
          'Die openFDA-Suche ist in deinen Einstellungen deaktiviert. '
          'Medi verwendet deshalb keine Produktkennzeichnung.';
      medicationContext =
          'openFDA ist in den Einstellungen deaktiviert. Behaupte keine '
          'konkreten Produktinformationen.';
    } else {
      if (medicationName != null) {
        operations.working(
          'Medikamenteninformation wird gesucht',
          detail: 'An openFDA geht nur der erkannte Suchbegriff.',
        );
      } else {
        operations.working(
          'Medi formuliert eine Antwort',
          detail: 'Die Antwort wird mit deinem Profilkontext erstellt.',
        );
      }
      try {
        if (medicationName != null) {
          medicationInfo = await _service.lookupMedication(text);
          if (medicationInfo != null) {
            _medicationCache[medicationName.toLowerCase()] = medicationInfo;
          }
        }
      } on OpenFdaException catch (error) {
        final cached = medicationName == null
            ? null
            : _medicationCache[medicationName.toLowerCase()];
        medicationInfo = cached?.asCached();
        medicationStatusMessage = cached == null
            ? 'openFDA ist gerade nicht erreichbar. Es gibt keinen gespeicherten '
                  'Treffer für diese Suche. Deine Anfrage wurde nicht '
                  'zwischengespeichert oder später gesendet. Du kannst sie '
                  'manuell erneut senden, sobald du wieder online bist.'
            : 'openFDA ist gerade nicht erreichbar (${error.message}). Ich '
                  'zeige einen gespeicherten Treffer, der veraltet sein kann. '
                  'Sende die Suche manuell erneut, um aktuelle Daten abzurufen.';
        operations.info(
          cached == null
              ? 'Keine Medikamentendaten offline verfügbar'
              : 'Gespeicherte Medikamentendaten werden angezeigt',
          detail: cached == null
              ? 'Die Suche wird nicht automatisch wiederholt.'
              : 'Der gespeicherte Treffer kann veraltet sein.',
        );
      }
    }
    if (medicationInfo != null) {
      medicationContext = [
        'Medikament: ${medicationInfo.name}',
        if (medicationInfo.usage != null)
          'Anwendungsgebiet: ${medicationInfo.usage}',
        if (medicationInfo.warnings != null)
          'Warnhinweise: ${medicationInfo.warnings}',
        if (medicationInfo.isCached)
          'Diese Daten stammen aus einem lokalen Cache und können veraltet '
              'sein.',
      ].join('\n');
    } else if (medicationName != null) {
      medicationContext =
          'openFDA hat keinen passenden Eintrag zurückgegeben. '
          'Behaupte keine konkreten Produktinformationen.';
    }

    operations.working(
      'Medi formuliert eine Antwort',
      detail:
          'Deine Nachricht wird an den konfigurierten Ollama-Dienst gesendet.',
    );
    try {
      final response = await _ollamaService.generateReply(
        intake: widget.intake,
        conversation: _messages,
        medicationContext: medicationContext,
      );
      reply = ChatMessage.assistant(response);
      operations.success(
        'Antwort ist da',
        detail: 'Wenn du möchtest, kannst du direkt nachfragen.',
      );
    } on OllamaException catch (error) {
      reply = ChatMessage.assistant(error.message);
      operations.error(
        'Ollama ist gerade nicht verfügbar',
        detail: error.message,
      );
    }

    if (!mounted) return;
    setState(() {
      if (medicationStatusMessage != null) {
        _messages.add(ChatMessage.assistant(medicationStatusMessage));
      }
      if (medicationInfo != null) {
        _messages.add(ChatMessage.medication(medicationInfo));
      }
      _messages.add(reply);
      _isLoading = false;
    });
    _scrollToBottom();
    await _persist();
  }

  void _clearChat() {
    if (_messages.isEmpty || _isLoading) return;
    setState(() {
      _messages.clear();
      _chatCleared = true;
    });
    unawaited(_persist());
    context.read<OperationStatusProvider>().success(
      'Chat geleert',
      detail: 'Dein Gesundheits-Check und FDA-Cache bleiben erhalten.',
    );
  }

  Future<void> _clearMedicationCache() async {
    _medicationCache.clear();
    await _persist();
    if (!mounted) return;
    context.read<OperationStatusProvider>().success(
      'Medikamenten-Cache gelöscht',
      detail: 'Gespeicherte openFDA-Treffer wurden entfernt.',
    );
  }

  Future<void> _clearChatFromSettings() async {
    if (_isLoading) return;
    setState(() {
      _messages.clear();
      _chatCleared = true;
    });
    await _persist();
    if (!mounted) return;
    context.read<OperationStatusProvider>().success(
      'Chatverlauf gelöscht',
      detail: 'Dein Gesundheits-Check bleibt erhalten.',
    );
  }

  Future<void> _openSettings() async {
    final profile = widget.profile;
    final storage = widget.storage;
    if (profile == null || storage == null) {
      _showNotice('Einstellungen sind nur in einem lokalen Profil verfügbar.');
      return;
    }
    final previousSettings = context.read<AppSettingsProvider>().settings;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(
          profile: profile,
          storage: storage,
          onClearChat: _clearChatFromSettings,
          onClearMedicationCache: _clearMedicationCache,
        ),
      ),
    );
    if (!mounted) return;
    final settings = context.read<AppSettingsProvider>().settings;
    if (widget.ollamaService == null &&
        (settings.ollamaBaseUrl != previousSettings.ollamaBaseUrl ||
            settings.ollamaModel != previousSettings.ollamaModel)) {
      final previousService = _ollamaService;
      _ollamaService = _createOllamaService(settings);
      previousService.close();
    }
    if (settings.speechEnabled != previousSettings.speechEnabled ||
        settings.speechLocale != previousSettings.speechLocale) {
      setState(() => _isInitializingSpeech = true);
      await _speech.cancel();
      if (!mounted) return;
      await _initializeSpeech();
    }
  }

  OllamaChatService _createOllamaService(AppSettings settings) {
    if (widget.ollamaService != null) return widget.ollamaService!;
    final baseUri = settings.ollamaBaseUrl.isEmpty
        ? null
        : Uri.parse(settings.ollamaBaseUrl);
    return OllamaChatService(baseUri: baseUri, model: settings.ollamaModel);
  }

  ChatMessage _intakeFeedbackMessage() => widget.intake.hasWarningSigns
      ? ChatMessage.urgent(widget.intake.feedback)
      : ChatMessage.assistant(widget.intake.feedback);

  Future<bool> _persist() async {
    final storage = widget.storage;
    final profile = widget.profile;
    if (storage == null || profile == null) return true;
    final settingsProvider = context.read<AppSettingsProvider>();
    try {
      final data = ProfileData(
        intake: widget.intake,
        settings: settingsProvider.settings,
        messages: List.unmodifiable(_messages),
        medicationCache: Map.unmodifiable(_medicationCache),
        chatCleared: _chatCleared,
        intakeAnalysisCompleted: _intakeAnalysisCompleted,
      );
      await storage.saveProfileData(profile, data);
      settingsProvider.recordProfileData(data);
      return true;
    } on ProfileStorageException catch (error) {
      _showNotice(error.message);
      return false;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _showNotice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _header(),
                  const OperationStatusBanner(),
                  Expanded(
                    child: _messages.isEmpty
                        ? ChatWelcome(
                            isLoading: _isLoading,
                            onSearch: (name) => _sendMessage(name),
                          )
                        : _conversation(),
                  ),
                  ChatComposer(
                    controller: _inputController,
                    focusNode: _inputFocusNode,
                    isLoading: _isLoading,
                    isInitializingSpeech: _isInitializingSpeech,
                    isListening: _isListening,
                    speechEnabled: context.select(
                      (AppSettingsProvider provider) =>
                          provider.settings.speechEnabled,
                    ),
                    onListenPressed: _toggleListening,
                    onSendPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final palette = context.palette;
    final profileName = context
        .watch<AppSettingsProvider>()
        .activeProfile
        ?.name;
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 10),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: palette.brandGradient,
              borderRadius: BorderRadius.all(Radius.circular(15)),
            ),
            child: const Icon(
              Icons.health_and_safety_outlined,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Medi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: palette.text,
                  ),
                ),
                Text(
                  profileName == null
                      ? 'Dein Gesundheitsassistent'
                      : 'Profil: $profileName',
                  style: TextStyle(fontSize: 12, color: palette.secondaryText),
                ),
              ],
            ),
          ),
          if (_messages.isNotEmpty)
            IconButton(
              onPressed: _isLoading ? null : _clearChat,
              tooltip: 'Chat leeren',
              icon: const Icon(Icons.refresh_rounded),
            ),
          if (widget.profile != null)
            IconButton(
              onPressed: _isLoading ? null : _switchProfile,
              tooltip: 'Profil wechseln',
              icon: const Icon(Icons.people_outline_rounded),
            ),
          IconButton(
            onPressed: _isLoading ? null : _openSettings,
            tooltip: 'Einstellungen',
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
    );
  }

  Future<void> _switchProfile() async {
    context.read<AppSettingsProvider>().lockProfile();
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ProfileScreen(storage: widget.storage),
      ),
    );
  }

  Widget _conversation() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 20, bottom: 22),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          return const OllamaTypingIndicator();
        }
        return ChatMessageTile(message: _messages[index]);
      },
    );
  }
}
