import 'dart:async';

import 'package:flutter/material.dart';

import '../models/health_intake.dart';
import '../theme/app_colors.dart';
import '../widgets/operation_status_banner.dart';
import 'chat_screen.dart';

class HealthIntakeScreen extends StatefulWidget {
  const HealthIntakeScreen({super.key, this.onCompleted});

  final FutureOr<void> Function(HealthIntake)? onCompleted;

  @override
  State<HealthIntakeScreen> createState() => _HealthIntakeScreenState();
}

class _HealthIntakeScreenState extends State<HealthIntakeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _concernController = TextEditingController();
  final _medicationController = TextEditingController();
  final _allergyController = TextEditingController();

  String? _ageGroup;
  String? _topic;
  String? _duration;
  EmergencyStatus? _emergencyStatus;
  bool _acceptedLimits = false;
  bool _isSubmitting = false;
  String? _consentError;

  @override
  void dispose() {
    _concernController.dispose();
    _medicationController.dispose();
    _allergyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    if (!_acceptedLimits) {
      setState(() => _consentError = 'Bitte bestätige diesen Hinweis.');
      return;
    }

    form.save();
    final intake = HealthIntake(
      ageGroup: _ageGroup!,
      topic: _topic!,
      concern: _concernController.text.trim(),
      duration: _duration!,
      emergencyStatus: _emergencyStatus!,
      medicationNotes: _medicationController.text.trim(),
      allergyNotes: _allergyController.text.trim(),
    );

    final onCompleted = widget.onCompleted;
    if (onCompleted != null) {
      setState(() => _isSubmitting = true);
      try {
        await onCompleted(intake);
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => ChatScreen(intake: intake)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
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
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(top: 18, bottom: 20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bevor wir starten',
                              style: TextStyle(
                                color: palette.text,
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ein paar Angaben helfen mir, dir eine '
                              'passende allgemeine Orientierung zu geben.',
                              style: TextStyle(
                                color: palette.secondaryText,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 22),
                            _choiceField(
                              label: 'Altersgruppe',
                              value: _ageGroup,
                              options: const [
                                'Unter 18',
                                '18–64',
                                '65 oder älter',
                              ],
                              onChanged: (value) => _ageGroup = value,
                            ),
                            const SizedBox(height: 14),
                            _choiceField(
                              label: 'Worum geht es hauptsächlich?',
                              value: _topic,
                              options: const [
                                'Beschwerden',
                                'Ein Medikament',
                                'Allgemeine Gesundheitsfrage',
                              ],
                              onChanged: (value) => _topic = value,
                            ),
                            const SizedBox(height: 14),
                            _choiceField(
                              label: 'Wie lange besteht das Anliegen?',
                              value: _duration,
                              options: const [
                                'Seit heute',
                                'Seit wenigen Tagen',
                                'Seit längerer Zeit',
                                'Keine Beschwerden, nur eine Frage',
                              ],
                              onChanged: (value) => _duration = value,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _concernController,
                              minLines: 3,
                              maxLines: 5,
                              maxLength: 500,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: _decoration(
                                'Was möchtest du klären?',
                                hint: 'Beschreibe dein Anliegen kurz',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().length < 5) {
                                  return 'Bitte beschreibe dein Anliegen kurz.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),
                            _warningQuestion(),
                            const SizedBox(height: 18),
                            _optionalNotes(),
                            const SizedBox(height: 18),
                            _limitsConfirmation(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _startButton(),
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
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 4),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: palette.brandGradient,
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
            child: const Icon(
              Icons.health_and_safety_outlined,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              'Medi · Gesundheits-Check',
              style: TextStyle(
                color: palette.text,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '1 von 1',
            style: TextStyle(color: palette.mutedText, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _choiceField({
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: _decoration(label),
      items: options
          .map((option) => DropdownMenuItem(value: option, child: Text(option)))
          .toList(),
      validator: (answer) =>
          answer == null ? 'Bitte wähle eine Antwort.' : null,
      onChanged: (answer) => setState(() => onChanged(answer)),
    );
  }

  Widget _warningQuestion() {
    return FormField<EmergencyStatus>(
      validator: (value) => value == null ? 'Bitte wähle eine Antwort.' : null,
      onSaved: (value) => _emergencyStatus = value,
      builder: (field) {
        final palette = context.palette;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hast du gerade eines dieser Warnzeichen?',
              style: TextStyle(
                color: palette.text,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Starke Atemnot, Brustschmerz, Bewusstlosigkeit oder starke Blutung',
              style: TextStyle(
                color: palette.secondaryText,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _urgencyChip(field, EmergencyStatus.none, 'Nein'),
                _urgencyChip(field, EmergencyStatus.yes, 'Ja'),
                _urgencyChip(field, EmergencyStatus.unsure, 'Unsicher'),
              ],
            ),
            if (field.hasError) ...[
              const SizedBox(height: 4),
              Text(
                field.errorText!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ],
            if (field.value != null && field.value != EmergencyStatus.none) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: palette.roseSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: palette.border),
                ),
                child: Text(
                  'Wenn eines dieser Warnzeichen gerade auftritt, rufe '
                  'sofort 112. Warte nicht auf den Chat.',
                  style: TextStyle(
                    color: palette.rose,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _urgencyChip(
    FormFieldState<EmergencyStatus> field,
    EmergencyStatus status,
    String label,
  ) {
    final palette = context.palette;
    return ChoiceChip(
      label: Text(label),
      selected: field.value == status,
      onSelected: (_) => field.didChange(status),
      selectedColor: palette.lavenderSurface,
      side: BorderSide(
        color: field.value == status ? palette.primary : palette.border,
      ),
    );
  }

  Widget _optionalNotes() {
    final palette = context.palette;
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      title: Text(
        'Medikamente und Allergien (optional)',
        style: TextStyle(
          color: palette.text,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        'Wird an Ollama gesendet; Wechselwirkungen werden nicht geprüft.',
        style: TextStyle(color: palette.secondaryText, fontSize: 12),
      ),
      children: [
        TextField(
          controller: _medicationController,
          maxLines: 2,
          maxLength: 250,
          decoration: _decoration('Derzeitige Medikamente', hint: 'Optional'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _allergyController,
          maxLines: 2,
          maxLength: 250,
          decoration: _decoration(
            'Allergien oder Unverträglichkeiten',
            hint: 'Optional',
          ),
        ),
      ],
    );
  }

  Widget _limitsConfirmation() {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          value: _acceptedLimits,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: palette.primary,
          title: Text(
            'Ich verstehe, dass Medi keine Diagnose stellt und keine '
            'Notfallversorgung ersetzt. Meine Angaben werden verschlüsselt '
            'in diesem lokalen Profil gespeichert und für Chatantworten an '
            'meinen konfigurierten Ollama-Dienst gesendet.',
            style: TextStyle(color: palette.text, fontSize: 13, height: 1.4),
          ),
          onChanged: (value) => setState(() {
            _acceptedLimits = value ?? false;
            _consentError = null;
          }),
        ),
        if (_consentError != null)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              _consentError!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          'Es gibt keine Cloud-Synchronisierung. Medikamentensuchbegriffe '
          'können online an openFDA übertragen werden. Bei akuten Beschwerden '
          'rufe 112.',
          style: TextStyle(color: palette.mutedText, fontSize: 11, height: 1.4),
        ),
      ],
    );
  }

  Widget _startButton() {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _isSubmitting ? null : _submit,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.arrow_forward_rounded),
          label: Text(
            _isSubmitting
                ? 'Sichere deine Angaben …'
                : 'Antworten prüfen und Bot starten',
          ),
          style: FilledButton.styleFrom(
            backgroundColor: palette.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, {String? hint}) {
    final palette = context.palette;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: palette.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: palette.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: palette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: palette.primary, width: 1.5),
      ),
    );
  }
}
