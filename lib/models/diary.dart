import 'package:flutter_qnote/models/emotion_tag.dart';
import 'package:flutter_qnote/models/tag.dart';

class Diary {
  final int id;
  final String title;
  final String content;
  final String summary;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Tag> tags;
  final List<EmotionTag> emotionTags;

  Diary({
    required this.id,
    required this.title,
    required this.content,
    required this.summary,
    required this.createdAt,
    required this.updatedAt,
    required this.tags,
    required this.emotionTags,
  });

  factory Diary.fromJson(Map<String, dynamic> json) {
    return Diary(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      summary: json['summary'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      tags: Tag.fromJsonList(json['tags']),
      emotionTags: EmotionTag.fromJsonList(json['emotionTags']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'summary': summary,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'tags': tags.map((tag) => tag.toJson()).toList(),
      'emotionTags':
          emotionTags.map((emotionTag) => emotionTag.toJson()).toList(),
    };
  }

  static List<Diary> fromJsonList(List<Map<String, dynamic>> list) {
    return list.map((diary) => Diary.fromJson(diary)).toList();
  }
}
