class Diary {
  final int? id;
  final int? userId;
  final String title;
  final String content;
  final String summary;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> tags;
  final List<String> emotionTags;

  Diary({
    this.id,
    this.userId,
    required this.title,
    required this.content,
    required this.summary,
    this.createdAt,
    this.updatedAt,
    this.tags = const [],
    this.emotionTags = const [],
  });

  factory Diary.fromJson(Map<String, dynamic> json) {
    return Diary(
      id: json['id'] as int?,
      userId: json['userId'] as int?,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      createdAt: (json['createdAt'] is String) ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: (json['updatedAt'] is String) ? DateTime.tryParse(json['updatedAt']) : null,
      tags: (json['tags'] is List)
          ? (json['tags'] as List).map((e) => e.toString()).toList()
          : (json['tags'] is String)
          ? (json['tags'] as String).split(RegExp(r'[,\s]+')).where((t) => t.isNotEmpty).toList()
          : [],
      emotionTags: (json['emotionTags'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'content': content,
      'summary': summary,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'tags': tags,
      'emotionTags': emotionTags,
    };
  }

  static List<Diary> fromJsonList(List<dynamic>? list) {
    if (list == null) return [];
    return list.map((item) => Diary.fromJson(item as Map<String, dynamic>)).toList();
  }

  Diary copyWith({
    int? id,
    int? userId,
    String? title,
    String? content,
    String? summary,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    List<String>? emotionTags,
  }) {
    return Diary(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      summary: summary ?? this.summary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      emotionTags: emotionTags ?? this.emotionTags,
    );
  }
}
