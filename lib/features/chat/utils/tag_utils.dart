// lib/features/chat/utils/tag_utils.dart
class TagUtils {
  static List<String> extractTagsFromMessage(String messageContent) {
    List<String> tags = [];
    try {
      RegExp exp = RegExp(r"#([\wㄱ-ㅎㅏ-ㅣ가-힣]+)");
      tags = exp.allMatches(messageContent)
          .map((m) => m.group(1))
          .where((tag) => tag != null && tag.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();

      if (tags.isEmpty && messageContent.isNotEmpty) {
        List<String> candidates = [];
        if (messageContent.contains("행복") || messageContent.contains("즐거") || messageContent.contains("기뻤")) candidates.add("행복");
        if (messageContent.contains("감사") || messageContent.contains("고마")) candidates.add("감사");
        if (messageContent.contains("슬픔") || messageContent.contains("우울") || messageContent.contains("힘들")) candidates.add("슬픔");
        if (messageContent.contains("샐러드")) candidates.add("샐러드");
        if (messageContent.contains("아침")) candidates.add("아침식사");
        tags.addAll(candidates.toSet().take(3));
        if (tags.isEmpty) {
          tags = messageContent
              .replaceAll(RegExp(r'[^\w\sㄱ-ㅎㅏ-ㅣ가-힣]'), '')
              .split(RegExp(r'\s+'))
              .where((word) => word.length > 1 && !_isCommonWord(word))
              .take(2)
              .toList();
        }
      }
    } catch (e) {
      // print("TagUtils: Error extracting/generating tags: $e");
    }
    return tags;
  }

  static bool _isCommonWord(String word) {
    const commonWords = ['오늘', '어제', '내일', '나는', '나의', '내가', '너는', '너의', '그는', '그녀는', '우리', '그리고', '그래서', '하지만', '그러나', '이제', '정말', '매우', '아주', '너무', '조금', '많이', '항상', '가끔', '때때로', '여기', '저기', '이것', '저것', '그것', '있다', '없다', '했다', '이다', '입니다', '같아요', '했어요', '있어요', '없어요'];
    return commonWords.contains(word.toLowerCase());
  }
}
