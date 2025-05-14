import 'package:flutter_qnote/models/chat_session.dart';
import 'package:flutter_qnote/models/diary.dart';
import 'package:flutter_qnote/models/emotion_tag.dart';
import 'package:flutter_qnote/models/tag.dart';

class User {
  final String id;
  final String username;
  final String email;
  final int? age;
  final DateTime createdAt;
  final DateTime updateAt;
  final String? profileImage;
  final String role;
  final String? phoneNumber;
  final bool emailVerified;
  final int loginAttempts;
  final String provider;
  final List<ChatSession> sessions;
  final List<Diary> diaries;
  final List<EmotionTag> emotionTags;
  final List<Tag> tags;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.age,
    required this.createdAt,
    required this.updateAt,
    this.profileImage,
    required this.role,
    this.phoneNumber,
    required this.emailVerified,
    required this.loginAttempts,
    required this.provider,
    this.sessions = const [],
    this.diaries = const [],
    this.emotionTags = const [],
    this.tags = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      age: json['age'],
      createdAt: DateTime.parse(json['createdAt']),
      updateAt: DateTime.parse(json['updateAt']),
      profileImage: json['profileImage'],
      role: json['role'],
      phoneNumber: json['phoneNumber'],
      emailVerified: json['emailVerified'],
      loginAttempts: json['loginAttempts'],
      provider: json['provider'],
      sessions: ChatSession.fromJsonList(json['sessions'] ?? []),
      diaries: Diary.fromJsonList(json['diaries'] ?? []),
      emotionTags: EmotionTag.fromJsonList(json['emotionTags'] ?? []),
      tags: Tag.fromJsonList(json['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'age': age,
      'createdAt': createdAt.toIso8601String(),
      'updateAt': updateAt.toIso8601String(),
      'profileImage': profileImage,
      'role': role,
      'phoneNumber': phoneNumber,
      'emailVerified': emailVerified,
      'loginAttempts': loginAttempts,
      'provider': provider,
      'sessions': sessions.map((session) => session.toJson()).toList(),
      'diaries': diaries.map((diary) => diary.toJson()).toList(),
      'emotionTags':
          emotionTags.map((emotionTag) => emotionTag.toJson()).toList(),
      'tags': tags.map((tag) => tag.toJson()).toList(),
    };
  }
}
