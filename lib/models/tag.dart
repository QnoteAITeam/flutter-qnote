class Tag {
  final String name;
  final String? id;

  Tag({required this.id, required this.name});

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(id: json['id'], name: json['name']);
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'id': id};
  }

  static List<Tag> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => Tag.fromJson(json)).toList();
  }
}
