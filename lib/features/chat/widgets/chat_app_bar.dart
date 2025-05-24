// lib/features/chat/widgets/chat_app_bar.dart
import 'package:flutter/material.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onInfoPressed;

  const ChatAppBar({Key? key, required this.onInfoPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.only(left: 12.0),
        child: Row(
          children: [
            const CircleAvatar( // 이미지 경로 직접 사용 또는 상수로 관리
              radius: 18,
              backgroundImage: AssetImage('assets/images/ai_avatar.png'),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('큐노트 AI', style: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.bold)),
                Text('오늘 하루를 요약해 보세요!', style: TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.info_outline, color: Colors.grey.shade600, size: 24),
          tooltip: 'AI 챗봇 정보',
          onPressed: onInfoPressed,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
