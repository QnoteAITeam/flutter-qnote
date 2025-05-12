//이 메세지는 누가 작성하였나.. system은 우리 서버측, assistance는.. AI, user는 유저
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum MessageRole { system, assistance, user }

//Ai의 상태, asking : 묻고 있음, done 이제 끝났고, text에는 일기의 내용
enum MessageState { asking, done, user }

class SendMessageDto {
  SendMessageDto({
    required this.role,
    required this.state,
    required this.message,
  });

  final MessageRole role;
  final MessageState state;
  final String message;

  factory SendMessageDto.fromMessageByUser(String message) {
    return SendMessageDto(
      role: MessageRole.user,

      state: MessageState.user,
      message: message,
    );
  }

  factory SendMessageDto.fromJsonByUser(Map<String, dynamic> json) {
    return SendMessageDto(
      role: MessageRole.user,

      state: MessageState.user,
      message: json['message'],
    );
  }

  factory SendMessageDto.fromJson(Map<String, dynamic> json) {
    return SendMessageDto(
      role:
          json['role'] == 'assistant'
              ? MessageRole.assistance
              : MessageRole.user,
      state:
          json['state'] == 'asking' ? MessageState.asking : MessageState.done,
      message: json['message'],
    );
  }

  factory SendMessageDto.fromJsonByAssistant(Map<String, dynamic> json) {
    return SendMessageDto(
      role: MessageRole.assistance,
      state: json['asking'] == 1 ? MessageState.asking : MessageState.done,
      message: json['message'],
    );
  }

  factory SendMessageDto.dummy() {
    return SendMessageDto(
      state: MessageState.asking,
      message: '서버에서 응답이 없어서 그래, 이건 더미 값이야 뭐 오늘 하루 어땟는데?',
      role: MessageRole.assistance,
    );
  }

  Map<String, dynamic> toJson() {
    return {'role': role.name, 'state': state.name, 'message': message};
  }

  static Widget _buildMessageWidget(BuildContext context, SendMessageDto msg) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Align(
        alignment:
            msg.role == MessageRole.user
                ? Alignment.topRight
                : Alignment.topLeft,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                msg.role == MessageRole.user
                    ? Colors.blue[100]
                    : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(msg.message),
        ),
      ),
    );
  }
}
