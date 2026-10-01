class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final bool isSystem;
  final bool isCorrectGuess;
  final bool isCloseGuess;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.isSystem = false,
    this.isCorrectGuess = false,
    this.isCloseGuess = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: json['playerId']?.toString() ?? '',
      senderName: json['playerName']?.toString() ?? 'System',
      text: json['text']?.toString() ?? '',
      isSystem: json['isSystem'] as bool? ?? false,
      isCorrectGuess: json['isCorrectGuess'] as bool? ?? false,
      isCloseGuess: json['isCloseGuess'] as bool? ?? false,
    );
  }
}
