// lib/features/chat/widgets/chat_message_bubble.dart
import 'package:flutter/material.dart';
import 'package:flutter_qnote/api/dto/send_message_dto.dart';

class ChatMessageBubble extends StatelessWidget {
  final SendMessageDto messageDto;
  final Widget smallAiAvatar; // AI 아바타 위젯 전달받음

  const ChatMessageBubble({
    Key? key,
    required this.messageDto,
    required this.smallAiAvatar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isUserMessage = messageDto.role == MessageRole.user;
    final bool isAssistanceMessage = messageDto.role == MessageRole.assistance;
    final bool isSystemMessage = messageDto.role == MessageRole.system;

    return Align(
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAssistanceMessage) ...[smallAiAvatar, const SizedBox(width: 8)],
          Flexible(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUserMessage
                    ? const Color(0xFFB59A7B)
                    : (isAssistanceMessage
                    ? Colors.grey[200]
                    : (isSystemMessage
                    ? Colors.amber.shade100
                    : Colors.grey[200])),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isUserMessage ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: isUserMessage ? const Radius.circular(4) : const Radius.circular(16),
                ),
              ),
              child: Text(
                messageDto.message,
                style: TextStyle(
                  color: isUserMessage
                      ? Colors.white
                      : (isAssistanceMessage
                      ? Colors.black87
                      : (isSystemMessage
                      ? Colors.orange.shade800
                      : Colors.black87)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
