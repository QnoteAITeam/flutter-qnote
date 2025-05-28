// lib/features/chat/widgets/chat_options_area.dart
import 'package:flutter/material.dart';

class ChatOptionsArea extends StatelessWidget {
  final List<String> options;
  final bool isAiResponding;
  final Function(String) onOptionTapped;

  const ChatOptionsArea({
    Key? key,
    required this.options,
    required this.isAiResponding,
    required this.onOptionTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty || isAiResponding) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      constraints: const BoxConstraints(maxHeight: 50),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1.0)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        itemCount: options.length,
        itemBuilder: (context, index) {
          return _buildOptionButton(options[index], () => onOptionTapped(options[index]));
        },
        separatorBuilder: (context, index) => const SizedBox(width: 8),
      ),
    );
  }

  Widget _buildOptionButton(String text, VoidCallback onTap) { // 옵션 버튼은 이 위젯 내부에 두어도 무방
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFF5F0E9),
        foregroundColor: const Color(0xFF4A4A4A),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ).copyWith(
        overlayColor: MaterialStateProperty.resolveWith<Color?>((states) {
          if (states.contains(MaterialState.pressed)) return Colors.brown.withOpacity(0.1);
          return null;
        }),
      ),
      child: Text(text),
    );
  }
}
