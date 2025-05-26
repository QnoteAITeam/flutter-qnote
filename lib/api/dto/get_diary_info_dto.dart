class FetchDiaryResponseDto {
  final String title;
  final String content;
  final List<String> tags;
  final List<String> emotionTags;

  FetchDiaryResponseDto({
    required this.title,
    required this.content,
    required this.tags,
    required this.emotionTags,
  });

  factory FetchDiaryResponseDto.fromJson(Map<String, dynamic> json) {
    return FetchDiaryResponseDto(
      title: json['title'] as String,
      content: json['content'] as String,
      tags: List<String>.from(json['tags'] ?? []),
      emotionTags: List<String>.from(json['emotionTags'] ?? []),
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
      'title': title,
      'content': content,
      'tags': tags,
      'emotionTags': emotionTags,
    };
  }
}
