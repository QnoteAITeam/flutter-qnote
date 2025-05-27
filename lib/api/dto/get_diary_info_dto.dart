class FetchDiaryResponseDto {
  final int id;
  final String title;
  final String content;
  final List<String> tags;
  final List<String> emotionTags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String summary;

  FetchDiaryResponseDto({
    required this.id,
    required this.title,
    required this.content,
    required this.tags,
    required this.emotionTags,
    required this.createdAt,
    required this.updatedAt,
    required this.summary,
  });

  factory FetchDiaryResponseDto.fromJson(Map<String, dynamic> json) {
    return FetchDiaryResponseDto(
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      tags: (json['tags'] is List)
          ? List<String>.from(json['tags'])
          : (json['tags'] is String)
          ? (json['tags'] as String).split(RegExp(r'[,\s]+')).where((t) => t.isNotEmpty).toList()
          : [],
      emotionTags: List<String>.from(json['emotionTags'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      summary: json['summary'] as String,
    );
  }

  static List<FetchDiaryResponseDto> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map(
          (json) =>
              FetchDiaryResponseDto.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'tags': tags,
      'emotionTags': emotionTags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'summary': summary,
    };
  }
}
