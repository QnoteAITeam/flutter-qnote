// lib/features/chat/widgets/chat_input_area.dart
import 'package:flutter/material.dart';

class ChatInputArea extends StatelessWidget {
  final TextEditingController textController;
  final VoidCallback onSendPressed;
  final VoidCallback onAttachPressed;

  const ChatInputArea({
    Key? key,
    required this.textController,
    required this.onSendPressed,
    required this.onAttachPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(offset: const Offset(0, -1), blurRadius: 4, color: Colors.grey.withAlpha(12))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.add_circle_outline, color: Colors.grey[600], size: 28),
              onPressed: onAttachPressed,
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(25.0)),
                child: TextField(
                  controller: textController,
                  decoration: InputDecoration(
                    hintText: '자유롭게 답변하기',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
                  ),
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSendPressed(), // 엔터키로 전송
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send_rounded, color: const Color(0xFFB59A7B), size: 28),
              onPressed: onSendPressed,
            ),
          ],
        ),
      ),
    );
  }
}
