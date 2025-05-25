// lib/features/dashboard/widgets/diary_summary_section_widget.dart
import 'package:flutter/material.dart';
// import 'package:flutter_qnote/widgets/calendar_widget.dart'; // 이전 경로
import 'calendar_widget.dart'; // 변경된 경로 (동일 디렉토리 내)
import 'package:flutter_qnote/models/diary.dart'; // DiaryDetailScreen 호출에 필요

// DiaryDetailScreen placeholder (실제 파일은 features/diary/에 있다고 가정)
import 'package:flutter_qnote/features/diary/diary_detail_screen.dart';

class DiarySummarySectionWidget extends StatelessWidget {
  final GlobalKey? calendarWidgetKey;
  final DateTime focusedDayForCalendar;
  final DateTime today;
  final Set<DateTime> daysWithDiary;
  final int weeklyFlameCount;
  final String? todayDiarySummary;
  final bool cachedDiariesEmpty;
  final OnDateTapWithDetails onDateTap; // CalendarWidget의 DateTapDetails 사용
  final ValueChanged<DateTime> onCalendarPageChanged;

  const DiarySummarySectionWidget({
    Key? key,
    this.calendarWidgetKey,
    required this.focusedDayForCalendar,
    required this.today,
    required this.daysWithDiary,
    required this.weeklyFlameCount,
    this.todayDiarySummary,
    required this.cachedDiariesEmpty,
    required this.onDateTap,
    required this.onCalendarPageChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String weeklyStatusText;
    if (cachedDiariesEmpty) {
      weeklyStatusText = '이번 주에 아직 작성된 일기가 없어요.';
    } else {
      weeklyStatusText = weeklyFlameCount > 0
          ? '이번 주에 총 $weeklyFlameCount개의 일기를 작성했어요! 🔥'
          : '이번 주에 아직 작성된 일기가 없네요.';
    }

    String todaySummaryText;
    if (todayDiarySummary == null && !cachedDiariesEmpty) {
      todaySummaryText = '오늘 작성된 일기가 없어요. 새로운 일기를 작성해보세요!';
    } else if (todayDiarySummary == null && cachedDiariesEmpty) {
      todaySummaryText = '오늘 작성된 일기가 없어요. 오늘의 일기를 작성해주세요!';
    } else if (todayDiarySummary != null){
      todaySummaryText = todayDiarySummary!;
    } else {
      // 이 경우는 발생하지 않아야 하지만, 방어적으로 처리
      todaySummaryText = '요약 정보를 불러올 수 없습니다.';
    }

    print('[DEBUG] DiarySummarySectionWidget daysWithDiary: $daysWithDiary');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 0, bottom: 16),
          child: Text(weeklyStatusText,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
        ),
        Container(
          key: calendarWidgetKey,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.withAlpha(80),
                    blurRadius: 10,
                    offset: const Offset(0, 1))
              ]),
          padding: const EdgeInsets.only(bottom: 8),
          child: CalendarWidget( // 변경된 경로로 CalendarWidget 사용
            focusedDayForCalendar: focusedDayForCalendar,
            today: today,
            daysWithDiary: daysWithDiary,
            onDateTap: onDateTap,
            onPageChanged: onCalendarPageChanged,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.withAlpha(80),
                    spreadRadius: 0.5,
                    blurRadius: 10,
                    offset: const Offset(0, 1))
              ]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('오늘의 일기 요약',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87)),
              const SizedBox(height: 12),
              Text(todaySummaryText,
                  style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: todayDiarySummary != null && todayDiarySummary!.isNotEmpty
                          ? Colors.black54
                          : Colors.grey), // 요약이 없거나 비어있으면 회색
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis)
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
