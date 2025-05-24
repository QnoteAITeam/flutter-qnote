// lib/features/diary/widgets/date_selector_widget.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateSelectorWidget extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onDateTap; // 아이콘 클릭 시 호출될 콜백
  final Color fieldBackgroundColor;
  final double fieldFontSize;

  const DateSelectorWidget({
    Key? key,
    required this.selectedDate,
    required this.onDateTap,
    required this.fieldBackgroundColor,
    required this.fieldFontSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container( // 외부 컨테이너는 UI 스타일링을 위해 유지
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      decoration: BoxDecoration(
        color: fieldBackgroundColor,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 텍스트 부분: 탭 이벤트 없음
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14.0),
              child: Text(
                DateFormat('yyyy.MM.dd. EEEE', 'ko_KR').format(selectedDate),
                style: TextStyle(fontSize: fieldFontSize, color: Colors.black87),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 아이콘 버튼 부분: 여기에만 탭 이벤트 연결
          IconButton(
            icon: Icon(Icons.calendar_today_outlined, color: Colors.grey[600], size: 22),
            padding: EdgeInsets.zero, // 아이콘 버튼의 기본 패딩 제거
            constraints: const BoxConstraints(), // 아이콘 버튼의 최소 크기 제약 제거
            tooltip: '날짜 선택',
            onPressed: onDateTap, // 아이콘 버튼 클릭 시에만 onDateTap 콜백 실행
          ),
        ],
      ),
    );
  }
}
