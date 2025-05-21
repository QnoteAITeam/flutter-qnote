// lib/features/dashboard/dashboard_screen.dart
import 'dart:async';
import 'dart:io'; // SocketException, TimeoutException 사용

import 'package:flutter/material.dart';
import 'package:flutter_qnote/api/diary_api.dart';
import 'package:flutter_qnote/models/diary.dart';
import 'package:flutter_qnote/widgets/calendar_widget.dart'; // CalendarWidget 경로 확인
import 'package:flutter_qnote/features/search/search_screen.dart'; // SearchScreen 경로 확인
import 'package:flutter_qnote/features/chat/chat_screen.dart';     // ChatScreen 경로 확인
import 'package:flutter_qnote/auth/auth_api.dart';                 // AuthApi 경로 확인
import 'package:flutter_qnote/features/login/login_screen.dart';   // LoginScreen 경로 확인
import 'package:flutter_qnote/features/profile/profile_screen.dart'; // ProfileScreen 경로 확인
import 'package:flutter_qnote/features/schedule/schedule_screen.dart'; // ScheduleScreen 경로 확인
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  int _weeklyFlameCount = 0;
  int _currentIndex = 0; // 현재 선택된 탭 인덱스
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
    WidgetsBinding.instance.addObserver(this); // 앱 생명주기 변경 감지 등록
    _focusedDayForCalendar = _today; // 캘린더 초기 포커스 날짜 설정
    _initializeScreenAndUserData(); // 화면 및 사용자 데이터 초기화
  }

  // 사용자 데이터 가져오기 (예시: API 호출 또는 로컬 저장소)
  Future<Map<String, dynamic>> _fetchUserData() async {
    if (_isUserAuthenticated) { // 사용자가 인증된 경우에만 실제 데이터 가져오기 시도
      await Future.delayed(const Duration(milliseconds: 50)); // API 호출 시뮬레이션 지연
      // 실제 API 호출: return await AuthApi.instance.getUserProfileData();
      return {"userName": "홍길동님", "isEmailVerified": true}; // 성공 시 사용자 데이터 반환
    }
    return {"userName": "방문자", "isEmailVerified": false}; // 비인증 시 기본값 반환
  }

  // 화면 및 사용자 데이터 초기화 함수
  Future<void> _initializeScreenAndUserData({bool forceRefresh = false}) async {
    if (!mounted) return; // 위젯이 마운트되지 않았으면 아무것도 하지 않음

    // 중복 실행 방지: 이미 로딩 중이 아니고, 강제 새로고침이 아니며, 사용자가 인증되었고, 초기 다이어리 로드를 이미 시도했다면 반환
    if (!forceRefresh && !_isLoadingPage && _isUserAuthenticated && _initialDiariesFetchAttempted) {
      return;
    }
    setState(() => _isLoadingPage = true); // 페이지 로딩 시작

    bool isLoggedIn = false;
    try {
      // 인증 API를 통해 현재 로그인 상태 확인
      String? accessTokenHeader = await AuthApi.getInstance.getAccessTokenHeader();
      isLoggedIn = accessTokenHeader != null && accessTokenHeader.isNotEmpty;
    } catch (e) {
      print("Error checking auth status in Dashboard: $e"); // 오류 발생 시 로그 출력
      isLoggedIn = false; // 오류 시 로그인 안 된 것으로 간주
    }

    if (mounted) {
      _isUserAuthenticated = isLoggedIn; // 실제 인증 상태를 멤버 변수에 반영

      Map<String, dynamic> userData = await _fetchUserData(); // 사용자 정보 가져오기
      String newUserName = userData['userName'] as String;
      bool newIsEmailVerified = userData['isEmailVerified'] as bool;

      setState(() {
        _userName = newUserName; // 사용자 이름 업데이트
        _isEmailVerified = newIsEmailVerified; // 이메일 인증 상태 업데이트
        _isLoadingPage = false; // 사용자 기본 정보 설정 후 페이지 로딩 완료

        // 로그인 상태가 아니라면 관련 데이터 초기화
        if (!isLoggedIn) {
          _weeklyFlameCount = 0;
          _daysWithDiaryFromApi = {};
          _cachedDiaries = [];
          _todayDiarySummary = null;
          _initialDiariesFetchAttempted = false; // 다시 로드할 수 있도록 false로 설정
        }
      });

      // 로그인 상태이고 (강제 새로고침이거나 아직 초기 다이어리 로드를 시도하지 않았다면) 다이어리 로드
      if (isLoggedIn && (forceRefresh || !_initialDiariesFetchAttempted)) {
        WidgetsBinding.instance.addPostFrameCallback((_) { // 현재 프레임 완료 후 실행
          if (mounted && _isUserAuthenticated) { // 콜백 실행 시점에도 mounted 및 인증 상태 재확인
            _tryFetchInitialDiaries(forceRefresh: forceRefresh, isInitialLoadOverride: true);
          }
        });
      }
    }
  }

  // 초기 다이어리 데이터 로드 시도
  Future<void> _tryFetchInitialDiaries({bool forceRefresh = false, bool isInitialLoadOverride = false}) async {
    if (!mounted || !_isUserAuthenticated) return; // 유효성 검사

    bool actualInitialLoad = isInitialLoadOverride || !_initialDiariesFetchAttempted;

    // 이미 초기 로드를 시도했고, 강제 새로고침이 아니며, 실제 초기 로드가 아니라면 중복 실행 방지
    if (_initialDiariesFetchAttempted && !forceRefresh && !actualInitialLoad) {
      return;
    }
    // 다이어리 데이터 가져오기 및 상태 업데이트
    await _fetchDiariesAndUpdateState(_focusedDayForCalendar, isInitialLoad: actualInitialLoad);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // 앱 생명주기 감지 해제
    _removeDiarySnippetOverlay(); // 오버레이 제거
    _snippetOverlayTimer?.cancel(); // 타이머 취소
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 앱이 다시 활성화될 때 (예: 다른 앱에서 돌아왔을 때) 데이터 새로고침
    if (state == AppLifecycleState.resumed && mounted) {
      _initializeScreenAndUserData(forceRefresh: true); // 인증 상태 및 데이터 강제 새로고침
    }
  }

  // 로그인 상태일 때 대시보드 데이터 새로고침
  Future<void> _refreshDashboardDataIfLoggedIn() async {
    if (!mounted || !_isUserAuthenticated) return;
    // 현재 focus된 날짜 기준으로 다이어리 데이터 새로고침 (초기 로드는 아님)
    await _fetchDiariesAndUpdateState(_focusedDayForCalendar, isInitialLoad: false);
  }

  // API를 통해 다이어리 데이터를 가져오고 상태를 업데이트하는 함수
  Future<void> _fetchDiariesAndUpdateState(DateTime referenceDateForView, {bool isInitialLoad = false}) async {
    if (!mounted || !_isUserAuthenticated) return; // 로그인 상태가 아니면 실행 안 함
    setState(() => _isLoadingDiaries = true); // 다이어리 로딩 시작
    String? snackBarMessage; // 오류 발생 시 표시할 메시지

    try {
      // DiaryApi를 통해 최근 150일치 일기 데이터를 가져옵니다. (기간은 필요에 따라 조절)
      final List<Diary> fetchedDiaries = await DiaryApi.instance.getRecentDiaries(150);
      _cachedDiaries = fetchedDiaries; // 가져온 다이어리를 캐시에 저장

      // 일기가 있는 날짜들을 Set에 저장 (캘린더에 표시하기 위함, 중복 방지 및 빠른 조회)
      final Set<DateTime> daysWithDiaries = {};
      for (var diary in fetchedDiaries) {
        // 시간 정보를 제외하고 날짜만 UTC로 저장하여 일관성 유지
        daysWithDiaries.add(DateTime.utc(diary.createdAt.year, diary.createdAt.month, diary.createdAt.day));
      }

      if (mounted) { // 위젯이 화면에 있을 때만 상태 업데이트
        setState(() {
          _daysWithDiaryFromApi = daysWithDiaries; // API에서 가져온 일기 있는 날짜들 업데이트
          _updateWeeklyFlameCount(); // 주간 일기 작성 수 업데이트
          _updateTodaySummaryFromCache(); // 오늘의 일기 요약 업데이트
          if (isInitialLoad) _initialDiariesFetchAttempted = true; // 초기 로드 시도 완료 플래그 설정
        });
      }
    } catch (e, stackTrace) { // 오류 처리
      print('Error in _fetchDiariesAndUpdateState: ${e.runtimeType} - $e'); // 콘솔에 오류 타입과 메시지 출력
      print('Stack trace: $stackTrace'); // 디버깅을 위해 스택 트레이스 출력
      String errorString = e.toString();

      if (e is SocketException) { // 네트워크 연결 오류
        snackBarMessage = '네트워크 연결을 확인해주세요.';
      } else if (e is TimeoutException) { // 서버 응답 시간 초과
        snackBarMessage = '서버 응답 시간이 초과되었습니다.';
      } else if (errorString.toLowerCase().contains('unauthorized') || errorString.contains('401')) { // 인증 오류 (401)
        snackBarMessage = '세션이 만료되었거나 인증 오류가 발생했습니다. 다시 로그인해주세요.';
        if (mounted) {
          // 로그인 화면으로 이동하고 이전 화면 스택 모두 제거
          await Navigator.pushAndRemoveUntil<bool>(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false, // 모든 이전 라우트를 false로 만들어 제거
          );
          // 로그인 화면에서 돌아온 후 대시보드 데이터 다시 초기화 (인증 상태 포함)
          if (mounted) await _initializeScreenAndUserData(forceRefresh: true);
          return; // 추가 진행 방지
        }
      } else { // 기타 서버 또는 알 수 없는 오류
        snackBarMessage = '일기 정보 로드 중 오류가 발생했습니다.';
      }
    } finally { // API 호출 성공/실패 여부와 관계없이 항상 실행
      if (mounted) {
        setState(() => _isLoadingDiaries = false); // 다이어리 로딩 상태 해제
        // 스낵바 메시지가 있고, 위젯이 화면에 있으며, 현재 라우트가 활성 상태일 때만 스낵바 표시
        if (snackBarMessage != null && mounted && ModalRoute.of(context)!.isCurrent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(snackBarMessage), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  // 캐시된 다이어리에서 오늘의 일기 요약 업데이트
  void _updateTodaySummaryFromCache() {
    Diary? todayDiary;
    final todayDateOnly = DateTime(_today.year, _today.month, _today.day); // 오늘 날짜 (시간 정보 제외)

    if (_cachedDiaries.isNotEmpty) { // 캐시된 일기가 있을 경우
      // 최신 일기부터 확인하여 오늘 날짜의 일기를 찾음
      for (var diary in _cachedDiaries.reversed) { // reversed()로 최신 일기부터 순회
        final diaryDateOnly = DateTime(diary.createdAt.year, diary.createdAt.month, diary.createdAt.day);
        if (diaryDateOnly.isAtSameMomentAs(todayDateOnly)) { // 날짜만 비교
          todayDiary = diary;
          break; // 찾으면 반복 중단
        }
      }
    }

    if (mounted) { // 위젯이 화면에 있을 때만 상태 업데이트
      setState(() {
        if (todayDiary != null) {
          // 요약 정보가 있으면 요약을 사용하고, 없으면 내용의 앞부분을 잘라서 사용
          _todayDiarySummary = todayDiary.summary.isNotEmpty
              ? todayDiary.summary
              : (todayDiary.content.length > 30 ? '${todayDiary.content.substring(0, 30)}...' : todayDiary.content);
        } else {
          _todayDiarySummary = null; // 오늘 작성된 일기가 없으면 null
        }
      });
    }
  }

  // 주간 일기 작성 수 업데이트
  void _updateWeeklyFlameCount() {
    DateTime now = _today;
    // 이번 주의 시작일(월요일)과 종료일(일요일) 계산
    // weekday는 월요일(1) ~ 일요일(7)
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - DateTime.monday));
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 6)); // 월요일부터 6일 뒤는 일요일

    int count = 0;
    for (DateTime diaryDateUtc in _daysWithDiaryFromApi) {
      // UTC 날짜를 로컬 시간대 없이 날짜만 비교하여 주간 범위에 포함되는지 확인
      DateTime diaryDateOnly = DateTime.utc(diaryDateUtc.year, diaryDateUtc.month, diaryDateUtc.day);
      DateTime startOfWeekOnly = DateTime.utc(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      DateTime endOfWeekOnly = DateTime.utc(endOfWeek.year, endOfWeek.month, endOfWeek.day);

      // diaryDateOnly가 startOfWeekOnly 이후이고 endOfWeekOnly 이전인지 확인
      if (!diaryDateOnly.isBefore(startOfWeekOnly) && !diaryDateOnly.isAfter(endOfWeekOnly)) {
        count++;
      }
    }
    if (mounted) {
      setState(() => _weeklyFlameCount = count); // 계산된 주간 일기 수로 상태 업데이트
    }
  }

  // 새 일기가 저장되었을 때 호출될 함수
  void _handleNewDiarySaved(Diary savedDiary) {
    if (!mounted) return;
    _refreshDashboardDataIfLoggedIn(); // 대시보드 데이터 새로고침하여 변경사항 반영
  }

  // 홈 탭(인덱스 0) 및 프로필 탭(인덱스 4), 검색 탭(인덱스 1)의 AppBar ("나만의 AI Assistance, Qnote" 헤더)
  PreferredSizeWidget _buildHomeAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 10), // _buildHeader의 실제 높이 + 약간의 여유
      child: _buildHeader(),
    );
  }

  // 특정 탭에서 사용할 수 있는 간단한 AppBar (현재는 검색 탭에서 _buildHomeAppBar로 대체됨)
  AppBar _buildSimpleAppBar(String title) {
    return AppBar(
      title: Text(title, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      backgroundColor: Colors.white,
      elevation: 0.5, // 약간의 그림자 효과
      centerTitle: true,
      automaticallyImplyLeading: false, // 뒤로가기 버튼 자동 생성 안 함
    );
  }

  // 홈 탭(인덱스 0)에 표시될 내용 (인사말 카드, 달력, 일기 요약 등)
  Widget _buildHomeScreenBody() {
    return Column(
      children: [
        // 홈 탭에서는 인사말 카드가 AppBar 바로 아래에 위치
        _buildGreetingCard(),
        Expanded(
          child: SingleChildScrollView( // 내용이 길어질 경우 스크롤 가능하도록
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding( // 주간 일기 작성 수 안내 메시지
                  padding: const EdgeInsets.only(top: 0, bottom: 16), // 위쪽 패딩 제거
                  child: Text(
                    !_isUserAuthenticated
                        ? '로그인 후 Qnote의 모든 기능을 이용해보세요!' // 비로그인 시
                        : (_initialDiariesFetchAttempted // 초기 데이터 로드 시도 후
                        ? (_weeklyFlameCount > 0
                        ? '이번 주에 총 $_weeklyFlameCount개의 일기를 작성했어요! 🎉' // 주간 일기 있을 때
                        : (_isEmailVerified
                        ? '이번 주에 아직 작성된 일기가 없어요. 첫 일기를 남겨보세요!' // 이메일 인증 & 주간 일기 없을 때
                        : '이메일 인증 후 일기를 작성할 수 있어요.')) // 이메일 미인증 시
                        : '일기 정보를 불러오는 중입니다...'), // 초기 데이터 로드 중
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
                if (_isUserAuthenticated) ...[ // 로그인 상태일 때만 달력 및 요약 표시
                  if (_isLoadingDiaries && _cachedDiaries.isEmpty && !_initialDiariesFetchAttempted) // 다이어리 로딩 중
                    const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 50.0), child: CircularProgressIndicator()))
                  else // 로딩 완료 또는 데이터 있을 때
                    Container(
                      key: _calendarWidgetKey, // 캘린더 위젯에 GlobalKey 할당 (오버레이 위치 계산용)
                      child: CalendarWidget(
                        focusedDayForCalendar: _focusedDayForCalendar, // 현재 포커스된 날짜
                        today: _today, // 오늘 날짜
                        daysWithDiary: _daysWithDiaryFromApi, // 일기가 있는 날짜들
                        onDateTap: _handleCalendarDateTap, // 날짜 탭 이벤트 핸들러
                        onPageChanged: (newFocusedPageDate) { // 캘린더 페이지(월) 변경 시
                          if (mounted) {
                            // 포커스된 날짜가 실제 변경되었거나 월이 변경된 경우에만 상태 업데이트 및 데이터 새로고침
                            if (!_isSameDay(_focusedDayForCalendar, newFocusedPageDate) || _focusedDayForCalendar.month != newFocusedPageDate.month) {
                              setState(() {
                                _focusedDayForCalendar = newFocusedPageDate;
                              });
                              _refreshDashboardDataIfLoggedIn(); // 새 달의 일기 데이터 로드
                            }
                          }
                        },
                      ),
                    ),
                  const SizedBox(height: 24),
                  Container( // 오늘의 일기 요약 카드
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.grey.withAlpha((0.15 * 255).round()), spreadRadius: 1, blurRadius: 5, offset: const Offset(0, 2))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('오늘의 일기 요약', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87)),
                        const SizedBox(height: 12),
                        Text(
                          _todayDiarySummary ?? (_initialDiariesFetchAttempted
                              ? '오늘 작성된 일기가 없어요. AI챗봇과 대화하며 하루를 기록해보세요!'
                              : (_isLoadingDiaries ? '요약 정보를 불러오는 중...' : '일기 정보를 불러와주세요.')),
                          style: TextStyle(fontSize: 15, height: 1.5, color: _todayDiarySummary != null ? Colors.black54 : Colors.grey),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ] else ...[ // 비로그인 시 표시할 내용
                  Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 50),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.note_alt_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text('로그인 후 캘린더와 일기 요약을 이용할 수 있습니다.', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24), // 하단 여백
              ],
            ),
          ),
        ),
      ],
    );
  }

  // "나만의 AI Assistance, Qnote" 갈색 헤더 위젯 (홈, 검색, 프로필 탭에서 사용)
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFB59A7B), // 갈색 배경
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18), // 내부 패딩
      child: SafeArea( // 상태 표시줄 영역을 피하도록 SafeArea 적용
        bottom: false, // 하단 SafeArea는 필요 없음 (AppBar이므로)
        child: Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: '나만의 AI Assistance, ', style: TextStyle(color: Colors.white, fontSize: 16)),
              TextSpan(
                text: 'Qnote',
                style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'NanumMyeongjo'), // 폰트 적용
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // 사용자 상태에 따른 인사말 카드 위젯 (홈 탭 전용)
  Widget _buildGreetingCard() {
    String title;
    String subtitle;
    Widget? actionButton;
    Color cardColor = Colors.white;
    IconData? leadingIcon;
    Color iconColor = Colors.grey.shade700;

    if (!_isUserAuthenticated) { // 비로그인 시
      title = 'Qnote에 오신 것을 환영합니다!';
      subtitle = '로그인하고 나만의 AI 비서와 함께 하루를 기록해보세요.';
      leadingIcon = Icons.login_outlined;
      iconColor = Theme.of(context).colorScheme.primary; // 테마 기본 색상 사용
      actionButton = ElevatedButton.icon(
        icon: const Icon(Icons.login, size: 18),
        label: const Text('로그인 하기'),
        onPressed: () async {
          // 로그인 화면으로 이동하고 결과(로그인 성공 여부)를 받음
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
          // 로그인 성공 시 (true 반환) 대시보드 데이터 새로고침
          if (result == true && mounted) {
            await _initializeScreenAndUserData(forceRefresh: true);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      );
    } else if (!_isEmailVerified) { // 이메일 미인증 시
      title = '$_userName, 이메일 인증을 완료해주세요 📧';
      subtitle = '더욱 안전하고 편리한 서비스 이용을 위해 이메일 인증이 필요합니다. 스팸 메일함도 확인해주세요!';
      cardColor = Colors.orange.shade50; // 카드 배경색
      leadingIcon = Icons.mark_email_unread_outlined;
      iconColor = Colors.orange.shade700;
      actionButton = ElevatedButton.icon(
        icon: const Icon(Icons.send_to_mobile, size: 18),
        label: const Text('인증 메일 다시 받기'),
        onPressed: () {
          // TODO: 인증 메일 재전송 API 호출
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('인증 메일 재전송 기능은 준비 중입니다.')),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      );
    } else if (_initialDiariesFetchAttempted && _weeklyFlameCount == 0) { // 로그인 & 이메일 인증 & 이번 주 일기 없음
      title = '$_userName, 이번 주 첫 일기를 작성해볼까요? ✍️';
      subtitle = 'AI 챗봇과 대화하며 오늘 하루를 쉽고 재미있게 기록해보세요!';
      cardColor = Colors.blue.shade50;
      leadingIcon = Icons.edit_calendar_outlined;
      iconColor = Colors.blue.shade700;
      actionButton = ElevatedButton.icon(
        icon: const Icon(Icons.chat_bubble_outline, size: 18),
        label: const Text('일기 쓰러 가기'),
        onPressed: () {
          if (mounted) setState(() => _currentIndex = 2); // AI 채팅 탭(인덱스 2)으로 이동
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      );
    } else { // 일반적인 로그인 상태
      title = '$_userName, 오늘은 어떤 하루였나요? 😊';
      subtitle = '오늘 하루 있었던 일들을 Qnote AI에게 편하게 이야기해주세요.';
      leadingIcon = Icons.auto_awesome_outlined; // 구글 AI 아이콘 느낌
      iconColor = Colors.amber.shade800;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4), // 아래쪽 그림자
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leadingIcon != null) ...[
                Icon(leadingIcon, color: iconColor, size: 28),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.only(left: leadingIcon != null ? 40.0 : 0), // 아이콘 있을 때만 들여쓰기
            child: Text(
              subtitle,
              style: TextStyle(
                  fontSize: 14, color: Colors.grey.shade600, height: 1.4),
            ),
          ),
          if (actionButton != null) ...[
            const SizedBox(height: 16),
            Align( // 버튼을 오른쪽으로 정렬
              alignment: Alignment.centerRight,
              child: actionButton,
            )
          ]
        ],
      ),
    );
  }

  // 캘린더 날짜 탭 시 일기 미리보기 오버레이 표시
  void _handleCalendarDateTap(DateTapDetails details) {
    _removeDiarySnippetOverlay(); // 기존 오버레이 제거
    if (details.hasEvent) { // 해당 날짜에 일기가 있으면
      Diary? tappedDiary;
      // 캐시된 일기에서 해당 날짜의 일기 찾기
      for (var diary in _cachedDiaries) {
        if (_isSameDay(diary.createdAt, details.date)) {
          tappedDiary = diary;
          break;
        }
      }
      if (tappedDiary != null) {
        // 표시할 스니펫 텍스트 준비
        String snippet = tappedDiary.summary.isNotEmpty
            ? tappedDiary.summary
            : (tappedDiary.content.length > 50 ? '${tappedDiary.content.substring(0, 50)}...' : tappedDiary.content);
        if (snippet.isNotEmpty) {
          // 캘린더 위젯의 위치를 기준으로 오버레이 위치 계산
          final RenderBox? calendarBox = _calendarWidgetKey.currentContext?.findRenderObject() as RenderBox?;
          Offset overlayPosition;
          if (calendarBox != null && calendarBox.attached) {
            final calendarPosition = calendarBox.localToGlobal(Offset.zero);
            double overlayHeight = 60; // 오버레이 높이 (대략)
            // 캘린더 상단 또는 화면 상단에 적절히 위치하도록 조정
            overlayPosition = Offset(
                calendarPosition.dx + (calendarBox.size.width / 2) - 75, // 가로 중앙 정렬 (너비 150 가정)
                calendarPosition.dy - overlayHeight - 10 // 캘린더 위쪽
            );
            // 오버레이가 화면 상단을 넘어가지 않도록 위치 조정
            if (overlayPosition.dy < MediaQuery.of(context).padding.top + kToolbarHeight + 10) {
              overlayPosition = Offset(overlayPosition.dx, MediaQuery.of(context).padding.top + kToolbarHeight + 10);
            }
          } else { // 캘린더 위치를 알 수 없을 경우 화면 중앙 부근에 표시
            overlayPosition = Offset(MediaQuery.of(context).size.width / 2 - 75, MediaQuery.of(context).size.height / 3);
          }
          _showDiarySnippetOverlay(overlayPosition, snippet);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${DateFormat.Md('ko_KR').format(details.date)}의 일기 정보가 캐시에 없습니다.')),
        );
      }
    }
  }

  // 일기 스니펫 오버레이 표시
  void _showDiarySnippetOverlay(Offset position, String snippetText) {
    _removeDiarySnippetOverlay(); // 기존 오버레이 제거
    _snippetOverlayTimer?.cancel(); // 이전 타이머 취소

    _diarySnippetOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx.clamp(0, MediaQuery.of(context).size.width - 150), // 화면 벗어나지 않도록
        top: position.dy,
        child: IgnorePointer( // 오버레이 터치 이벤트 무시
          child: Material( // 그림자 효과 등을 위해 Material 위젯 사용
            elevation: 4.0,
            borderRadius: BorderRadius.circular(8.0),
            color: Colors.transparent, // Material 자체 배경은 투명
            child: Container(
              width: 150, // 오버레이 너비
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8), // 반투명 검정 배경
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                snippetText,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );

    if (mounted) {
      Overlay.of(context).insert(_diarySnippetOverlayEntry!);
      // 3초 후 자동으로 오버레이 제거
      _snippetOverlayTimer = Timer(const Duration(seconds: 3), _removeDiarySnippetOverlay);
    }
  }

  // 일기 스니펫 오버레이 제거
  void _removeDiarySnippetOverlay() {
    _snippetOverlayTimer?.cancel();
    if (_diarySnippetOverlayEntry != null) {
      if (_diarySnippetOverlayEntry!.mounted) { // 오버레이가 아직 화면에 있는지 확인
        _diarySnippetOverlayEntry!.remove();
      }
      _diarySnippetOverlayEntry = null;
    }
  }

  // 두 날짜가 같은 날인지 비교 (시간 무시)
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPage) { // 페이지 전체 로딩 중이면 로딩 인디케이터 표시
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 각 탭에 해당하는 화면 위젯 리스트
    // ChatScreen, ScheduleScreen, ProfileScreen은 각자 Scaffold/AppBar를 관리하거나,
    // DashboardScreen의 AppBar를 사용하지 않도록 설정됨.
    final List<Widget> currentTabScreens = [
      _buildHomeScreenBody(),   // Index 0: 홈
      const SearchScreen(),     // Index 1: 검색 (Dashboard의 AppBar 사용)
      const ChatScreen(),       // Index 2: AI 채팅 (자체 Scaffold/AppBar를 가짐)
      const ScheduleScreen(),   // Index 3: 일정 (자체 Scaffold/헤더를 가짐)
      const ProfileScreen(),    // Index 4: 프로필 (Dashboard의 AppBar 사용)
    ];

    PreferredSizeWidget? currentAppBar;
    // 현재 선택된 탭에 따라 AppBar 동적 설정
    switch (_currentIndex) {
      case 0: // 홈 탭
        currentAppBar = _buildHomeAppBar(); // "나만의 AI Assistance, Qnote" 헤더
        break;
      case 1: // 검색 탭
        currentAppBar = _buildHomeAppBar(); // "나만의 AI Assistance, Qnote" 헤더 표시 (UI 변경 요청에 따름)
        break;
      case 2: // AI 채팅 탭
        currentAppBar = null; // ChatScreen이 자체 AppBar를 사용하므로 DashboardScreen의 AppBar는 null
        break;
      case 3: // 일정 탭
        currentAppBar = null; // ScheduleScreen이 자체 헤더(AppBar 역할)를 사용하므로 null
        break;
      case 4: // 프로필 탭
        currentAppBar = _buildHomeAppBar(); // "나만의 AI Assistance, Qnote" 헤더 표시
        break;
      default: // 기본값 (보통 홈 탭)
        currentAppBar = _buildHomeAppBar();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8), // 탭 화면들의 기본 배경색
      appBar: currentAppBar, // 선택된 탭에 맞는 AppBar 표시
      body: IndexedStack( // IndexedStack으로 화면 전환 시 각 탭의 상태 유지
        index: _currentIndex,
        children: currentTabScreens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed, // 모든 아이템 레이블 표시
        currentIndex: _currentIndex,
        selectedItemColor: Colors.black, // 선택된 아이템 색상
        unselectedItemColor: Colors.grey.shade500, // 선택되지 않은 아이템 색상
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        onTap: (idx) async { // 탭 클릭 시
          if (!mounted) return;

          if (idx == 0) { // 홈 탭은 항상 접근 가능
            if (mounted) setState(() => _currentIndex = idx);
            return;
          }

          // 홈 탭이 아닌 다른 탭들은 로그인 상태 확인
          if (!_isUserAuthenticated) {
            String featureName = '';
            switch (idx) {
              case 1: featureName = '검색 기능'; break;
              case 2: featureName = 'AI 채팅 기능'; break;
              case 3: featureName = '일정 기능'; break;
              case 4: featureName = '프로필 화면'; break;
              default: featureName = '해당 기능';
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$featureName을(를) 이용하려면 로그인이 필요합니다.')),
            );
            // 로그인 화면으로 이동
            final loginSuccess = await Navigator.push<bool>(
              context, MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
            // 로그인 성공 시 대시보드 데이터 새로고침 및 원래 탭으로 이동 시도
            if (loginSuccess == true && mounted) {
              await _initializeScreenAndUserData(forceRefresh: true);
              if (_isUserAuthenticated && idx != 0) {
                if (mounted) setState(() => _currentIndex = idx);
              } else { // 로그인 했지만 인증 실패했거나 하면 홈으로
                if (mounted) setState(() => _currentIndex = 0);
              }
            } else { // 로그인 안 했거나 실패 시 홈으로
              if (mounted) setState(() => _currentIndex = 0);
            }
            return; // 함수 종료
          }

          // 로그인 된 상태면 해당 탭으로 이동
          if (mounted) setState(() => _currentIndex = idx);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: '검색'),
          BottomNavigationBarItem(
            icon: CircleAvatar(backgroundColor: Color(0xFFB59A7B), child: Icon(Icons.chat_bubble_outline, color: Colors.white, size: 26)),
            label: 'AI 채팅',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: '일정'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: '프로필'),
        ],
      ),
    );
  }
}
