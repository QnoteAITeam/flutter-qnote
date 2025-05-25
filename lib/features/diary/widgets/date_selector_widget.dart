import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateSelectorWidget extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onDateTap; // 달력 아이콘 클릭 시 콜백
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
    return Container(
      // 오른쪽 잘림 방지: minHeight와 minWidth, padding 조정
      constraints: const BoxConstraints(minHeight: 48, minWidth: 0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      decoration: BoxDecoration(
        color: fieldBackgroundColor,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
      child: Row(
        children: [
          // 텍스트 부분: 탭 이벤트 없음, overflow 방지
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14.0),
              child: Text(
                DateFormat('yyyy.MM.dd.', 'ko_KR').format(selectedDate),
                style: TextStyle(fontSize: fieldFontSize, color: Colors.black87),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.calendar_today_outlined, color: Colors.grey[600], size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: '날짜 선택',
            onPressed: onDateTap,
          ),
        ],
      ),
    );
  }
}
