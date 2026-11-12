import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../services/open_fda_service.dart';
import '../theme/app_colors.dart';

class ChatMessageTile extends StatelessWidget {
  const ChatMessageTile({required this.message, super.key});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 310),
          margin: const EdgeInsets.only(bottom: 15, left: 36),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: palette.deepGradient,
            borderRadius: BorderRadius.circular(
              20,
            ).copyWith(bottomRight: const Radius.circular(6)),
          ),
          child: Text(
            message.text,
            style: const TextStyle(color: Colors.white, height: 1.4),
          ),
        ),
      );
    }

    final medication = message.medication;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18, right: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: message.isUrgent
                  ? palette.roseSurface
                  : palette.lavenderSurface,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              message.isUrgent
                  ? Icons.warning_amber_rounded
                  : Icons.health_and_safety_outlined,
              size: 17,
              color: message.isUrgent ? palette.error : palette.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: medication == null
                ? Padding(
                    padding: EdgeInsets.only(top: message.isUrgent ? 0 : 5),
                    child: Container(
                      padding: message.isUrgent
                          ? const EdgeInsets.all(14)
                          : EdgeInsets.zero,
                      decoration: message.isUrgent
                          ? BoxDecoration(
                              color: palette.roseSurface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: palette.border),
                            )
                          : null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (message.isUrgent) ...[
                            Text(
                              'WICHTIG',
                              style: TextStyle(
                                color: palette.error,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 6),
                          ],
                          Text(
                            message.text,
                            style: TextStyle(height: 1.5, color: palette.text),
                          ),
                        ],
                      ),
                    ),
                  )
                : _MedicationCard(medication: medication),
          ),
        ],
      ),
    );
  }
}

class OllamaTypingIndicator extends StatelessWidget {
  const OllamaTypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: palette.primary,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Ollama erstellt deine Antworten …',
            style: TextStyle(fontSize: 13, color: palette.secondaryText),
          ),
        ],
      ),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({required this.medication});

  final MedicationInfo medication;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'OPENFDA · ${medication.isCached ? 'LOKALER CACHE' : 'ARZNEIMITTELINFORMATION'}',
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 0.7,
              fontWeight: FontWeight.w700,
              color: palette.rose,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            medication.name,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: palette.text,
            ),
          ),
          if (medication.usage != null) ...[
            const SizedBox(height: 14),
            const _SectionHeading(title: 'Anwendungsgebiet'),
            const SizedBox(height: 4),
            Text(
              medication.usage!,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: palette.secondaryText,
              ),
            ),
          ],
          if (medication.warnings != null) ...[
            const SizedBox(height: 14),
            const _SectionHeading(title: 'Hinweise aus der Kennzeichnung'),
            const SizedBox(height: 4),
            Text(
              medication.warnings!,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: palette.secondaryText,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            'Quelle: U.S. FDA · Produktkennzeichnungen auf Englisch. '
            '${medication.isCached ? 'Gespeicherter Stand, möglicherweise veraltet. ' : ''}'
            'Die Angaben ersetzen keine medizinische Beratung.',
            style: TextStyle(
              fontSize: 10,
              height: 1.45,
              color: palette.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: palette.text,
      ),
    );
  }
}
