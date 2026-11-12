import '../services/open_fda_service.dart';

class ChatMessage {
  const ChatMessage.user(this.text)
    : isUser = true,
      isUrgent = false,
      medication = null;

  const ChatMessage.assistant(this.text)
    : isUser = false,
      isUrgent = false,
      medication = null;

  const ChatMessage.urgent(this.text)
    : isUser = false,
      isUrgent = true,
      medication = null;

  const ChatMessage.medication(MedicationInfo value)
    : text = '',
      isUser = false,
      isUrgent = false,
      medication = value;

  final String text;
  final bool isUser;
  final bool isUrgent;
  final MedicationInfo? medication;

  Map<String, dynamic> toJson() => {
    'text': text,
    'isUser': isUser,
    'isUrgent': isUrgent,
    'medication': medication?.toJson(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final text = json['text'];
    final isUser = json['isUser'];
    final isUrgent = json['isUrgent'];
    final medication = json['medication'];
    if (text is! String ||
        isUser is! bool ||
        isUrgent is! bool ||
        (medication != null && medication is! Map<String, dynamic>)) {
      throw const FormatException('Ungültige Chatnachricht');
    }
    final medicationInfo = medication == null
        ? null
        : MedicationInfo.fromJson(medication);
    if (medicationInfo != null) return ChatMessage.medication(medicationInfo);
    if (isUser) return ChatMessage.user(text);
    if (isUrgent) return ChatMessage.urgent(text);
    return ChatMessage.assistant(text);
  }
}
