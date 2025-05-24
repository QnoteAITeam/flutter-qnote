
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
    this.suggestedTags = const [],
    this.suggestedEmotionTags = const [],
    this.suggestedTitle,
  });

  final MessageRole role;
  final MessageState state;
  final String message;
  final int? askingNumericValue;
  final List<String> suggestedTags;
  final List<String> suggestedEmotionTags;
  final String? suggestedTitle;

  factory SendMessageDto.fromMessageByUser(String message) {
    return SendMessageDto(
      role: MessageRole.user,
      state: MessageState.user,
      message: message,
      askingNumericValue: null,
      suggestedTags: [],
    );
  }

  factory SendMessageDto.fromJsonByUser(Map<String, dynamic> json) {
    return SendMessageDto(
      role: MessageRole.user,
      state: MessageState.user,
      message: json['message'] as String? ?? '',
      askingNumericValue: null,
    );
  }

  factory SendMessageDto.fromJson(Map<String, dynamic> json) {
    List<String> tags = [];
    if (json['suggestedTags'] != null && json['suggestedTags'] is List) {
      tags =
      List<String>.from(json['suggestedTags'].map((tag) => tag.toString()));
    } else if (json['tags'] != null && json['tags'] is List) {
      tags = List<String>.from(json['tags'].map((tag) => tag.toString()));
    }

    List<String> emotionTags = [];
    if (json['suggestedEmotionTags'] != null &&
        json['suggestedEmotionTags'] is List) {
      emotionTags = List<String>.from(
          json['suggestedEmotionTags'].map((tag) => tag.toString()));
    } else if (json['emotionTags'] != null &&
        json['emotionTags'] is List) { // 'emotionTags' 키도 확인
      emotionTags =
      List<String>.from(json['emotionTags'].map((tag) => tag.toString()));
    }

    return SendMessageDto(
      role: json['role'] == 'assistant'
          ? MessageRole.assistance
          : (json['role'] == 'system' ? MessageRole.system : MessageRole.user),
      state: json['state'] == 'asking'
          ? MessageState.asking
          : (json['state'] == 'user' ? MessageState.user : MessageState.done),
      message: json['message'] as String? ?? '',
      askingNumericValue: json['askingNumericValue'] as int?,
      suggestedTags: tags,
      suggestedEmotionTags: emotionTags,
      suggestedTitle: json['suggestedTitle'] as String? ??
          json['title'] as String?,
    );
  }

  factory SendMessageDto.fromJsonByAssistant(Map<String, dynamic> json) {
    int? finalAskingNumericValue;
    String actualMessage = "AI 응답을 처리하는 중입니다...";
    List<String> finalSuggestedTags = [];
    List<String> finalSuggestedEmotionTags = [];
    String? finalSuggestedTitle;

    dynamic payloadToParse = json;

    if (json.containsKey('message') && json['message'] is String) {
      try {
        dynamic decodedMessageField = jsonDecode(json['message'] as String);
        if (decodedMessageField is Map<String, dynamic>) {
          payloadToParse = decodedMessageField;

          if (payloadToParse.containsKey('message') &&
              payloadToParse['message'] is String) {
            actualMessage = payloadToParse['message'] as String;
          } else if (payloadToParse.containsKey('content') &&
              payloadToParse['content'] is String) {
            actualMessage = payloadToParse['content'] as String;
          } else {
            actualMessage = json['message'] as String;
          }
        } else {
// 'message' 필드가 JSON 문자열이 아닌 단순 문자열인 경우
          actualMessage = json['message'] as String;
// payloadToParse는 그대로 jsonResponseFromServer (최상위에서 다른 필드 찾기)
        }
      } catch (e) {
// 중첩 JSON 파싱 실패 시, 'message' 필드를 단순 문자열로 간주
        actualMessage = json['message'] as String;
// payloadToParse는 그대로 jsonResponseFromServer
      }
    } else if (json.containsKey('message') && json['message'] != null) {
// 'message' 필드가 문자열이 아니지만 null도 아닌 다른 타입인 경우 (toString으로 변환)
      actualMessage = json['message'].toString();
// payloadToParse는 그대로 jsonResponseFromServer
    } else if (json.containsKey('content') && json['content'] is String) {
// 'message' 필드가 아예 없고, 최상위 레벨에 'content' 필드만 있는 경우
      actualMessage = json['content'] as String;
// payloadToParse는 그대로 jsonResponseFromServer
    }

    finalSuggestedTitle = payloadToParse['title'] as String?;

    if (payloadToParse['tags'] != null && payloadToParse['tags'] is List) {
      finalSuggestedTags =
      List<String>.from(payloadToParse['tags'].map((tag) => tag.toString()));
    }
    if (payloadToParse['emotionTags'] != null &&
        payloadToParse['emotionTags'] is List) {
      finalSuggestedEmotionTags = List<String>.from(
          payloadToParse['emotionTags'].map((tag) => tag.toString()));
    }

    finalAskingNumericValue =
    payloadToParse['asking'] as int?; // '/openai/metadata' 응답에는 asking이 없을 수 있음
    finalAskingNumericValue ??= json['askingNumericValue'] as int?;
    finalAskingNumericValue ??= json['asking'] as int?;

    MessageState determinedState;

    if (finalAskingNumericValue == 0 ||
        (payloadToParse.containsKey('title') &&
            payloadToParse.containsKey('content') &&
            payloadToParse.containsKey('tags'))) { // 구조화된 데이터가 왔다면 done으로 간주
      determinedState = MessageState.done;
      finalAskingNumericValue = 0;
    } else if (finalAskingNumericValue == 1 || finalAskingNumericValue == 2 ||
        finalAskingNumericValue == 3) {
      determinedState = MessageState.asking;
    } else {
      determinedState = MessageState.done;
    }

    return SendMessageDto(
      role: MessageRole.assistance,
      state: determinedState,
      message: actualMessage,
      askingNumericValue: finalAskingNumericValue,
      suggestedTags: finalSuggestedTags,
      suggestedEmotionTags: finalSuggestedEmotionTags,
      suggestedTitle: finalSuggestedTitle,
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
    final Map<String, dynamic> data = {
      'role': role.name,
      'state': state.name,
      'message': message,
    };

    if (askingNumericValue != null) {
      data['askingNumericValue'] = askingNumericValue;
    }
    if (suggestedTags.isNotEmpty) {
      data['suggestedTags'] = suggestedTags;
    }
    if (suggestedEmotionTags.isNotEmpty) {
      data['suggestedEmotionTags'] = suggestedEmotionTags;
    }
    if (suggestedTitle != null && suggestedTitle!.isNotEmpty) {
      data['suggestedTitle'] = suggestedTitle;
    }
    return data;
  }
}
Widget _buildMessageWidget(BuildContext context, SendMessageDto msg) {
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