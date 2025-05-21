//이 메세지는 누가 작성하였나.. system은 우리 서버측, assistance는.. AI, user는 유저
import 'dart:convert';

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
    this.askingNumericValue,
  });

  final MessageRole role;
  final MessageState state;
  final String message;
  final int? askingNumericValue;

  factory SendMessageDto.fromMessageByUser(String message) {
    return SendMessageDto(
      role: MessageRole.user,

      state: MessageState.user,
      message: message,
      askingNumericValue: null,
    );
  }

  factory SendMessageDto.fromJsonByUser(Map<String, dynamic> json) {
    return SendMessageDto(
      role: MessageRole.user,

      state: MessageState.user,
      message: json['message'],
      askingNumericValue: null,
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
      askingNumericValue: json['askingNumericValue'] as int?,
    );
  }

  factory SendMessageDto.fromJsonByAssistant(Map<String, dynamic> json) {
    int? originalAskingValue;
    String actualMessage;

    // 'message' 필드가 중첩된 JSON 문자열인지 확인
    if (json['message'] is String) {
      try {
        Map<String, dynamic> nestedJson = jsonDecode(json['message']);
        actualMessage = nestedJson['message'] as String? ?? '';
        originalAskingValue = nestedJson['asking'] as int?;
        print("fromJsonByAssistant - Nested asking value: $originalAskingValue");
      } catch (e) {
        actualMessage = json['message'];
      }
    } else {
      actualMessage = json['message']?.toString() ?? json.toString();
    }

    MessageState determinedState;
    // 서버 응답의 'asking' 값에 따라 MessageState 결정
    if (originalAskingValue == 1 || originalAskingValue == 2 || originalAskingValue == 3) { // 1, 2, 3 일때는 질문 중
      determinedState = MessageState.asking;
    } else if (originalAskingValue == 0) {
      determinedState = MessageState.done;
    } else {
      determinedState = MessageState.done;
    }

    return SendMessageDto(
      role: MessageRole.assistance,
      state: determinedState,
      message: actualMessage,
      askingNumericValue: originalAskingValue,
    );
  }

  factory SendMessageDto.dummy() {
    return SendMessageDto(
      state: MessageState.asking,
      message: '서버에서 응답이 없어서 그래, 이건 더미 값이야 뭐 오늘 하루 어땟는데?',
      role: MessageRole.assistance,
      askingNumericValue: 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {'role': role.name, 'state': state.name, 'message': message, 'askingNumericValue': askingNumericValue,};
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
