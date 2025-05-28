class GetDiaryMetadataDto {
  final String title;
  final String content;
  final List<String> tags;
  final List<String> emotionTags;

  GetDiaryMetadataDto({
    required this.title,
    required this.content,
    required this.tags,
    required this.emotionTags,
  });

  // JSON -> DiaryEntry
  factory GetDiaryMetadataDto.fromJson(Map<String, dynamic> json) {
    return GetDiaryMetadataDto(
      title: json['title'] as String,
      content: json['content'] as String,
      tags: List<String>.from(json['tags'] ?? []),
      emotionTags: List<String>.from(json['emotionTags'] ?? []),
    );
  }

  // DiaryEntry -> JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'tags': tags,
      'emotionTags': emotionTags,
    };
  }
}
