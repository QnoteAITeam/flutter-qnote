class GetScheduleByDateResponseDto {
  final int id;
  final String title;
  final String context;
  final DateTime startAt;
  final DateTime endAt;
  final String location;
  final bool isAllDay;
  final DateTime createdAt;
  final DateTime updatedAt;

  GetScheduleByDateResponseDto({
    required this.id,
    required this.title,
    required this.context,
    required this.startAt,
    required this.endAt,
    required this.location,
    required this.isAllDay,
    required this.createdAt,
    required this.updatedAt,
  });

  /// JSON → 객체
  factory GetScheduleByDateResponseDto.fromJson(Map<String, dynamic> json) {
    return GetScheduleByDateResponseDto(
      id: json['id'],
      title: json['title'],
      context: json['context'],
      startAt: DateTime.parse(json['startAt']),
      endAt: DateTime.parse(json['endAt']),
      location: json['location'],
      isAllDay: json['isAllDay'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  /// JSON 리스트 → 객체 리스트
  static List<GetScheduleByDateResponseDto> fromJsonList(
    List<dynamic> jsonList,
  ) {
    return jsonList
        .map((json) => GetScheduleByDateResponseDto.fromJson(json))
        .toList();
  }

  /// 객체 → JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'context': context,
      'startAt': startAt.toIso8601String(),
      'endAt': endAt.toIso8601String(),
      'location': location,
      'isAllDay': isAllDay,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
