import 'package:flutter_qnote/models/user.dart';

class ChatSession {
  final int? id;
  final User? user;
  final DateTime? createdAt;

  ChatSession({this.id, this.user, this.createdAt});

  factory ChatSession.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return ChatSession(id: null, user: null, createdAt: null);
    }

    User? parsedUser;
    if (json['user'] is Map<String, dynamic>) {
      try {
        parsedUser = User.fromJson(json['user'] as Map<String, dynamic>);
      } catch (e) {
      }
    }

    DateTime? parsedCreatedAt;
    if (json['createdAt'] is String) {
      parsedCreatedAt = DateTime.tryParse(json['createdAt']);
    }

    return ChatSession(
      id: json['id'] as int?,
      user: parsedUser,
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user?.toJson(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  static List<ChatSession> fromJsonList(List<dynamic>? list) {
    if (list == null || list.isEmpty) {
      return [];
    }

    final List<ChatSession> sessions = [];
    for (final item in list) {
      if (item is Map<String, dynamic>) {
        try {
          sessions.add(ChatSession.fromJson(item));
        } catch (e) {
        }
      }
    }
    return sessions;
  }
}
