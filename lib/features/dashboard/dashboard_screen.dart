// lib/features/dashboard/dashboard_screen.dart
import 'dart:async';
import 'dart:io'; // SocketException, TimeoutException

import 'package:flutter/material.dart';
import 'package:flutter_qnote/api/diary_api.dart';
import 'package:flutter_qnote/models/diary.dart';
import 'package:flutter_qnote/widgets/calendar_widget.dart';
import 'package:flutter_qnote/features/search/search_screen.dart';
import 'package:flutter_qnote/features/chat/chat_screen.dart';
import 'package:flutter_qnote/auth/auth_api.dart';
import 'package:flutter_qnote/features/login/login_screen.dart';
import 'package:flutter_qnote/features/profile/profile_screen.dart';
import 'package:flutter_qnote/features/schedule/schedule_screen.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  int _weeklyFlameCount = 0;
  int _currentIndex = 0;
  String _userName = '사용자';
  late DateTime _focusedDayForCalendar;
  final DateTime _today = DateTime.now();

  Set<DateTime> _daysWithDiaryFromApi = {};
  List<Diary> _cachedDiaries = [];
  bool _isLoadingPage = true;
  bool _isLoadingDiaries = false;
  String? _todayDiarySummary;
  bool _isUserAuthenticated = false;
  bool _initialDiariesFetchAttempted = false;
  bool _isEmailVerified = true;

  OverlayEntry? _diarySnippetOverlayEntry;
  final GlobalKey _calendarWidgetKey = GlobalKey();
  Timer? _snippetOverlayTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _focusedDayForCalendar = _today;
    _initializeScreenAndUserData();
  }

  Future<Map<String, dynamic>> _fetchUserData() async {
    if (_isUserAuthenticated) {
      try {
        await Future.delayed(const Duration(milliseconds: 50));
        return {"userName": "큐노트 사용자", "isEmailVerified": true};
      } catch (e) {
        print("DashboardScreen: Error fetching user profile: $e");
        return {"userName": "사용자", "isEmailVerified": false};
      }
    }
    return {"userName": "방문자", "isEmailVerified": false};
  }

  Future<void> _initializeScreenAndUserData({bool forceRefresh = false}) async {
    print("DashboardScreen: _initializeScreenAndUserData called with forceRefresh: $forceRefresh");
    if (!mounted) return;

    if (!forceRefresh && !_isLoadingPage && _isUserAuthenticated && _initialDiariesFetchAttempted && _cachedDiaries.isNotEmpty && !_isLoadingDiaries) {
      print("DashboardScreen: Data likely up-to-date and not forcing refresh. Skipping.");
      return;
    }

    if (mounted) setState(() => _isLoadingPage = true);

    bool isLoggedIn = false;
    try {
      String? accessTokenHeader = await AuthApi.getInstance.getAccessTokenHeader();
      isLoggedIn = accessTokenHeader != null && accessTokenHeader.isNotEmpty;
    } catch (e) {
      print("DashboardScreen: Error checking auth status: $e");
    }

    if (mounted) {
      bool previousAuthStatus = _isUserAuthenticated;
      _isUserAuthenticated = isLoggedIn;

      if (isLoggedIn) {
        Map<String, dynamic> userData = await _fetchUserData();
        if (mounted) {
          setState(() {
            _userName = userData['userName'] as String;
            _isEmailVerified = userData['isEmailVerified'] as bool;
          });
        }
        if ((previousAuthStatus != isLoggedIn && isLoggedIn) || forceRefresh || !_initialDiariesFetchAttempted) {
          await _tryFetchInitialDiaries(forceRefresh: true, isInitialLoadOverride: !_initialDiariesFetchAttempted);
        }
      } else {
        _clearDiaryData();
        if (mounted) {
          setState(() {
            _userName = "방문자";
            _isEmailVerified = false;
          });
        }
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
        _initialDiariesFetchAttempted = false;
        _isLoadingDiaries = false;
      });
    }
  }

  Future<void> _tryFetchInitialDiaries({bool forceRefresh = false, bool isInitialLoadOverride = false}) async {
    if (!mounted || !_isUserAuthenticated) return;
    bool actualInitialLoad = isInitialLoadOverride;

    if (_initialDiariesFetchAttempted && _cachedDiaries.isNotEmpty && !forceRefresh && !actualInitialLoad) {
      return;
    }
    await _fetchDiariesAndUpdateState(_focusedDayForCalendar, isInitialLoad: actualInitialLoad);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _removeDiarySnippetOverlay();
    _snippetOverlayTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && mounted) {
      print("DashboardScreen: App resumed. Forcing data refresh.");
      _initializeScreenAndUserData(forceRefresh: true);
    }
  }

  Future<void> _fetchDiariesAndUpdateState(DateTime referenceDateForView, {bool isInitialLoad = false}) async {
    if (!mounted || !_isUserAuthenticated) return;
    if (mounted) setState(() => _isLoadingDiaries = true);
    String? snackBarMessageForError;

    try {
      print("DashboardScreen: Fetching diaries from API...");
      final List<Diary> fetchedDiaries = await DiaryApi.instance.getRecentDiaries(150);
      _cachedDiaries = fetchedDiaries;
      _initialDiariesFetchAttempted = true;

      final Set<DateTime> daysWithDiaries = {};
      for (var diary in fetchedDiaries) {
        if (diary.createdAt != null) {
          daysWithDiaries.add(DateTime.utc(diary.createdAt!.year, diary.createdAt!.month, diary.createdAt!.day));
        }
      }
      if (mounted) {
        setState(() {
          _daysWithDiaryFromApi = daysWithDiaries;
          _updateWeeklyFlameCount();
          _updateTodaySummaryFromCache();
          print("DashboardScreen: Diaries fetched/updated. Count: ${_cachedDiaries.length}");
        });
      }
    } catch (e, stackTrace) {
      print('DashboardScreen: Error in _fetchDiariesAndUpdateState: ${e.runtimeType} - $e');
      if (e.toString().contains('404') || e.toString().toLowerCase().contains('not found')) {
        if (mounted) {
          setState(() {
            _cachedDiaries = [];
            _daysWithDiaryFromApi = {};
            _weeklyFlameCount = 0;
            _todayDiarySummary = null;
            _initialDiariesFetchAttempted = true;
            print("DashboardScreen: 404 Not Found from API, treated as no diaries.");
          });
        }
      } else {
        snackBarMessageForError = '일기 정보 로드 중 오류가 발생했습니다.';
        if (e.toString().toLowerCase().contains('unauthorized') || e.toString().contains('401')) {
          snackBarMessageForError = '세션이 만료되었거나 인증 오류가 발생했습니다. 다시 로그인해주세요.';
        }
        print('DashboardScreen: Stack trace for non-404 error: $stackTrace');
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

  void _updateTodaySummaryFromCache() {
    Diary? todayDiary;
    final todayDateOnly = DateTime(_today.year, _today.month, _today.day);
    if (_cachedDiaries.isNotEmpty) {
      for (var diary in _cachedDiaries.reversed) {
        if (diary.createdAt != null) {
          final diaryDateOnly = DateTime(diary.createdAt!.year, diary.createdAt!.month, diary.createdAt!.day);
          if (diaryDateOnly.isAtSameMomentAs(todayDateOnly)) {
            todayDiary = diary;
            break;
          }
        }
      }
    }
    if (mounted) {
      setState(() {
        if (todayDiary != null) {
          _todayDiarySummary = todayDiary.summary.isNotEmpty ? todayDiary.summary : (todayDiary.content.length > 50 ? '${todayDiary.content.substring(0, 50)}...' : todayDiary.content);
        } else {
          _todayDiarySummary = null;
        }
      });
    }
  }

  void _updateWeeklyFlameCount() {
    DateTime now = _today;
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - DateTime.monday));
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));
    int count = 0;
    for (DateTime diaryDateUtc in _daysWithDiaryFromApi) {
      DateTime diaryDateOnly = DateTime.utc(diaryDateUtc.year, diaryDateUtc.month, diaryDateUtc.day);
      DateTime startOfWeekOnly = DateTime.utc(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      DateTime endOfWeekOnly = DateTime.utc(endOfWeek.year, endOfWeek.month, endOfWeek.day);
      if (!diaryDateOnly.isBefore(startOfWeekOnly) && !diaryDateOnly.isAfter(endOfWeekOnly)) {
        count++;
      }
    }
    if (mounted) {
      setState(() => _weeklyFlameCount = count);
    }
  }

  PreferredSizeWidget _buildHomeAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(MediaQuery.of(context).padding.top + 60),
      child: _buildHeader(),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFB59A7B),
      padding: EdgeInsets.only(left: 20, right: 20, top: MediaQuery.of(context).padding.top + 10, bottom: 10),
      child: Text.rich(
        TextSpan(children: [
          const TextSpan(text: '나만의 AI Assistance, ', style: TextStyle(color: Colors.white, fontSize: 16)),
          TextSpan(text: 'Qnote', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'NanumMyeongjo')),
        ]), textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildGreetingCard() {
    String title; String subtitle; Widget? actionButton; Color cardColor = Colors.white; IconData? leadingIcon; Color iconColor = Colors.grey.shade700;
    if (!_isUserAuthenticated) { title = 'Qnote에 오신 것을 환영합니다!'; subtitle = '로그인하고 나만의 AI 비서와 함께 하루를 기록해보세요.'; leadingIcon = Icons.login_outlined; iconColor = Theme.of(context).colorScheme.primary; actionButton = ElevatedButton.icon(icon: const Icon(Icons.login, size: 18), label: const Text('로그인 하기'), onPressed: () async { final result = await Navigator.push<bool>(context, MaterialPageRoute(builder: (context) => const LoginScreen())); if (result == true && mounted) await _initializeScreenAndUserData(forceRefresh: true); }, style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))); }
    else if (!_isEmailVerified) { title = '$_userName, 이메일 인증을 완료해주세요 📧'; subtitle = '더욱 안전하고 편리한 서비스 이용을 위해 이메일 인증이 필요합니다. 스팸 메일함도 확인해주세요!'; cardColor = Colors.orange.shade50; leadingIcon = Icons.mark_email_unread_outlined; iconColor = Colors.orange.shade700; actionButton = ElevatedButton.icon(icon: const Icon(Icons.send_to_mobile, size: 18), label: const Text('인증 메일 다시 받기'), onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('인증 메일 재전송 기능은 준비 중입니다.'))), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade600, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))); }
    else if (_initialDiariesFetchAttempted && _cachedDiaries.isEmpty) { title = '$_userName, 첫 일기를 작성해볼까요? ✍️'; subtitle = 'AI 챗봇과 대화하며 오늘 하루를 쉽고 재미있게 기록해보세요!'; cardColor = Colors.blue.shade50; leadingIcon = Icons.edit_calendar_outlined; iconColor = Colors.blue.shade700; actionButton = ElevatedButton.icon(icon: const Icon(Icons.chat_bubble_outline, size: 18), label: const Text('일기 쓰러 가기'), onPressed: () { if (mounted) setState(() => _currentIndex = 2); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade600, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))); }
    else { title = '$_userName, 오늘은 어떤 하루였나요? 😊'; subtitle = '오늘 하루 있었던 일들을 Qnote AI에게 편하게 이야기해주세요.'; leadingIcon = Icons.auto_awesome_outlined; iconColor = Colors.amber.shade800; }
    return Container(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.15), spreadRadius: 1, blurRadius: 8, offset: const Offset(0, 4))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(crossAxisAlignment: CrossAxisAlignment.start, children: [if (leadingIcon != null) ...[Icon(leadingIcon, color: iconColor, size: 28), const SizedBox(width: 12)], Expanded(child: Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.grey.shade800)))]), const SizedBox(height: 8), Padding(padding: EdgeInsets.only(left: leadingIcon != null ? 40.0 : 0), child: Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4))), if (actionButton != null) ...[const SizedBox(height: 16), Align(alignment: Alignment.centerRight, child: actionButton)]]));
  }

  void _handleCalendarDateTap(DateTapDetails details) {
    _removeDiarySnippetOverlay(); if (details.hasEvent) { Diary? tappedDiary; for (var diary in _cachedDiaries) { if (diary.createdAt != null && _isSameDay(diary.createdAt!, details.date)) { tappedDiary = diary; break; } } if (tappedDiary != null) { String snippet = tappedDiary.summary.isNotEmpty ? tappedDiary.summary : (tappedDiary.content.length > 50 ? '${tappedDiary.content.substring(0, 50)}...' : tappedDiary.content); if (snippet.isNotEmpty) { final RenderBox? calendarBox = _calendarWidgetKey.currentContext?.findRenderObject() as RenderBox?; Offset overlayPosition; if (calendarBox != null && calendarBox.attached) { final calendarPosition = calendarBox.localToGlobal(Offset.zero); double overlayHeight = 60; overlayPosition = Offset(calendarPosition.dx + (calendarBox.size.width / 2) - 75, calendarPosition.dy - overlayHeight - 10); final screenWidth = MediaQuery.of(context).size.width; final screenHeight = MediaQuery.of(context).size.height; final appBar = Scaffold.maybeOf(context)?.appBarMaxHeight; final appBarHeight = appBar ?? kToolbarHeight; final statusBarHeight = MediaQuery.of(context).padding.top; overlayPosition = Offset( overlayPosition.dx.clamp(10.0, screenWidth - 150 - 10.0), overlayPosition.dy.clamp(statusBarHeight + appBarHeight + 10.0, screenHeight - overlayHeight - MediaQuery.of(context).padding.bottom - 10.0) ); } else { overlayPosition = Offset(MediaQuery.of(context).size.width / 2 - 75, MediaQuery.of(context).size.height / 3); } _showDiarySnippetOverlay(overlayPosition, snippet); } } }
  }
  void _showDiarySnippetOverlay(Offset position, String snippetText) { _removeDiarySnippetOverlay(); _snippetOverlayTimer?.cancel(); _diarySnippetOverlayEntry = OverlayEntry(builder: (context) => Positioned(left: position.dx, top: position.dy, child: IgnorePointer(child: Material(elevation: 4.0, borderRadius: BorderRadius.circular(8.0), color: Colors.transparent, child: Container(width: 150, padding: const EdgeInsets.all(10.0), decoration: BoxDecoration(color: Colors.black.withOpacity(0.8), borderRadius: BorderRadius.circular(8.0)), child: Text(snippetText, style: const TextStyle(color: Colors.white, fontSize: 13), textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis)))))); if (mounted) { Overlay.of(context).insert(_diarySnippetOverlayEntry!); _snippetOverlayTimer = Timer(const Duration(seconds: 3), _removeDiarySnippetOverlay); } }
  void _removeDiarySnippetOverlay() { _snippetOverlayTimer?.cancel(); if (_diarySnippetOverlayEntry != null) { if (_diarySnippetOverlayEntry!.mounted) _diarySnippetOverlayEntry!.remove(); _diarySnippetOverlayEntry = null; } }
  bool _isSameDay(DateTime a, DateTime b) { return a.year == b.year && a.month == b.month && a.day == b.day; }

  Widget _buildHomeScreenBody() {
    Widget content;
    if (!_isUserAuthenticated) {
      content = Column(children: [_buildGreetingCard(), Expanded(child: Center(child: Text("로그인 후 이용해주세요.")))]);
    } else if (!_initialDiariesFetchAttempted || (_isLoadingDiaries && !_initialDiariesFetchAttempted) ) {
      content = Column(children: [
        _buildGreetingCard(),
        Expanded(child: SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(padding: const EdgeInsets.only(top: 0, bottom: 16),
                  child: Text('일기 정보를 불러오는 중입니다...', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87))),
              Container(key: _calendarWidgetKey,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.grey.withAlpha(80), blurRadius: 10, offset: Offset(0,1))]),
                  padding: const EdgeInsets.only(bottom:8),
                  child: CalendarWidget(
                    focusedDayForCalendar: _focusedDayForCalendar, today: _today, daysWithDiary: _daysWithDiaryFromApi,
                    onDateTap: _handleCalendarDateTap,
                    onPageChanged: (newFocusedPageDate) { if (mounted) { if (!_isSameDay(_focusedDayForCalendar, newFocusedPageDate) || _focusedDayForCalendar.month != newFocusedPageDate.month) { setState(() => _focusedDayForCalendar = newFocusedPageDate); } } },
                  )
              ),
              const SizedBox(height: 24),
              Container(
                  width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.grey.withAlpha(80), spreadRadius: 0.5, blurRadius: 10, offset: Offset(0,1))]),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('오늘의 일기 요약', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87)), const SizedBox(height: 12),
                    Text('요약 정보를 불러오는 중...', style: TextStyle(fontSize: 15, height: 1.5, color: Colors.grey))
                  ])),
              const SizedBox(height: 24)
            ]))),
      ]);
    } else if (_initialDiariesFetchAttempted && _cachedDiaries.isEmpty) {
      content = Column(children: [
        _buildGreetingCard(),
        Expanded(child: SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(padding: const EdgeInsets.only(top: 0, bottom: 16),
                  child: Text('이번 주에 아직 작성된 일기가 없어요.', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87))),
              Container(key: _calendarWidgetKey,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.grey.withAlpha(80), blurRadius: 10, offset: Offset(0,1))]),
                  padding: const EdgeInsets.only(bottom:8),
                  child: CalendarWidget(
                    focusedDayForCalendar: _focusedDayForCalendar, today: _today, daysWithDiary: _daysWithDiaryFromApi,
                    onDateTap: _handleCalendarDateTap,
                    onPageChanged: (newFocusedPageDate) { if (mounted) { if (!_isSameDay(_focusedDayForCalendar, newFocusedPageDate) || _focusedDayForCalendar.month != newFocusedPageDate.month) { setState(() => _focusedDayForCalendar = newFocusedPageDate); } } },
                  )
              ),
              const SizedBox(height: 24),
              Container(
                  width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.grey.withAlpha(80), spreadRadius: 0.5, blurRadius: 10, offset: Offset(0,1))]),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('오늘의 일기 요약', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87)), const SizedBox(height: 12),
                    Text('오늘 작성된 일기가 없어요. AI챗봇과 대화하며 하루를 기록해보세요!', style: TextStyle(fontSize: 15, height: 1.5, color: Colors.grey))
                  ])),
              const SizedBox(height: 24)
            ]))),
      ],
      );
    } else {
      content = Column(children: [
        _buildGreetingCard(),
        Expanded(child: SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(padding: const EdgeInsets.only(top: 0, bottom: 16),
                  child: Text(
                      _weeklyFlameCount > 0 ? '이번 주에 총 $_weeklyFlameCount개의 일기를 작성했어요! 🔥' : '이번 주에 아직 작성된 일기가 없네요.',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87))),
              Container(key: _calendarWidgetKey,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.grey.withAlpha(80), blurRadius: 10, offset: Offset(0,1))]),
                  padding: const EdgeInsets.only(bottom:8),
                  child: CalendarWidget(
                    focusedDayForCalendar: _focusedDayForCalendar, today: _today, daysWithDiary: _daysWithDiaryFromApi,
                    onDateTap: _handleCalendarDateTap,
                    onPageChanged: (newFocusedPageDate) { if (mounted) { if (!_isSameDay(_focusedDayForCalendar, newFocusedPageDate) || _focusedDayForCalendar.month != newFocusedPageDate.month) { setState(() => _focusedDayForCalendar = newFocusedPageDate); } } },
                  )
              ),
              const SizedBox(height: 24),
              Container(
                  width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.grey.withAlpha(80), spreadRadius: 0.5, blurRadius: 10, offset: Offset(0,1))]),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('오늘의 일기 요약', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87)), const SizedBox(height: 12),
                    Text(
                        _todayDiarySummary ?? '오늘 작성된 일기가 없어요.',
                        style: TextStyle(fontSize: 15, height: 1.5, color: _todayDiarySummary != null ? Colors.black54 : Colors.grey),
                        maxLines: 3, overflow: TextOverflow.ellipsis)])),
              const SizedBox(height: 24)
            ]))),
      ]);
    }
    return RefreshIndicator(
        onRefresh: () => _initializeScreenAndUserData(forceRefresh: true),
        child: content
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPage && _currentIndex == 0 && !_initialDiariesFetchAttempted) {
      return const Scaffold(backgroundColor: Color(0xFFF4F6F8), body: Center(child: CircularProgressIndicator(key: ValueKey("full_page_loading_dashboard"))));
    }

    final List<Widget> currentTabScreens = [
      _buildHomeScreenBody(), const SearchScreen(), const ChatScreen(), const ScheduleScreen(), const ProfileScreen()];

    PreferredSizeWidget? currentAppBar;
    switch (_currentIndex) {
      case 0: case 1: case 4: currentAppBar = _buildHomeAppBar(); break;
      case 2: case 3: currentAppBar = null; break;
      default: currentAppBar = _buildHomeAppBar();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: currentAppBar,
      body: IndexedStack(index: _currentIndex, children: currentTabScreens),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white, type: BottomNavigationBarType.fixed, currentIndex: _currentIndex,
        selectedItemColor: Colors.black, unselectedItemColor: Colors.grey.shade500,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        onTap: (idx) async {
          if (!mounted) return;
          bool needsRefreshForHome = false;
          if (idx == 0 && _currentIndex == 0) { needsRefreshForHome = true; }
          else if (idx == 0 && _currentIndex != 0) { needsRefreshForHome = true; }

          if (mounted) setState(() => _currentIndex = idx);

          if (needsRefreshForHome) {
            await _initializeScreenAndUserData(forceRefresh: true);
          } else if (idx != 0 && !_isUserAuthenticated) {
            String featureName = '';
            switch (idx) { case 1: featureName = '검색 기능'; break; case 2: featureName = 'AI 채팅 기능'; break; case 3: featureName = '일정 기능'; break; case 4: featureName = '프로필 화면'; break; }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$featureName을(를) 이용하려면 로그인이 필요합니다.')));
              final loginSuccess = await Navigator.push<bool>(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
              if (loginSuccess == true && mounted) {
                await _initializeScreenAndUserData(forceRefresh: true);
                if (_isUserAuthenticated && idx != 0) { if (mounted) setState(() => _currentIndex = idx); }
                else { if (mounted) setState(() => _currentIndex = 0); }
              } else { if (mounted) setState(() => _currentIndex = 0); }
            }
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: '검색'),
          BottomNavigationBarItem(icon: CircleAvatar(backgroundColor: Color(0xFFB59A7B), child: Icon(Icons.chat_bubble_outline, color: Colors.white, size: 26)), label: 'AI 채팅'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: '일정'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: '프로필')
        ],
      ),
    );
  }
}
