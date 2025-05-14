import 'package:flutter_qnote/models/chat_session.dart';

class ChatMessage {
  final int id;
  final String role; // 'assistant' | 'system' | 'user'
  final String text;
  final DateTime createdAt;
  final ChatSession? session;

  ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    required this.session,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      role: json['role'],
      text: json['text'],
      createdAt: DateTime.parse(json['createdAt']),
      session: ChatSession.fromJson(json['session']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'session': session?.toJson(),
    };
  }
}
