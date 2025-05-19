// lib/features/dashboard/dashboard_screen.dart
import 'dart:async';
import 'dart:io'; // SocketException, TimeoutException 사용

import 'package:flutter/material.dart';
import 'package:flutter_qnote/api/diary_api.dart'; // 제공해주신 DiaryApi
import 'package:flutter_qnote/models/diary.dart';   // Diary 모델
import 'package:flutter_qnote/widgets/calendar_widget.dart'; // CalendarWidget
import 'package:flutter_qnote/features/search/search_screen.dart';
import 'package:flutter_qnote/features/chat/chat_screen.dart';
import 'package:intl/intl.dart'; // DateFormat 사용

// 사용자 정의 예외 클래스 (선택적이지만, DiaryApi에서 일반 Exception을 던지므로 여기서 구분하기 어려움)
// class FetchDataException implements Exception {
//   final String message;
//   FetchDataException(this.message);
//   @override
//   String toString() => message;
// }
// class ServerErrorException implements Exception {
//   final String message;
//   ServerErrorException(this.message);
//   @override
//   String toString() => message;
// }


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _weeklyFlameCount = 0;
  int _currentIndex = 0;
  final String _userName = '사용자';
  late DateTime _focusedDayForCalendar;
  final DateTime _today = DateTime.now();

  Set<DateTime> _daysWithDiaryFromApi = {};
  List<Diary> _cachedDiaries = []; // API로부터 성공적으로 받아온 Diary 객체들을 저장
  bool _isLoadingDiaries = true;

  OverlayEntry? _diarySnippetOverlayEntry;
  final GlobalKey _calendarWidgetKey = GlobalKey();
  Timer? _snippetOverlayTimer;

  @override
  void initState() {
    super.initState();
    _focusedDayForCalendar = _today;
    _loadInitialDiaryData();
  }

  @override
  void dispose() {
    _removeDiarySnippetOverlay();
    _snippetOverlayTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialDiaryData() async {
    await _fetchDiariesAndUpdateState(_focusedDayForCalendar);
  }

  Future<void> _fetchDiariesAndUpdateState(DateTime referenceDateForView) async {
    if (!mounted) return;
    setState(() => _isLoadingDiaries = true);
    String? snackBarMessage;

    try {
      // DiaryApi.getRecentDiaries()는 성공 시 List<Diary>를, 실패 시 Exception을 던짐.
      // 따라서 반환값을 List<Diary>로 바로 받습니다.
      final List<Diary> fetchedDiaries = await DiaryApi.instance.getRecentDiaries(150);

      _cachedDiaries = fetchedDiaries; // API로부터 받은 Diary 리스트를 바로 캐시에 저장
      final Set<DateTime> daysWithDiaries = {};
      for (var diary in fetchedDiaries) {
        daysWithDiaries.add(DateTime.utc(diary.createdAt.year, diary.createdAt.month, diary.createdAt.day));
      }

      if (mounted) {
        setState(() {
          _daysWithDiaryFromApi = daysWithDiaries;
          _updateWeeklyFlameCount();
          // _isLoadingDiaries는 finally에서 false로 설정
        });
      }
    } catch (e, stackTrace) { // DiaryApi에서 발생한 모든 Exception을 여기서 잡음
      print('Error type in _fetchDiariesAndUpdateState: ${e.runtimeType}');
      print('Error details: $e');
      print('Stack trace: $stackTrace');

      if (e is SocketException) {
        snackBarMessage = '네트워크 연결을 확인해주세요.';
      } else if (e is TimeoutException) {
        snackBarMessage = '서버 응답 시간이 초과되었습니다.';
      } else if (e is HttpException) { // DiaryApi 내부에서 HTTP 오류 시 발생시킬 수 있음 (현재 코드는 일반 Exception)
        snackBarMessage = '서버 통신 오류: ${e.message}';
      }
      // DiaryApi의 getRecentDiaries에서 throw Exception(...)으로 오는 경우
      // e.toString()에 'Failed to fetch recent diaries: {실제 서버 응답}'이 포함됨
      else if (e.toString().contains('Failed to fetch recent diaries')) {
        // 서버 응답 내용 중 일부를 파싱하여 사용자에게 더 친화적인 메시지를 보여줄 수도 있음
        // 예: if (e.toString().contains('not found')) snackBarMessage = '최근 일기를 찾을 수 없습니다.';
        snackBarMessage = '최근 일기를 가져오는데 실패했습니다. 서버 응답을 확인해주세요.';
        // 실제 오류는 콘솔에 e.toString()으로 출력됨
      } else {
        String errorString = e.toString();
        snackBarMessage = '일기 정보 로드 중 오류: ${errorString.substring(0, (errorString.length > 40) ? 40 : errorString.length)}...';
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDiaries = false;
        });
        if (snackBarMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(snackBarMessage),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  void _updateWeeklyFlameCount() {
    DateTime now = _today;
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - DateTime.monday));
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));
    int count = 0;
    for (DateTime diaryDateUtc in _daysWithDiaryFromApi) {
      DateTime utcStartOfWeek = DateTime.utc(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      DateTime utcEndOfWeek = DateTime.utc(endOfWeek.year, endOfWeek.month, endOfWeek.day);
      if (!diaryDateUtc.isBefore(utcStartOfWeek) && !diaryDateUtc.isAfter(utcEndOfWeek)) {
        count++;
      }
    }
    if (mounted) {
      setState(() {
        _weeklyFlameCount = count;
      });
    }
  }

  Future<void> handleExternalDiarySaved(DateTime savedDate) async {
    DateTime savedDateUtc = DateTime.utc(savedDate.year, savedDate.month, savedDate.day);
    if (mounted) {
      bool needsApiFetch = !_daysWithDiaryFromApi.contains(savedDateUtc);
      setState(() {
        _daysWithDiaryFromApi.add(savedDateUtc);
        _updateWeeklyFlameCount();
      });
      if (needsApiFetch) {
        await _fetchDiariesAndUpdateState(_focusedDayForCalendar);
      }
    }
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFB59A7B),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: SafeArea(
        bottom: false,
        child: Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: '나만의 AI Assistance, ', style: TextStyle(color: Colors.white, fontSize: 16)),
              TextSpan(
                text: 'Qnote',
                style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'NanumMyeongjo'),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildGreetingCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withAlpha((0.2 * 255).round()), spreadRadius: 2, blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$_userName님, 오늘은 어떤 하루였나요? 😊', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          const Text('오늘 하루는 무슨 일들이 있었는지 저에게 알려주세요!', style: TextStyle(fontSize: 14, color: Colors.black54)),
        ],
      ),
    );
  }

  void _handleCalendarDateTap(DateTapDetails details) {
    _removeDiarySnippetOverlay();
    if (details.hasEvent) { // _daysWithDiaryFromApi에 해당 날짜가 있는지 (UI 기준)
      Diary? tappedDiary;
      // _cachedDiaries에는 API에서 성공적으로 Diary 객체로 변환된 것들만 있음
      for (var diary in _cachedDiaries) {
        if (_isSameDay(diary.createdAt, details.date)) {
          tappedDiary = diary;
          break;
        }
      }
      if (tappedDiary != null) {
        String snippet = tappedDiary.summary.isNotEmpty
            ? tappedDiary.summary
            : (tappedDiary.content.length > 50 ? '${tappedDiary.content.substring(0, 50)}...' : tappedDiary.content);
        if (snippet.isNotEmpty) {
          final RenderBox? calendarBox = _calendarWidgetKey.currentContext?.findRenderObject() as RenderBox?;
          Offset overlayPosition;
          if (calendarBox != null && calendarBox.attached) {
            overlayPosition = Offset(
                calendarBox.localToGlobal(Offset.zero).dx + (calendarBox.size.width / 2) - 75,
                calendarBox.localToGlobal(Offset.zero).dy - 80
            );
            if (overlayPosition.dy < MediaQuery.of(context).padding.top + kToolbarHeight) {
              overlayPosition = Offset(overlayPosition.dx, MediaQuery.of(context).padding.top + kToolbarHeight + 10);
            }
          } else {
            overlayPosition = Offset(MediaQuery.of(context).size.width / 2 - 75, MediaQuery.of(context).size.height / 4);
          }
          _showDiarySnippetOverlay(overlayPosition, snippet);
        }
      } else {
        // UI 상에는 이벤트가 있다고 표시되었으나, 실제 캐시된 Diary 객체에는 없는 경우
        // 이는 _daysWithDiaryFromApi와 _cachedDiaries 간의 불일치 또는 데이터 로드 제한 때문일 수 있음
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${DateFormat.Md('ko_KR').format(details.date)}의 일기 상세 정보를 찾을 수 없습니다.')),
        );
      }
    }
  }

  void _showDiarySnippetOverlay(Offset position, String snippetText) {
    _removeDiarySnippetOverlay();
    _snippetOverlayTimer?.cancel();
    _diarySnippetOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx, top: position.dy,
        child: IgnorePointer(
          child: Material(
            elevation: 4.0, borderRadius: BorderRadius.circular(8.0), color: Colors.transparent,
            child: Container(
              width: 150, padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(color: Colors.black.withAlpha((0.8 * 255).round()), borderRadius: BorderRadius.circular(8.0)),
              child: Text(snippetText, style: const TextStyle(color: Colors.white, fontSize: 13), textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis),
            ),
          ),
        ),
      ),
    );
    if (mounted) Overlay.of(context).insert(_diarySnippetOverlayEntry!);
    _snippetOverlayTimer = Timer(const Duration(seconds: 3), _removeDiarySnippetOverlay);
  }

  void _removeDiarySnippetOverlay() {
    _snippetOverlayTimer?.cancel();
    if (_diarySnippetOverlayEntry != null && _diarySnippetOverlayEntry!.mounted) {
      _diarySnippetOverlayEntry!.remove();
    }
    _diarySnippetOverlayEntry = null;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: Column(
        children: [
          _buildHeader(),
          _buildGreetingCard(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 0, bottom: 16),
                    child: Text(
                      '이번 주에 총 $_weeklyFlameCount개의 일기를 작성했어요!',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ),
                  if (_isLoadingDiaries)
                    const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
                  else
                    Container(
                      key: _calendarWidgetKey,
                      child: CalendarWidget(
                        focusedDayForCalendar: _focusedDayForCalendar,
                        today: _today,
                        daysWithDiary: _daysWithDiaryFromApi,
                        onDateTap: _handleCalendarDateTap,
                        onPageChanged: (newFocusedPageDate) {
                          if (mounted) {
                            if (!_isSameDay(_focusedDayForCalendar, newFocusedPageDate) || _focusedDayForCalendar.month != newFocusedPageDate.month) {
                              setState(() {
                                _focusedDayForCalendar = newFocusedPageDate;
                              });
                              _fetchDiariesAndUpdateState(DateTime(newFocusedPageDate.year, newFocusedPageDate.month, 1));
                            }
                          }
                        },
                      ),
                    ),
                  const SizedBox(height: 24),
                  Container( // 오늘의 일기 요약 (하드코딩)
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.grey.withAlpha((0.15 * 255).round()), spreadRadius: 1, blurRadius: 5, offset: const Offset(0, 2))],
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('오늘의 일기 요약', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87)),
                        SizedBox(height: 12),
                        Text('오늘 생각보다 피곤했어.\n이만 자야겠다. 고생했어, 나😊', style: TextStyle(fontSize: 15, height: 1.5, color: Colors.black54)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // ElevatedButton(onPressed: () => handleExternalDiarySaved(DateTime.now()), child: Text("오늘 일기 저장 (테스트)"))
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey.shade500,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        onTap: (idx) {
          if (mounted) { setState(() { _currentIndex = idx; });}
          if (idx == 1) {Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));}
          else if (idx == 2) {Navigator.push( context, MaterialPageRoute(builder: (_) => const ChatScreen()));}
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: '검색'),
          BottomNavigationBarItem(
            icon: CircleAvatar(backgroundColor: Color(0xFFB59A7B), child: Icon(Icons.edit_outlined, color: Colors.white, size: 28)),
            label: '',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.schedule), label: '일정'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: '프로필'),
        ],
      ),
    );
  }
}
