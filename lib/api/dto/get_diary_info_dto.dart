class GetDiaryInfoDto {
  final String title;
  final String content;
  final List<String> tags;
  final List<String> emotionTags;

  GetDiaryInfoDto({
    required this.title,
    required this.content,
    required this.tags,
    required this.emotionTags,
  });

  factory GetDiaryInfoDto.fromJson(Map<String, dynamic> json) {
    return GetDiaryInfoDto(
      title: json['title'] as String,
      content: json['content'] as String,
      tags: List<String>.from(json['tags'] ?? []),
      emotionTags: List<String>.from(json['emotionTags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'tags': tags,
      'emotionTags': emotionTags,
    };
  }
}
