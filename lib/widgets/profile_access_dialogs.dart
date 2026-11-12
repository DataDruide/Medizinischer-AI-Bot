import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProfileCredentials {
  const ProfileCredentials({required this.name, required this.pin});

  final String name;
  final String pin;
}

class CreateProfileDialog extends StatefulWidget {
  const CreateProfileDialog({super.key});

  @override
  State<CreateProfileDialog> createState() => _CreateProfileDialogState();
}

class _CreateProfileDialogState extends State<CreateProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Profil erstellen'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              maxLength: 32,
              decoration: const InputDecoration(labelText: 'Profilname'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Bitte gib einen Namen ein.'
                  : null,
            ),
            TextFormField(
              controller: _pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 12,
              decoration: const InputDecoration(
                labelText: 'PIN (6 bis 12 Ziffern)',
              ),
              validator: (value) => value == null || value.length < 6
                  ? 'Die PIN muss mindestens 6 Ziffern haben.'
                  : null,
            ),
            TextFormField(
              controller: _confirmController,
              obscureText: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 12,
              decoration: const InputDecoration(labelText: 'PIN wiederholen'),
              validator: (value) => value != _pinController.text
                  ? 'Die PINs stimmen nicht überein.'
                  : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              ProfileCredentials(
                name: _nameController.text.trim(),
                pin: _pinController.text,
              ),
            );
          },
          child: const Text('Erstellen'),
        ),
      ],
    );
  }
}

class UnlockProfileDialog extends StatefulWidget {
  const UnlockProfileDialog({required this.profileName, super.key});

  final String profileName;

  @override
  State<UnlockProfileDialog> createState() => _UnlockProfileDialogState();
}

class _UnlockProfileDialogState extends State<UnlockProfileDialog> {
  final _pinController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Profil ${widget.profileName}'),
      content: TextField(
        controller: _pinController,
        autofocus: true,
        obscureText: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        maxLength: 12,
        decoration: const InputDecoration(labelText: 'PIN'),
        onSubmitted: (_) => Navigator.pop(context, _pinController.text),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _pinController.text),
          child: const Text('Entsperren'),
        ),
      ],
    );
  }
}
