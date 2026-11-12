import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class ChatWelcome extends StatelessWidget {
  const ChatWelcome({
    required this.isLoading,
    required this.onSearch,
    super.key,
  });

  final bool isLoading;
  final ValueChanged<String> onSearch;

  static const _suggestions = [
    'Was hilft bei Schlafproblemen?',
    'Ibuprofen',
    'Vitamin D',
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 38, bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: palette.lavenderSurface,
              border: Border.all(color: palette.border),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, size: 15, color: palette.primary),
                const SizedBox(width: 6),
                Text(
                  'LOKALE KI · MEDIKAMENTEN-INFOS AUS openFDA',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 0.55,
                    fontWeight: FontWeight.w700,
                    color: palette.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              gradient: palette.brandGradient,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: palette.brandStart.withValues(alpha: 0.2),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Center(
                  child: Icon(
                    Icons.health_and_safety_outlined,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                Positioned(
                  right: -5,
                  bottom: -5,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: palette.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: palette.border),
                    ),
                    child: Icon(
                      Icons.favorite_rounded,
                      color: palette.rose,
                      size: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Hallo! Was möchtest\ndu wissen?',
            style: TextStyle(
              fontSize: 34,
              height: 1.12,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.1,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            'Stelle eine allgemeine Gesundheitsfrage oder frage nach einem '
            'Medikament. Antworten erstellt Ollama lokal anhand deiner '
            'Angaben; Medikamenteninfos können aus openFDA ergänzt werden.',
            style: TextStyle(
              fontSize: 15,
              height: 1.55,
              color: palette.secondaryText,
            ),
          ),
          const SizedBox(height: 26),
          Text(
            'Beispiele',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 11),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: _suggestions
                .map(
                  (name) => ActionChip(
                    onPressed: isLoading ? null : () => onSearch(name),
                    avatar: Icon(
                      Icons.search_rounded,
                      size: 17,
                      color: palette.primary,
                    ),
                    label: Text(name),
                    backgroundColor: palette.surface,
                    side: BorderSide(color: palette.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          const _MedicalNotice(),
        ],
      ),
    );
  }
}

class _MedicalNotice extends StatelessWidget {
  const _MedicalNotice();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: palette.roseSurface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 19, color: palette.rose),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Keine Diagnose oder Therapieempfehlung. Bei Beschwerden wende '
              'dich an medizinisches Fachpersonal; im Notfall an 112.',
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: palette.secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
