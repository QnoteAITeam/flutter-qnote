// lib/features/dashboard/widgets/greeting_card_widget.dart
import 'package:flutter/material.dart';

class GreetingCardWidget extends StatelessWidget {
  final bool isUserAuthenticated;
  final String userName; // "님"이 포함된 사용자 이름
  final bool hasWrittenTodayDiary; // 오늘 일기 작성 여부
  final VoidCallback onLoginPressed;
  final VoidCallback onWriteNewDiaryPressed; // "새 일기 작성" 또는 "일기 다시쓰기" 시 호출될 콜백 (ChatScreen으로 이동)
  // onEditTodayDiaryPressed 파라미터는 제거됨

  const GreetingCardWidget({
    Key? key,
    required this.isUserAuthenticated,
    required this.userName, // DashboardScreen에서 "님"을 포함하여 전달
    required this.hasWrittenTodayDiary,
    required this.onLoginPressed,
    required this.onWriteNewDiaryPressed, // 이 콜백이 "일기 다시쓰기"에도 사용됨
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String title;
    String subtitle;
    Widget? actionButton;
    Color cardColor = Colors.white;
    IconData? leadingIcon;
    Color iconColor = Colors.grey.shade700;

    if (!isUserAuthenticated) {
      // 1. 비로그인 상태
      title = 'Qnote에 오신 것을 환영합니다!';
      subtitle = '로그인하고 나만의 AI 비서와 함께 하루를 기록해보세요.';
      leadingIcon = Icons.login_outlined;
      iconColor = Theme.of(context).colorScheme.primary;
      actionButton = ElevatedButton.icon(
        icon: const Icon(Icons.login, size: 18),
        label: const Text('로그인 하기'),
        onPressed: onLoginPressed,
        style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      );
    } else if (hasWrittenTodayDiary) {
      // 2. 로그인 상태 & 오늘 일기 이미 작성됨
      title = '$userName, 오늘은 일기를 작성하셨군요! 👍'; // userName에 "님" 포함
      subtitle = '오늘 하루 있었던 일을 Qnote AI를 통해 작성해주셔서 고마워요!';
      cardColor = Colors.teal.shade50; // 구분되는 배경색 (예시)
      leadingIcon = Icons.check_circle_outline_rounded; // 아이콘 변경 (예시)
      iconColor = Colors.teal.shade700;
      actionButton = ElevatedButton.icon(
        icon: const Icon(Icons.history_edu_outlined, size: 18), // "다시쓰기"에 어울리는 아이콘 (예시)
        label: const Text('일기 다시쓰기'), // 버튼 텍스트 변경
        onPressed: onWriteNewDiaryPressed, // ChatScreen으로 이동하는 콜백 연결
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange.shade600, // 버튼 색상 변경 (예시)
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      );
    } else {
      // 3. 로그인 상태 & 오늘 일기 아직 작성 안 됨
      // (이전에 "첫 일기 작성 유도" 로직이 있었다면,
      //  DashboardScreen에서 _hasWrittenTodayDiary 외에 추가적인 상태(예: 전체 일기 개수)를
      //  판단하여 이 위젯에 다른 title/subtitle을 전달하거나,
      //  이 위젯에 cachedDiariesEmpty와 같은 파라미터를 유지하여 여기서 분기할 수 있음.
      //  현재는 "오늘 일기 작성 안 함"으로 단순화된 상태)
      title = '$userName, 오늘은 어떤 하루였나요? 😊'; // userName에 "님" 포함
      subtitle = '오늘 하루 있었던 일들을 Qnote AI에게 편하게 이야기해주세요.';
      leadingIcon = Icons.auto_awesome_outlined;
      iconColor = Colors.amber.shade800;
      actionButton = ElevatedButton.icon(
        icon: const Icon(Icons.add_circle_outline, size: 18), // 또는 Icons.chat_bubble_outline
        label: const Text('새 일기 작성'),
        onPressed: onWriteNewDiaryPressed, // ChatScreen으로 이동하는 콜백 연결
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leadingIcon != null) ...[
                Icon(leadingIcon, color: iconColor, size: 28),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.only(left: leadingIcon != null ? 40.0 : 0),
            child: Text(subtitle,
                style: TextStyle(
                    fontSize: 14, color: Colors.grey.shade600, height: 1.4)),
          ),
          if (actionButton != null) ...[
            const SizedBox(height: 16),
            Align(alignment: Alignment.centerRight, child: actionButton),
          ],
        ],
      ),
    );
  }
}
