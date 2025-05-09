import 'package:flutter_qnote/api/send_message_request.dart';

class GetMessagesDto {
  GetMessagesDto({required this.messages});

  final List<SendMessageRequestDto> messages;

  factory GetMessagesDto.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawList = json['messages'];
    return GetMessagesDto(
      messages:
          rawList.map((item) => SendMessageRequestDto.fromJson(item)).toList(),
    );
  }

  factory GetMessagesDto.dummy() {
    const int length = 10;

    const List<SendMessageRequestDto> list = [];
    for (int i = 0; i < length; i++) list.add(SendMessageRequestDto.dummy());
    return GetMessagesDto(messages: list);
  }

  Map<String, dynamic> toJson() {
    return {'messages': messages.map((m) => m.toJson()).toList()};
  }
}
