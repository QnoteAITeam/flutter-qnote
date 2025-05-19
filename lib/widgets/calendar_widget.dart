// lib/widgets/calendar_widget.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart'; // DateFormat 사용

// DateTapDetails 클래스는 이전과 동일하게 유지
class DateTapDetails {
  final DateTime date;
  final bool hasEvent;

  DateTapDetails({
    required this.date,
    required this.hasEvent,
  });
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
  final List<String> _koreanWeekdays = ["월", "화", "수", "목", "금", "토", "일"]; // 요일 표시용

  @override
  void initState() {
    super.initState();
    _focusedDayInternal = widget.focusedDayForCalendar;
  }

  @override
  void didUpdateWidget(covariant CalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!isSameDay(widget.focusedDayForCalendar, _focusedDayInternal)) {
      _focusedDayInternal = widget.focusedDayForCalendar;
    }
  }

  bool _isEnabledDay(DateTime day) {
    DateTime normalizedToday = DateTime.utc(widget.today.year, widget.today.month, widget.today.day);
    DateTime normalizedDay = DateTime.utc(day.year, day.month, day.day);
    return !normalizedDay.isAfter(normalizedToday);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12.withAlpha((0.05 * 255).round()), blurRadius: 10, spreadRadius: 2)],
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: TableCalendar<dynamic>(
        locale: 'ko_KR',
        firstDay: DateTime.utc(2010, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDayInternal,
        calendarFormat: CalendarFormat.month,
        calendarStyle: const CalendarStyle(
          outsideDaysVisible: true, // 이전/다음 달 날짜 셀을 빌더가 처리하도록
        ),
        headerStyle: HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          titleTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
          leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.grey),
          rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.grey),
          titleTextFormatter: (date, locale) => DateFormat.yMMMM(locale).format(date),
        ),
        daysOfWeekHeight: 30, // 요일 표시 영역 높이 (선택적)
        calendarBuilders: CalendarBuilders(
          dowBuilder: (context, day) { // 요일 빌더 수정
            final text = _koreanWeekdays[day.weekday -1]; // DateTime.monday는 1
            TextStyle? style;
            if (day.weekday == DateTime.saturday) { // 토요일
              style = TextStyle(color: Colors.blue[700], fontSize: 12, fontWeight: FontWeight.w500);
            } else if (day.weekday == DateTime.sunday) { // 일요일
              style = TextStyle(color: Colors.red[600], fontSize: 12, fontWeight: FontWeight.w500);
            } else { // 평일
              style = TextStyle(color: Colors.grey[700], fontSize: 12, fontWeight: FontWeight.w500);
            }
            return Center(
              child: Text(text, style: style),
            );
          },
          todayBuilder: (context, day, focusedDay) {
            final dayUtc = DateTime.utc(day.year, day.month, day.day);
            final bool isFlameDay = widget.daysWithDiary.contains(dayUtc);
            return _buildCell(context, day, isFlameDay, true, true);
          },
          defaultBuilder: (context, day, focusedDay) {
            final bool isEnabled = _isEnabledDay(day);
            return _buildCell(context, day, false, false, isEnabled);
          },
          disabledBuilder: (context, day, focusedDay) {
            return _buildCell(context, day, false, false, false);
          },
          outsideBuilder: (context, day, focusedDay) {
            return _buildCell(context, day, false, false, false, isOutside: true);
          },
        ),
        enabledDayPredicate: _isEnabledDay,
        onDaySelected: (selectedDay, focusedDay) {
          if (!isSameDay(_focusedDayInternal, focusedDay)) {
            setState(() {
              _focusedDayInternal = focusedDay;
            });
          }
          _handleDayCellTap(selectedDay);
        },
        onPageChanged: (focusedDay) {
          setState(() {
            _focusedDayInternal = focusedDay;
          });
          widget.onPageChanged?.call(focusedDay);
        },
      ),
    );
  }

  Widget _buildCell(BuildContext context, DateTime day, bool isFlameForToday, bool isToday, bool isEnabled, {bool isOutside = false}) {
    BoxDecoration cellDecoration = BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.transparent,
    );
    Widget cellChild = const SizedBox.shrink();

    if (isOutside) {
      cellDecoration = BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.withAlpha((0.10 * 255).round()),
      );
    } else if (isEnabled) {
      if (isToday) {
        if (isFlameForToday) {
          cellChild = const Icon(Icons.local_fire_department, color: Colors.deepOrangeAccent, size: 20);
          cellDecoration = BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.orange.withAlpha((0.10 * 255).round()),
            border: Border.all(color: Colors.amber.shade600, width: 1.5),
          );
        } else {
          cellDecoration = BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.withAlpha((0.15 * 255).round()),
            border: Border.all(color: Colors.amber.shade600, width: 1.5),
          );
        }
      } else { // 과거 (오늘 아님)
        cellDecoration = BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.withAlpha((0.15 * 255).round()),
        );
      }
    } else { // 미래 날짜
      cellDecoration = BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.withAlpha((0.15 * 255).round()),
      );
    }
    return Container(
      margin: const EdgeInsets.all(5.0),
      decoration: cellDecoration,
      child: Center(child: cellChild),
    );
  }

  void _handleDayCellTap(DateTime tappedDay) {
    final bool hasEvent = widget.daysWithDiary.contains(
        DateTime.utc(tappedDay.year, tappedDay.month, tappedDay.day));
    widget.onDateTap?.call(DateTapDetails(date: tappedDay, hasEvent: hasEvent));
  }

  bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
