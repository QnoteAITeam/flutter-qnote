import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_qnote/api/diary_api.dart';
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

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _focusedDayForCalendar = DateTime(_today.year, _today.month, _today.day);
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
      final User currentUser = await UserApi.instance.getUserCredential();
      return {"userName": "${currentUser.username}님"};
    } catch (e) {
      return {"userName": "사용자님"};
    }
  }

  Future<void> _initializeScreenAndUserData({bool forceRefresh = false}) async {
    if (!mounted) return;
    if (!forceRefresh && !_isLoadingPage && _isUserAuthenticated &&
        _initialDiariesFetchAttempted && _cachedDiaries.isNotEmpty && !_isLoadingDiaries) {
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
        if (authStatusChanged || forceRefresh || !_initialDiariesFetchAttempted) {
          await _tryFetchInitialDiaries(forceRefresh: true, isInitialLoadOverride: !_initialDiariesFetchAttempted);
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

  Future<void> _tryFetchInitialDiaries({bool forceRefresh = false, bool isInitialLoadOverride = false}) async {
    if (!mounted || !_isUserAuthenticated) return;
    if (_initialDiariesFetchAttempted && _cachedDiaries.isNotEmpty && !forceRefresh && !isInitialLoadOverride) {
      return;
    }
    await _fetchDiariesAndUpdateState(_focusedDayForCalendar, isInitialLoad: isInitialLoadOverride);
  }

  Future<void> _fetchDiariesAndUpdateState(DateTime referenceDateForView, {bool isInitialLoad = false}) async {
    if (!mounted || !_isUserAuthenticated) return;
    if (mounted) setState(() => _isLoadingDiaries = true);
    String? snackBarMessageForError;
    try {
      final List<Diary> fetchedDiaries = await DiaryApi.instance.getRecentDiaries(150);
      print('[FETCHED DIARIES] Count: ${fetchedDiaries.length}');
      for (final diary in fetchedDiaries) {
        print(' - Diary ID: ${diary.id}, Title: ${diary.title}, Summary: ${diary.summary}');
      }
      _cachedDiaries = fetchedDiaries;
      _initialDiariesFetchAttempted = true;
      // 🔥 반드시 toLocal()로 변환해서 KST 기준으로 저장
      _daysWithDiaryFromApi = fetchedDiaries
          .where((diary) => diary.createdAt != null)
          .map((diary) {
        final local = diary.createdAt!.toLocal();
        return DateTime(local.year, local.month, local.day);
      })
          .toSet();
      if (mounted) {
        setState(() {
          _updateWeeklyFlameCount();
          _updateTodaySummaryAndStatus();
        });
      }
    } catch (e) {
      _initialDiariesFetchAttempted = true;
      if (e.toString().contains('404') || e.toString().toLowerCase().contains('not found')) {
        if (mounted) setState(() { _clearDiaryData(); });
      } else {
        snackBarMessageForError = '일기 정보 로드 중 오류가 발생했습니다.';
        if (e.toString().toLowerCase().contains('unauthorized') || e.toString().contains('401')) {
          snackBarMessageForError = '세션이 만료되었거나 인증 오류입니다. 다시 로그인해주세요.';
        }
        if (mounted) setState(() { _clearDiaryData(); });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingDiaries = false);
        if (snackBarMessageForError != null && mounted && ModalRoute.of(context)!.isCurrent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(snackBarMessageForError), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  void _updateTodaySummaryAndStatus() {
    Diary? todayDiary;
    final now = DateTime.now();
    final todayDateOnly = DateTime(now.year, now.month, now.day);
    bool foundTodayDiary = false;

    if (_cachedDiaries.isNotEmpty) {
      // 최신순(내림차순)으로 정렬
      final sorted = List<Diary>.from(_cachedDiaries)
        ..sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
      for (final diary in sorted) {
        if (diary.createdAt != null) {
          final diaryDateLocal = diary.createdAt!.toLocal();
          final diaryDateOnly = DateTime(diaryDateLocal.year, diaryDateLocal.month, diaryDateLocal.day);
          if (diaryDateOnly.isAtSameMomentAs(todayDateOnly)) {
            todayDiary = diary;
            foundTodayDiary = true;
            print('[TODAY DIARY FOUND] ID: ${diary.id}, Summary: ${diary.summary}');
            break;
          }
        }
      }
    }
    _hasWrittenTodayDiary = foundTodayDiary;

    String? newSummary;
    if (todayDiary != null) {
      newSummary = todayDiary.summary.isNotEmpty
          ? todayDiary.summary
          : (todayDiary.content.isNotEmpty
          ? (todayDiary.content.length > 50 ? '${todayDiary.content.substring(0, 50)}...' : todayDiary.content)
          : "요약 정보 없음");
    }
    _todayDiarySummary = newSummary;
  }

  void _updateWeeklyFlameCount() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - DateTime.monday));
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
          final diaryDateLocal = diary.createdAt!.toLocal();
          final diaryDateOnly = DateTime(diaryDateLocal.year, diaryDateLocal.month, diaryDateLocal.day);
          if (_isSameDay(diaryDateOnly, details.date)) {
            tappedDiary = diary; break;
          }
        }
      }
      if (tappedDiary != null && mounted) {
        FocusScope.of(context).unfocus();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DiaryDetailScreen(diaryToEdit: tappedDiary)),
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

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  PreferredSizeWidget _buildDashboardAppBar() => const DashboardAppBar();

  Widget _buildGreeting() {
    return GreetingCardWidget(
      isUserAuthenticated: _isUserAuthenticated,
      userName: _userName,
      hasWrittenTodayDiary: _hasWrittenTodayDiary,
      onLoginPressed: () async {
        final result = await Navigator.push<bool>(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
        if (result == true && mounted) await _initializeScreenAndUserData(forceRefresh: true);
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
    if (!_initialDiariesFetchAttempted || (_isLoadingDiaries && !_initialDiariesFetchAttempted)) {
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
                    child: Text('일기 정보를 불러오는 중입니다...', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ),
                  Container(
                    key: _calendarWidgetKey,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.grey.withAlpha(80), blurRadius: 10, offset: Offset(0,1))]
                    ),
                    padding: const EdgeInsets.only(bottom:8),
                    child: CalendarWidget(
                      focusedDayForCalendar: _focusedDayForCalendar,
                      today: DateTime(_today.year, _today.month, _today.day),
                      daysWithDiary: const {},
                      onDateTap: _handleCalendarDateTap,
                      onPageChanged: (newFocusedPageDate) {
                        if (mounted) {
                          if (!_isSameDay(_focusedDayForCalendar, newFocusedPageDate) || _focusedDayForCalendar.month != newFocusedPageDate.month) {
                            setState(() => _focusedDayForCalendar = newFocusedPageDate);
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.grey.withAlpha(80), spreadRadius: 0.5, blurRadius: 10, offset: Offset(0,1))]
                    ),
                    child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('오늘의 일기 요약', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87)),
                          SizedBox(height: 12),
                          Text('요약 정보를 불러오는 중...', style: TextStyle(fontSize: 15, height: 1.5, color: Colors.grey))
                        ]
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
              today: DateTime(_today.year, _today.month, _today.day),
              daysWithDiary: _daysWithDiaryFromApi,
              weeklyFlameCount: _weeklyFlameCount,
              todayDiarySummary: _todayDiarySummary,
              cachedDiariesEmpty: _cachedDiaries.isEmpty,
              onDateTap: _handleCalendarDateTap,
              onCalendarPageChanged: (newFocusedPageDate) {
                if (mounted) {
                  if (!_isSameDay(_focusedDayForCalendar, newFocusedPageDate) || _focusedDayForCalendar.month != newFocusedPageDate.month) {
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
    if (_isLoadingPage && _currentIndex == 0 && !_initialDiariesFetchAttempted) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F6F8),
        body: Center(child: CircularProgressIndicator(key: ValueKey("full_page_loading_dashboard"))),
      );
    }

    final List<Widget> currentTabScreens = [
      RefreshIndicator(
        onRefresh: () => _initializeScreenAndUserData(forceRefresh: true),
        child: _buildHomeScreenBody(),
      ),
      const SearchScreen(),
      const ChatScreen(),
      const ScheduleScreen(),
      const ProfileScreen(),
    ];

    PreferredSizeWidget? currentAppBar;
    switch (_currentIndex) {
      case 0: case 1: case 4: currentAppBar = _buildDashboardAppBar(); break;
      case 2: case 3: currentAppBar = null; break;
      default: currentAppBar = _buildDashboardAppBar();
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        appBar: currentAppBar,
        body: IndexedStack(index: _currentIndex, children: currentTabScreens),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey.shade500,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          onTap: (idx) async {
            if (!mounted) return;
            if (_currentIndex != idx) FocusScope.of(context).unfocus();

            bool needsRefreshForHome = false;
            if (idx == 0) needsRefreshForHome = true;
            if (mounted) setState(() => _currentIndex = idx);
            if (needsRefreshForHome) {
              await _initializeScreenAndUserData(forceRefresh: true);
            } else if (idx != 0 && !_isUserAuthenticated) {
              String featureName = '';
              switch (idx) {
                case 1: featureName = '검색'; break;
                case 2: featureName = 'AI 채팅'; break;
                case 3: featureName = '일정'; break;
                case 4: featureName = '프로필'; break;
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$featureName을(를) 이용하려면 로그인이 필요합니다.')));
                final loginSuccess = await Navigator.push<bool>(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                if (loginSuccess == true && mounted) {
                  await _initializeScreenAndUserData(forceRefresh: true);
                  if (_isUserAuthenticated && idx != 0) {
                    if (mounted) setState(() => _currentIndex = idx);
                  } else {
                    if (mounted) setState(() => _currentIndex = 0);
                  }
                } else {
                  if (mounted) setState(() => _currentIndex = 0);
                }
              }
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: '홈'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: '검색'),
            BottomNavigationBarItem(icon: CircleAvatar(backgroundColor: Color(0xFFB59A7B), child: Icon(Icons.chat_bubble_outline, color: Colors.white, size: 26)), label: 'AI 채팅'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: '일정'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: '프로필'),
          ],
        ),
      ),
    );
  }
}
