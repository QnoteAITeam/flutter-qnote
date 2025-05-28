class EmotionTag {
  final int? id;
  final String name;

  EmotionTag({required this.id, required this.name});

  factory EmotionTag.fromJson(Map<String, dynamic> json) {
    return EmotionTag(id: json['id'], name: json['name']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }

  static List<EmotionTag> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => EmotionTag.fromJson(json)).toList();
  }
}
