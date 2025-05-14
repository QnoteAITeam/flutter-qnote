import 'package:flutter_qnote/api/dto/send_message_dto.dart';

class GetMessagesDto {
  GetMessagesDto({required this.messages});

  final List<SendMessageDto> messages;

  factory GetMessagesDto.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawList = json['messages'];
    return GetMessagesDto(
      messages: rawList.map((item) => SendMessageDto.fromJson(item)).toList(),
    );
  }

  factory GetMessagesDto.dummy() {
    const int length = 10;

    const List<SendMessageDto> list = [];
    for (int i = 0; i < length; i++) list.add(SendMessageDto.dummy());
    return GetMessagesDto(messages: list);
  }

  Map<String, dynamic> toJson() {
    return {'messages': messages.map((m) => m.toJson()).toList()};
  }
}
