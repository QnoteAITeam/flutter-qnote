class ChatMessage {
  final int id;
  final String role; // 'assistant' | 'system' | 'user'
  final String text;
  final DateTime createdAt;
  final int sessionId;

  ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    required this.sessionId,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      role: json['role'],
      text: json['text'],
      createdAt: DateTime.parse(json['createdAt']),
      sessionId: json['session']['id'], // session 객체 안의 id만 추출
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'session': {'id': sessionId},
    };
  }
}
