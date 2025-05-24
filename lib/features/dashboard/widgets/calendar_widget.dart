// lib/widgets/calendar_widget.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart'; // DateFormat 사용

// DateTapDetails 클래스는 변경 없음
class DateTapDetails {
  final DateTime date;
  final bool hasEvent;
  DateTapDetails({required this.date, required this.hasEvent});
}

typedef OnDateTapWithDetails = void Function(DateTapDetails details);

class CalendarWidget extends StatefulWidget {
  final DateTime focusedDayForCalendar;
  final DateTime today;
  final Set<DateTime> daysWithDiary;
  final OnDateTapWithDetails? onDateTap;
  final ValueChanged<DateTime>? onPageChanged;

  const CalendarWidget({
    Key? key,
    required this.focusedDayForCalendar,
    required this.today,
    this.daysWithDiary = const {},
    this.onDateTap,
    this.onPageChanged,
  }) : super(key: key);

  @override
  _CalendarWidgetState createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late DateTime _focusedDayInternal;
  final List<String> _koreanWeekdays = ["월", "화", "수", "목", "금", "토", "일"];

  @override
  void initState() {
    super.initState();
    _focusedDayInternal = DateTime(widget.focusedDayForCalendar.year, widget.focusedDayForCalendar.month, widget.focusedDayForCalendar.day);
  }

  @override
  void didUpdateWidget(covariant CalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newFocusedDayLocal = DateTime(widget.focusedDayForCalendar.year, widget.focusedDayForCalendar.month, widget.focusedDayForCalendar.day);
    if (!isSameDay(newFocusedDayLocal, _focusedDayInternal)) {
      _focusedDayInternal = newFocusedDayLocal;
    }
  }

  bool _isEnabledDay(DateTime day) {
    final normalizedToday = DateTime(widget.today.year, widget.today.month, widget.today.day);
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return !normalizedDay.isAfter(normalizedToday);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: TableCalendar<dynamic>(
        locale: 'ko_KR',
        firstDay: DateTime(2010, 1, 1),
        lastDay: DateTime(2030, 12, 31),
        focusedDay: _focusedDayInternal,
        calendarFormat: CalendarFormat.month,
        headerStyle: HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          titleTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
          leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.grey),
          rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.grey),
          titleTextFormatter: (date, locale) => DateFormat.yMMMM(locale).format(date),
        ),
        daysOfWeekHeight: 30,
        calendarBuilders: CalendarBuilders(
          dowBuilder: (context, day) {
            final text = _koreanWeekdays[day.weekday - 1];
            final Color textColor;
            if (day.weekday == DateTime.saturday) {
              textColor = Colors.blue[700]!;
            } else if (day.weekday == DateTime.sunday) {
              textColor = Colors.red[600]!;
            } else {
              textColor = Colors.black87;
            }
            return Center(
              child: Text(text, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500)),
            );
          },
          defaultBuilder: (context, day, focusedDay) {
            final dayLocal = DateTime(day.year, day.month, day.day);
            final todayLocal = DateTime(widget.today.year, widget.today.month, widget.today.day);
            final isToday = isSameDay(dayLocal, todayLocal);
            final hasEvent = widget.daysWithDiary.contains(dayLocal);
            final isEnabled = _isEnabledDay(day);
            return _buildCustomCell(context, day, hasEvent, isToday, isEnabled, false);
          },
          todayBuilder: (context, day, focusedDay) {
            final dayLocal = DateTime(day.year, day.month, day.day);
            final hasEvent = widget.daysWithDiary.contains(dayLocal);
            return _buildCustomCell(context, day, hasEvent, true, true, false);
          },
          disabledBuilder: (context, day, focusedDay) {
            return _buildCustomCell(context, day, false, false, false, false);
          },
          outsideBuilder: (context, day, focusedDay) {
            return _buildCustomCell(context, day, false, false, false, true);
          },
        ),
        enabledDayPredicate: _isEnabledDay,
        onDaySelected: (selectedDay, focusedDay) {
          final focusedDayLocal = DateTime(focusedDay.year, focusedDay.month, focusedDay.day);
          if (!isSameDay(_focusedDayInternal, focusedDayLocal)) {
            setState(() { _focusedDayInternal = focusedDayLocal; });
          }
          _handleDayCellTap(DateTime(selectedDay.year, selectedDay.month, selectedDay.day));
        },
        onPageChanged: (focusedDay) {
          final focusedDayLocal = DateTime(focusedDay.year, focusedDay.month, focusedDay.day);
          setState(() { _focusedDayInternal = focusedDayLocal; });
          widget.onPageChanged?.call(focusedDayLocal);
        },
      ),
    );
  }

  // image.png UI를 따르는 커스텀 셀 빌더 (문제 1-1 테두리 추가)
  Widget _buildCustomCell(BuildContext context, DateTime day, bool hasEvent, bool isToday, bool isEnabled, bool isOutside) {
    Color circleColor;
    Border? circleBorder;
    Widget? iconContent;

    if (isOutside) { // 현재 달력이 아닌 날짜
      circleColor = Colors.grey.shade200.withOpacity(0.5);
    } else if (!isEnabled) { // 미래 날짜 (비활성화)
      circleColor = Colors.grey.shade200.withOpacity(0.7);
    } else { // 활성화된 날짜 (과거 또는 오늘)
      if (hasEvent) {
        // 일기가 있으면 배경을 노란색 계열로 변경
        circleColor = Colors.yellow.shade100; // 예: 연한 노란색
        iconContent = Icon(
          Icons.local_fire_department,
          color: Colors.deepOrangeAccent,
          size: 20,
        );
        // 오늘이 아닌데 일기가 있는 경우, 테두리 추가 (요청 사항 1-1)
        if (!isToday) {
          circleBorder = Border.all(color: Colors.orangeAccent.withOpacity(0.7), width: 1.5); // 예: 연한 주황색 테두리
        }
      } else {
        // 일기가 없으면 기본 회색 동그라미
        circleColor = Colors.grey.shade300;
      }

      if (isToday) {
        // 오늘 날짜는 항상 더 굵고 명확한 테두리로 강조 (기존 테두리 덮어씀)
        circleBorder = Border.all(color: Colors.orange.shade700, width: 2);
        // 오늘이면서 일기가 없을 때의 배경색은 hasEvent 조건에서 이미 처리됨 (회색)
        // 만약 오늘+일기없음 일때도 노란 배경을 원한다면, 이 if 블록 안에서 circleColor를 다시 설정
        // 예: if (isToday && !hasEvent) circleColor = Colors.yellow.shade50;
      }
    }

    return GestureDetector(
      onTap: () => isEnabled && !isOutside ? _handleDayCellTap(DateTime(day.year, day.month, day.day)) : null,
      child: Container(
        margin: const EdgeInsets.all(5.0),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: circleColor,
          border: circleBorder, // 설정된 테두리 적용
        ),
        child: Center(child: iconContent),
      ),
    );
  }

  void _handleDayCellTap(DateTime tappedDayLocal) {
    final bool hasEvent = widget.daysWithDiary.contains(tappedDayLocal);
    widget.onDateTap?.call(DateTapDetails(date: tappedDayLocal, hasEvent: hasEvent));
  }

  bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
