// lib/features/schedule/schedule_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_qnote/api/schedule/schedule_api.dart';
import 'package:flutter_qnote/features/schedule/widgets/schedule_holder_widget.dart';
import 'package:intl/intl.dart'; // 날짜 포매팅을 위해 필요

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({Key? key}) : super(key: key);

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _selectedDate = DateTime.now();
  final ScrollController _dateScrollController = ScrollController();
  final List<DateTime> _weekDays = [];

  // 헤더, 날짜 선택기, 일정 목록 등에 사용될 더미 데이터
  List<Map<String, dynamic>> _schedules = [
    {
      'time_start': '16:00',
      'time_end': '14:30',
      'title': '해야 할 일',
      'description':
          '세부 설정 세부 설정 세부 설정 세부 설정 세부 설정 세부 설정 세부 설정 세부 설정 세부 설정 세부 설정 세부 설정',
      'isImportant': true,
    },
    {
      'time_start': '15:00',
      'time_end': '16:30',
      'title': '해야 할 일',
      'description': '세부 설정 세부 설정 세부 설정 세부 설정 세부 설정',
      'isImportant': false,
    },
    {
      'time_start': '19:00',
      'time_end': '20:30',
      'title': '해야 할 일',
      'description': '세부 설정 세부 설정 세부 설정 세부 설정 세부 설정 세부 설정 세부 설정',
      'isImportant': false,
    },
    // 더 많은 더미 데이터 추가 가능
  ];

  @override
  void initState() {
    super.initState();
    _generateWeekDays();
    // 선택된 날짜가 화면 중앙에 오도록 스크롤 위치 조정
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (_weekDays.isNotEmpty && _dateScrollController.hasClients) {
          int selectedIndex = _weekDays.indexWhere(
            (day) =>
                day.year == _selectedDate.year &&
                day.month == _selectedDate.month &&
                day.day == _selectedDate.day,
          );
          if (selectedIndex != -1) {
            double itemWidth = 50.0 + 8.0; // 아이템 너비 + 마진
            double containerWidth = MediaQuery.of(context).size.width;
            double offset =
                (selectedIndex * itemWidth) -
                (containerWidth / 2) +
                (itemWidth / 2);
            _dateScrollController.jumpTo(
              offset.clamp(0.0, _dateScrollController.position.maxScrollExtent),
            );
          }
        }
      } catch (e, stack) {
        print('🛑 스크롤 위치 조정 중 오류 발생: $e');
        print(stack);
      }
    });

    initSchedules();
  }

  bool _isLoading = false;

  void initSchedules() async {
    print('========= initSchedules called ========');
    print('initSchedules called with date: $_selectedDate');

    setState(() {
      _isLoading = true;
    });

    try {
      final list = await ScheduleApi.instance.getScheduleByDate(_selectedDate);

      setState(() {
        _schedules =
            list.map((e) {
              return {
                'time_start': DateFormat.Hm('ko_KR').format(e.startAt),
                'time_end': DateFormat.Hm('ko_KR').format(e.endAt),
                'title': e.title,
                'description': e.context,
                'isImportant': e.isAllDay, // 예시로 isAllDay를 중요 표시로 사용
              };
            }).toList();

        _isLoading = false;
      });
    } catch (e) {
      print(e);
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _dateScrollController.dispose();
    super.dispose();
  }

  void _generateWeekDays() {
    _weekDays.clear();
    DateTime firstDayOfWeek = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday - DateTime.monday),
    );
    if (_selectedDate.weekday == DateTime.sunday) {
      // 일요일이 주의 시작인 경우 (선택적)
      firstDayOfWeek = _selectedDate.subtract(const Duration(days: 6));
    }

    for (int i = -7; i <= 14; i++) {
      // 현재 주 포함 앞뒤로 1주씩 더 (넉넉하게)
      _weekDays.add(firstDayOfWeek.add(Duration(days: i)));
    }
  }

  void _onDateSelected(DateTime date) async {
    if (!mounted) return;
    _selectedDate = date;

    // 날짜 변경 시, 일정 리스트 배열 초기화
    initSchedules();
  }

  Widget _buildScheduleScreenHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10, // 상태 표시줄 높이만큼 패딩
        left: 20,
        right: 20,
        bottom: 20,
      ),
      color: const Color(0xFFB59A7B),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center, // 수직 중앙 정렬
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat('d').format(_selectedDate),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.1, // 줄간격 미세 조정
                  letterSpacing: -1, // 자간 미세 조정
                ),
              ),
              // SizedBox(height: 0), // 날짜와 요일 사이 간격 거의 없게
              Text(
                '${DateFormat.EEEE('ko_KR').format(_selectedDate)} ${DateFormat.yMMMM('ko_KR').format(_selectedDate)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                  height: 1.0,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white, size: 28),
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('일정 검색 기능 (준비 중)')));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalDatePicker() {
    return Container(
      height: 75, // 높이 조절
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        controller: _dateScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: _weekDays.length,
        itemBuilder: (context, index) {
          final date = _weekDays[index];
          final isSelected =
              date.year == _selectedDate.year &&
              date.month == _selectedDate.month &&
              date.day == _selectedDate.day;
          return GestureDetector(
            onTap: () => _onDateSelected(date),
            child: Container(
              width: 50,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color:
                    isSelected ? const Color(0xFF8FBC8F) : Colors.transparent,
                borderRadius: BorderRadius.circular(12), // 좀 더 둥글게
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat.E('ko_KR').format(date).substring(0, 1),
                    style: TextStyle(
                      fontSize: 13, // 폰트 크기 살짝 조정
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('d').format(date),
                    style: TextStyle(
                      fontSize: 17, // 폰트 크기 살짝 조정
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 일정 목록을 표시하는 위젯
  Widget _buildScheduleListContent() {
    if (_schedules.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(30.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_busy_outlined,
                size: 60,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                '${DateFormat('M월 d일 EEEE', 'ko_KR').format(_selectedDate)}에는\n예정된 일정이 없습니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: 80,
      ), // 하단 버튼 고려한 패딩
      itemCount: _schedules.length, // 버튼은 Stack으로 처리
      itemBuilder: (context, index) {
        final schedule = _schedules[index];
        return ScheduleHolderWidget(
          timeStart: schedule['time_start'],
          timeEnd: schedule['time_end'],
          title: schedule['title'],
          description: schedule['description'],
          isImportant: schedule['isImportant'],
        );
      },
    );
  }

  Widget _buildAddScheduleButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: ElevatedButton.icon(
        icon: Icon(
          Icons.add_circle_outline,
          color: Colors.brown.shade700,
          size: 22,
        ),
        label: Text(
          '일정 추가하기',
          style: TextStyle(
            color: Colors.brown.shade800,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        onPressed: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('일정 추가 기능 (준비 중)')));
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF5F0E9),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ScheduleScreen은 자체 Scaffold를 가짐
      backgroundColor: const Color(0xFFF4F6F8), // 전체 배경색
      // appBar는 null이므로 DashboardScreen의 AppBar가 표시되지 않음
      body: Column(
        children: [
          _buildScheduleScreenHeader(),
          _buildHorizontalDatePicker(),
          Expanded(
            child: Stack(
              // 일정 목록과 추가 버튼을 Stack으로 배치
              children: [
                _buildScheduleListContent(),
                Align(
                  // 버튼을 하단에 고정
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    // 버튼 배경색과 패딩을 위해 Container 사용
                    color: const Color(0xFFF4F6F8).withOpacity(0.9), // 반투명 배경
                    padding: const EdgeInsets.only(
                      bottom: 10,
                      top: 5,
                    ), // SafeArea 하단 여백 고려
                    child: _buildAddScheduleButton(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
