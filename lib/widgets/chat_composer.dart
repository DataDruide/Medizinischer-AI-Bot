import 'package:flutter/material.dart';

import '../services/chat_input_validator.dart';
import '../theme/app_colors.dart';

class ChatComposer extends StatelessWidget {
  const ChatComposer({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.isInitializingSpeech,
    required this.isListening,
    required this.speechEnabled,
    required this.onListenPressed,
    required this.onSendPressed,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final bool isInitializingSpeech;
  final bool isListening;
  final bool speechEnabled;
  final VoidCallback onListenPressed;
  final VoidCallback onSendPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(15, 5, 6, 5),
            decoration: BoxDecoration(
              color: palette.surface,
              border: Border.all(color: palette.border),
              borderRadius: BorderRadius.circular(25),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0C302832),
                  blurRadius: 18,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: ChatInputValidator.maxLength,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Stelle eine Gesundheitsfrage …',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                      counterText: '',
                    ),
                    onSubmitted: (_) => onSendPressed(),
                  ),
                ),
                IconButton(
                  tooltip: !speechEnabled
                      ? 'Spracheingabe in den Einstellungen aktivieren'
                      : isListening
                      ? 'Aufnahme beenden'
                      : 'Spracheingabe starten',
                  color: isListening ? palette.error : palette.secondaryText,
                  onPressed: speechEnabled ? onListenPressed : null,
                  icon: isInitializingSpeech
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          !speechEnabled
                              ? Icons.mic_off_outlined
                              : isListening
                              ? Icons.stop_rounded
                              : Icons.mic_none,
                        ),
                ),
                const SizedBox(width: 3),
                Container(
                  decoration: BoxDecoration(
                    gradient: isLoading ? null : palette.deepGradient,
                    color: isLoading ? palette.mutedText : null,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: isLoading ? null : onSendPressed,
                    tooltip: 'Senden',
                    color: Colors.white,
                    icon: const Icon(Icons.arrow_upward_rounded),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          Text(
            'Ollama lokal · openFDA optional · Daten je Profil gespeichert',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: palette.mutedText),
          ),
        ],
      ),
    );
  }
}
