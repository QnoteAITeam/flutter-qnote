import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_qnote/api/diary_api.dart';
import 'package:flutter_qnote/api/dto/get_user_info_dto.dart';
import 'package:flutter_qnote/api/user_api.dart';
import 'package:flutter_qnote/models/diary.dart';
import 'package:flutter_qnote/models/user.dart';
import 'widgets/calendar_widget.dart';
import 'package:flutter_qnote/features/search/search_screen.dart';
import 'package:flutter_qnote/features/chat/chat_screen.dart';
import 'package:flutter_qnote/auth/auth_api.dart';
import 'package:flutter_qnote/features/login/login_screen.dart';
import 'package:flutter_qnote/features/profile/profile_screen.dart';
import 'package:flutter_qnote/features/schedule/schedule_screen.dart';
import 'widgets/dashboard_app_bar.dart';
import 'widgets/greeting_card_widget.dart';
import 'widgets/diary_summary_section_widget.dart';
import 'package:flutter_qnote/features/diary/diary_detail_screen.dart';
import 'package:flutter_qnote/api/dto/get_diary_info_dto.dart'; // DTO import 추가
import 'package:flutter_qnote/features/search/search_home_screen.dart';

// 변환 함수 추가
Diary diaryFromDto(FetchDiaryResponseDto dto) {
  return Diary(
    id: dto.id,
    title: dto.title,
    content: dto.content,
    tags: dto.tags,
    emotionTags: dto.emotionTags,
    createdAt: dto.createdAt,
    updatedAt: dto.updatedAt,
    summary: dto.summary,
  );
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  int _weeklyFlameCount = 0;
  int _currentIndex = 0;
  String _userName = '사용자님';
  late DateTime _focusedDayForCalendar;
  final DateTime _today = DateTime.now();

  Set<DateTime> _daysWithDiaryFromApi = {};
  List<Diary> _cachedDiaries = [];
  bool _isLoadingPage = true;
  bool _isLoadingDiaries = false;
  String? _todayDiarySummary;
  bool _hasWrittenTodayDiary = false;
  bool _isUserAuthenticated = false;
  bool _initialDiariesFetchAttempted = false;

  final GlobalKey _calendarWidgetKey = GlobalKey();

  DateTime _add9Hours(DateTime date) => date.add(const Duration(hours: 9));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _focusedDayForCalendar = _add9Hours(
      DateTime(_today.year, _today.month, _today.day),
    );
    _initializeScreenAndUserData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _initializeScreenAndUserData(forceRefresh: true);
    }
  }

  Future<Map<String, dynamic>> _fetchUserData() async {
    if (!_isUserAuthenticated) return {"userName": "방문자님"};
    try {
      final FetchUserResponseDto currentUser =
          await UserApi.instance.getUserCredential();

      return {"userName": "${currentUser.username}님"};
    } catch (e) {
      return {"userName": "사용자님"};
    }
  }

  Future<void> _initializeScreenAndUserData({bool forceRefresh = false}) async {
    if (!mounted) return;
    if (!forceRefresh &&
        !_isLoadingPage &&
        _isUserAuthenticated &&
        _initialDiariesFetchAttempted &&
        _cachedDiaries.isNotEmpty &&
        !_isLoadingDiaries) {
      return;
    }
    if (mounted) setState(() => _isLoadingPage = true);
    bool isLoggedIn = false;
    try {
      String? token = await AuthApi.getInstance.getAccessTokenHeader();
      isLoggedIn = token != null && token.isNotEmpty;
    } catch (_) {}
    if (mounted) {
      bool authStatusChanged = _isUserAuthenticated != isLoggedIn;
      _isUserAuthenticated = isLoggedIn;
      if (isLoggedIn) {
        Map<String, dynamic> userData = await _fetchUserData();
        if (mounted) setState(() => _userName = userData['userName'] as String);
        if (authStatusChanged ||
            forceRefresh ||
            !_initialDiariesFetchAttempted) {
          await _tryFetchInitialDiaries(
            forceRefresh: true,
            isInitialLoadOverride: !_initialDiariesFetchAttempted,
          );
        }
      } else {
        _clearDiaryData();
        if (mounted) setState(() => _userName = "방문자님");
      }
      if (mounted) setState(() => _isLoadingPage = false);
    }
  }

  void _clearDiaryData() {
    if (mounted) {
      setState(() {
        _cachedDiaries = [];
        _daysWithDiaryFromApi = {};
        _weeklyFlameCount = 0;
        _todayDiarySummary = null;
        _hasWrittenTodayDiary = false;
        _initialDiariesFetchAttempted = false;
        _isLoadingDiaries = false;
      });
    }
  }

  Future<void> _tryFetchInitialDiaries({
    bool forceRefresh = false,
    bool isInitialLoadOverride = false,
  }) async {
    if (!mounted || !_isUserAuthenticated) return;
    if (_initialDiariesFetchAttempted &&
        _cachedDiaries.isNotEmpty &&
        !forceRefresh &&
        !isInitialLoadOverride) {
      return;
    }
    await _fetchDiariesAndUpdateState(
      _focusedDayForCalendar,
      isInitialLoad: isInitialLoadOverride,
    );
  }

  Future<void> _fetchDiariesAndUpdateState(
    DateTime referenceDateForView, {
    bool isInitialLoad = false,
  }) async {
    if (!mounted || !_isUserAuthenticated) return;
    if (mounted) setState(() => _isLoadingDiaries = true);
    String? snackBarMessageForError;
    try {
      // 여기서 DTO로 받아서 Diary로 변환
      final List<FetchDiaryResponseDto> fetchedDtos = await DiaryApi.instance
          .getRecentDiaries(150);
      final List<Diary> fetchedDiaries =
          fetchedDtos.map((dto) => diaryFromDto(dto)).toList();
      _cachedDiaries = fetchedDiaries;
      _initialDiariesFetchAttempted = true;
      _daysWithDiaryFromApi =
          fetchedDiaries.where((diary) => diary.createdAt != null).map((diary) {
            final plus9 = diary.createdAt!.add(const Duration(hours: 9));
            return DateTime(plus9.year, plus9.month, plus9.day);
          }).toSet();
      if (mounted) {
        setState(() {
          _updateWeeklyFlameCount();
          _updateTodaySummaryAndStatus();
        });
      }
    } catch (e) {
      _initialDiariesFetchAttempted = true;
      if (e.toString().contains('404') ||
          e.toString().toLowerCase().contains('not found')) {
        if (mounted)
          setState(() {
            _clearDiaryData();
          });
      } else {
        snackBarMessageForError = '일기 정보 로드 중 오류가 발생했습니다.';
        if (e.toString().toLowerCase().contains('unauthorized') ||
            e.toString().contains('401')) {
          snackBarMessageForError = '세션이 만료되었거나 인증 오류입니다. 다시 로그인해주세요.';
        }
        if (mounted)
          setState(() {
            _clearDiaryData();
          });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingDiaries = false);
        if (snackBarMessageForError != null &&
            mounted &&
            ModalRoute.of(context)!.isCurrent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(snackBarMessageForError),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  void _updateTodaySummaryAndStatus() {
    Diary? todayDiary;
    final now = DateTime.now().add(const Duration(hours: 9));
    final todayDateOnly = DateTime(now.year, now.month, now.day);
    bool foundTodayDiary = false;

    if (_cachedDiaries.isNotEmpty) {
      final sorted = List<Diary>.from(_cachedDiaries)
        ..sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
      for (final diary in sorted) {
        if (diary.createdAt != null) {
          final diaryDatePlus9 = diary.createdAt!.add(const Duration(hours: 9));
          final diaryDateOnly = DateTime(
            diaryDatePlus9.year,
            diaryDatePlus9.month,
            diaryDatePlus9.day,
          );
          if (diaryDateOnly.isAtSameMomentAs(todayDateOnly)) {
            todayDiary = diary;
            foundTodayDiary = true;
            break;
          }
        }
      }
    }
    _hasWrittenTodayDiary = foundTodayDiary;

    String? newSummary;
    if (todayDiary != null) {
      newSummary =
          todayDiary.summary.isNotEmpty
              ? todayDiary.summary
              : (todayDiary.content.isNotEmpty
                  ? (todayDiary.content.length > 50
                      ? '${todayDiary.content.substring(0, 50)}...'
                      : todayDiary.content)
                  : "요약 정보 없음");
    }
    _todayDiarySummary = newSummary;
  }

  void _updateWeeklyFlameCount() {
    final now = DateTime.now().add(const Duration(hours: 9));
    final startOfWeek = now.subtract(
      Duration(days: now.weekday - DateTime.monday),
    );
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    int count = 0;
    for (DateTime diaryDate in _daysWithDiaryFromApi) {
      if (!diaryDate.isBefore(startOfWeek) && !diaryDate.isAfter(endOfWeek)) {
        count++;
      }
    }
    _weeklyFlameCount = count;
  }

  void _handleCalendarDateTap(DateTapDetails details) {
    if (details.hasEvent) {
      Diary? tappedDiary;
      for (var diary in _cachedDiaries) {
        if (diary.createdAt != null) {
          final diaryDatePlus9 = diary.createdAt!.add(const Duration(hours: 9));
          final diaryDateOnly = DateTime(
            diaryDatePlus9.year,
            diaryDatePlus9.month,
            diaryDatePlus9.day,
          );
          if (_isSameDay(diaryDateOnly, details.date)) {
            tappedDiary = diary;
            break;
          }
        }
      }
      if (tappedDiary != null && mounted) {
        FocusScope.of(context).unfocus();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DiaryDetailScreen(diaryToEdit: tappedDiary),
          ),
        ).then((returnedValue) {
          FocusScope.of(context).unfocus();
          if (returnedValue is Diary || returnedValue == true) {
            _initializeScreenAndUserData(forceRefresh: true);
          }
        });
      }
    }
  }

  void _navigateToNewDiaryViaChat() {
    if (mounted) {
      FocusScope.of(context).unfocus();
      setState(() => _currentIndex = 2);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  PreferredSizeWidget _buildDashboardAppBar() => const DashboardAppBar();

  Widget _buildGreeting() {
    return GreetingCardWidget(
      isUserAuthenticated: _isUserAuthenticated,
      userName: _userName,
      hasWrittenTodayDiary: _hasWrittenTodayDiary,
      onLoginPressed: () async {
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        if (result == true && mounted)
          await _initializeScreenAndUserData(forceRefresh: true);
      },
      onWriteNewDiaryPressed: _navigateToNewDiaryViaChat,
    );
  }

  Widget _buildHomeScreenBody() {
    if (!_isUserAuthenticated) {
      return Column(
        children: [
          _buildGreeting(),
          Expanded(child: Center(child: Text("로그인 후 이용해주세요."))),
        ],
      );
    }
    if (!_initialDiariesFetchAttempted ||
        (_isLoadingDiaries && !_initialDiariesFetchAttempted)) {
      return Column(
        children: [
          GreetingCardWidget(
            isUserAuthenticated: _isUserAuthenticated,
            userName: _userName,
            hasWrittenTodayDiary: false,
            onLoginPressed: () async {},
            onWriteNewDiaryPressed: _navigateToNewDiaryViaChat,
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 0, bottom: 16),
                    child: Text(
                      '일기 정보를 불러오는 중입니다...',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    key: _calendarWidgetKey,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withAlpha(80),
                          blurRadius: 10,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.only(bottom: 8),
                    child: CalendarWidget(
                      focusedDayForCalendar: _focusedDayForCalendar,
                      today: _add9Hours(
                        DateTime(_today.year, _today.month, _today.day),
                      ),
                      daysWithDiary: _daysWithDiaryFromApi,
                      onDateTap: _handleCalendarDateTap,
                      onPageChanged: (newFocusedPageDate) {
                        if (mounted) {
                          if (!_isSameDay(
                                _focusedDayForCalendar,
                                newFocusedPageDate,
                              ) ||
                              _focusedDayForCalendar.month !=
                                  newFocusedPageDate.month) {
                            setState(
                              () => _focusedDayForCalendar = newFocusedPageDate,
                            );
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withAlpha(80),
                          spreadRadius: 0.5,
                          blurRadius: 10,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '오늘의 일기 요약',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          '요약 정보를 불러오는 중...',
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        _buildGreeting(),
        Expanded(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DiarySummarySectionWidget(
              calendarWidgetKey: _calendarWidgetKey,
              focusedDayForCalendar: _focusedDayForCalendar,
              today: _add9Hours(
                DateTime(_today.year, _today.month, _today.day),
              ),
              daysWithDiary: _daysWithDiaryFromApi,
              weeklyFlameCount: _weeklyFlameCount,
              todayDiarySummary: _todayDiarySummary,
              cachedDiariesEmpty: _cachedDiaries.isEmpty,
              onDateTap: _handleCalendarDateTap,
              onCalendarPageChanged: (newFocusedPageDate) {
                if (mounted) {
                  if (!_isSameDay(_focusedDayForCalendar, newFocusedPageDate) ||
                      _focusedDayForCalendar.month !=
                          newFocusedPageDate.month) {
                    setState(() => _focusedDayForCalendar = newFocusedPageDate);
                  }
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPage &&
        _currentIndex == 0 &&
        !_initialDiariesFetchAttempted) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F6F8),
        body: Center(
          child: CircularProgressIndicator(
            key: ValueKey("full_page_loading_dashboard"),
          ),
        ),
      );
    }

    final List<Widget> currentTabScreens = [
      RefreshIndicator(
        onRefresh: () => _initializeScreenAndUserData(forceRefresh: true),
        child: _buildHomeScreenBody(),
      ),
      const SearchHomeScreen(), // ✅ 최근 일기 보여주는 첫 화면
      const ChatScreen(),
      const ScheduleScreen(),
      const ProfileScreen(),
    ];

    PreferredSizeWidget? currentAppBar;
    switch (_currentIndex) {
      case 0:
      case 1:
      case 4:
        currentAppBar = _buildDashboardAppBar();
        break;
      case 2:
      case 3:
        currentAppBar = null;
        break;
      default:
        currentAppBar = _buildDashboardAppBar();
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        appBar: currentAppBar,
        body: IndexedStack(index: _currentIndex, children: currentTabScreens),
        bottomNavigationBar: _CustomBottomNavBar(
          currentIndex: _currentIndex,
          onTap: (idx) {
            if (idx == 0) {
              setState(() => _currentIndex = 0);
              _initializeScreenAndUserData(
                forceRefresh: true,
              ); // 홈 새로고침 시 일기 갱신
            } else if (idx == 2) {
              setState(() => _currentIndex = 2); // 채팅화면 이동
            } else {
              setState(() => _currentIndex = idx);
            }
          },
        ),
        floatingActionButton:
            MediaQuery.of(context).viewInsets.bottom == 0 && _currentIndex != 2
                ? FloatingActionButton(
                  backgroundColor: const Color(0xFFB59A7B),
                  elevation: 2,
                  onPressed: () {
                    setState(() => _currentIndex = 2); // 채팅화면 이동
                  },
                  child: const Icon(Icons.edit, color: Colors.white, size: 32),
                  shape: const CircleBorder(),
                )
                : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }
}

class _CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _CustomBottomNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colors.white,
      elevation: 8,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 48,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_filled,
              label: '홈',
              selected: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            _NavItem(
              icon: Icons.search,
              label: '검색',
              selected: currentIndex == 1,
              onTap: () => onTap(1),
            ),
            const SizedBox(width: 48),
            _NavItem(
              icon: Icons.calendar_today_outlined,
              label: '일정',
              selected: currentIndex == 3,
              onTap: () => onTap(3),
            ),
            _NavItem(
              icon: Icons.person_outline,
              label: '프로필',
              selected: currentIndex == 4,
              onTap: () => onTap(4),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.black : Colors.grey.shade500;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 52,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
