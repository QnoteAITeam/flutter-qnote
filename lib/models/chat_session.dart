import 'package:flutter_qnote/models/user.dart';

class ChatSession {
  final int id;
  final User user;
  final DateTime createdAt;

  ChatSession({required this.id, required this.user, required this.createdAt});

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'],
      user: User.fromJson(json['user']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
