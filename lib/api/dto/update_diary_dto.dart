class UpdateDiaryDto {
  String? title;
  String? content;
  List<String> tags;
  List<String> emotionTags;

  UpdateDiaryDto(this.title, this.content, this.tags, this.emotionTags);

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'tags': tags,
      'emotionTags': emotionTags,
    };
  }
}
