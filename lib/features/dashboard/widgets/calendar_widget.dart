import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

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
  final List<String> _koreanWeekdays = ["일", "월", "화", "수", "목", "금", "토"];

  // 날짜를 UTC+9로 변환한 뒤, 반드시 시간 0시로 맞춰주는 함수
  DateTime _toKstZero(DateTime date) {
    final plus9 = date.add(const Duration(hours: 9));
    return DateTime(plus9.year, plus9.month, plus9.day); // KST 0시
  }

  @override
  void initState() {
    super.initState();
    _focusedDayInternal = _toKstZero(
      DateTime(
        widget.focusedDayForCalendar.year,
        widget.focusedDayForCalendar.month,
        widget.focusedDayForCalendar.day,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant CalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newFocusedDay = _toKstZero(
      DateTime(
        widget.focusedDayForCalendar.year,
        widget.focusedDayForCalendar.month,
        widget.focusedDayForCalendar.day,
      ),
    );
    if (!isSameDay(newFocusedDay, _focusedDayInternal)) {
      _focusedDayInternal = newFocusedDay;
    }
  }

  bool _isEnabledDay(DateTime day) {
    return true;
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
        startingDayOfWeek: StartingDayOfWeek.sunday,
        currentDay: _toKstZero(DateTime.now()),

        headerStyle: HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          titleTextStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black87,
          ),
          leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.grey),
          rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.grey),
          titleTextFormatter:
              (date, locale) => DateFormat.yMMMM(locale).format(date),
        ),
        daysOfWeekHeight: 30,
        calendarBuilders: CalendarBuilders(
          dowBuilder: (context, day) {
            final weekdayIndex = (day.weekday % 7);
            final text = _koreanWeekdays[weekdayIndex];
            final Color textColor;
            if (day.weekday == DateTime.saturday) {
              textColor = Colors.blue[700]!;
            } else if (day.weekday == DateTime.sunday) {
              textColor = Colors.red[600]!;
            } else {
              textColor = Colors.black87;
            }
            return Center(
              child: Text(
                text,
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },
          defaultBuilder: (context, day, focusedDay) {
            final dayKstZero = _toKstZero(
              DateTime(day.year, day.month, day.day),
            );
            final todayKstZero = _toKstZero(
              DateTime(widget.today.year, widget.today.month, widget.today.day),
            );
            final isToday = isSameDay(_toKstZero(day), _toKstZero(DateTime.now()));
            final hasEvent = widget.daysWithDiary.contains(dayKstZero);
            final isEnabled = _isEnabledDay(day);

            return _buildCustomCell(context, day, hasEvent, isToday, isEnabled, false);

          },
          todayBuilder: (context, day, focusedDay) {
            final dayKstZero = _toKstZero(
              DateTime(day.year, day.month, day.day),
            );
            final hasEvent = widget.daysWithDiary.contains(dayKstZero);
            return _buildCustomCell(context, day, hasEvent, true, true, false);
          },
          disabledBuilder: (context, day, focusedDay) {
            return _buildCustomCell(context, day, false, false, false, false);
          },
          outsideBuilder: (context, day, focusedDay) {
            return _buildCustomCell(context, day, false, false, false, true);
          },
        ),
        enabledDayPredicate: (_) => true,
        onDaySelected: (selectedDay, focusedDay) {
          final focusedDayKstZero = _toKstZero(
            DateTime(focusedDay.year, focusedDay.month, focusedDay.day),
          );
          if (!isSameDay(_focusedDayInternal, focusedDayKstZero)) {
            setState(() {
              _focusedDayInternal = focusedDayKstZero;
            });
          }
          _handleDayCellTap(
            _toKstZero(
              DateTime(selectedDay.year, selectedDay.month, selectedDay.day),
            ),
          );
        },
        onPageChanged: (focusedDay) {
          final focusedDayKstZero = _toKstZero(
            DateTime(focusedDay.year, focusedDay.month, focusedDay.day),
          );
          setState(() {
            _focusedDayInternal = focusedDayKstZero;
          });
          widget.onPageChanged?.call(focusedDayKstZero);
        },
      ),
    );
  }

  Widget _buildCustomCell(
    BuildContext context,
    DateTime day,
    bool hasEvent,
    bool isToday,
    bool isEnabled,
    bool isOutside,
  ) {
    Color circleColor;
    Border? circleBorder;
    Widget? iconContent;

    final isCurrentMonth = day.month == _focusedDayInternal.month;

    if (isOutside) {
      circleColor = Colors.grey.shade200.withOpacity(0.5);
    } else if (!isEnabled) {
      circleColor = isCurrentMonth
          ? Colors.grey.shade300
          : Colors.grey.shade200.withOpacity(0.7);
    } else {
      if (hasEvent) {
        circleColor = Colors.yellow.shade100;
        iconContent = Icon(
          Icons.local_fire_department,
          color: Colors.deepOrangeAccent,
          size: 20,
        );
        if (!isToday) {
          circleBorder = Border.all(
            color: Colors.orangeAccent.withOpacity(0.7),
            width: 1.5,
          );
        }
      } else {
        circleColor = Colors.grey.shade300;
      }

      if (isToday) {
        circleBorder = Border.all(color: Colors.orange.shade700, width: 2);
      }
    }

    return GestureDetector(
      onTap:
          () =>
              isEnabled && !isOutside
                  ? _handleDayCellTap(
                    _toKstZero(DateTime(day.year, day.month, day.day)),
                  )
                  : null,
      child: Container(
        margin: const EdgeInsets.all(5.0),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: circleColor,
          border: circleBorder,
        ),
        child: Center(child: iconContent),
      ),
    );
  }

  void _handleDayCellTap(DateTime tappedDayKstZero) {
    final bool hasEvent = widget.daysWithDiary.contains(tappedDayKstZero);

    widget.onDateTap?.call(
      DateTapDetails(date: tappedDayKstZero, hasEvent: hasEvent),
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
