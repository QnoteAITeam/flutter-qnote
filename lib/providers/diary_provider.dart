// lib/providers/diary_provider.dart (새 파일 또는 기존 파일 수정)
import 'package:flutter/foundation.dart';
import 'package:flutter_qnote/api/diary_api.dart';
import 'package:flutter_qnote/models/diary.dart';
// import 'package:intl/intl.dart'; // 필요하다면 DateFormat 등 사용

class DiaryProvider with ChangeNotifier {
  List<Diary> _diaries = [];
  int _weeklyFlameCount = 0;
  String? _todayDiarySummary;
  Set<DateTime> _daysWithDiary = {}; // UTC 날짜만 저장 (시간 정보 제외)
  bool _isLoading = false;
  bool _initialFetchAttempted = false; // 초기 데이터 로드 시도 여부
  String? _errorMessage;

  List<Diary> get diaries => _diaries;
  int get weeklyFlameCount => _weeklyFlameCount;
  String? get todayDiarySummary => _todayDiarySummary;
  Set<DateTime> get daysWithDiary => _daysWithDiary;
  bool get isLoading => _isLoading;
  bool get initialFetchAttempted => _initialFetchAttempted;
  String? get errorMessage => _errorMessage;

  // 특정 날짜에 일기가 있는지 확인 (캘린더 이벤트용)
  bool hasDiaryOnDate(DateTime date) {
    final dateOnly = DateTime.utc(date.year, date.month, date.day);
    return _daysWithDiary.contains(dateOnly);
  }

  // 특정 날짜의 일기 목록 가져오기 (캘린더 탭 시 요약 표시용)
  List<Diary> getDiariesForDate(DateTime date) {
    final dateOnly = DateTime.utc(date.year, date.month, date.day);
    return _diaries.where((diary) {
      if (diary.createdAt == null) return false;
      final diaryDateOnly = DateTime.utc(diary.createdAt!.year, diary.createdAt!.month, diary.createdAt!.day);
      return diaryDateOnly.isAtSameMomentAs(dateOnly);
    }).toList();
  }


  Future<void> fetchInitialData() async {
    // 이미 로딩 중이거나, 초기 로드를 이미 시도했고 데이터가 있다면 중복 실행 방지
    if (_isLoading || (_initialFetchAttempted && _diaries.isNotEmpty)) {
      // 데이터가 있지만, UI갱신이 필요할 수 있으므로 notifyListeners()는 호출 가능
      // if (!_isLoading) notifyListeners(); // 데이터가 있는 상태에서 호출 시 UI가 깜빡일 수 있으므로 주의
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    if (!_initialFetchAttempted) { // 초기 로드 시에만 notifyListeners, 이후 새로고침은 다르게 처리 가능
      notifyListeners();
    }


    try {
      // 최근 150개 또는 특정 기간의 일기 로드 (API 스펙에 따라 조절)
      _diaries = await DiaryApi.instance.getRecentDiaries(150);
      _updateDerivedData(); // 주간 작성 수, 오늘 요약, 달력 표시 날짜 등 계산
      _initialFetchAttempted = true;
    } catch (e) {
      print("Error fetching initial diaries in DiaryProvider: $e");
      _errorMessage = "일기 정보를 불러오는 중 오류가 발생했습니다.";
      // _diaries = []; // 오류 시 기존 데이터 유지 또는 초기화 선택
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 새 일기가 추가되었을 때 또는 기존 일기가 수정/삭제되었을 때 호출될 메소드
  Future<void> refreshDiariesAfterSave(Diary? savedOrUpdatedDiary) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); // 로딩 상태 UI 반영

    try {
      // 전체 목록을 다시 불러오는 것이 가장 간단하지만, 비효율적일 수 있음.
      // 여기서는 전체 목록을 다시 불러오는 것으로 가정.
      // 더 최적화된 방법은 savedOrUpdatedDiary를 기존 _diaries 리스트에 추가/수정하고
      // _updateDerivedData()만 호출하는 것.
      _diaries = await DiaryApi.instance.getRecentDiaries(150);
      _updateDerivedData();
    } catch (e) {
      print("Error refreshing diaries in DiaryProvider: $e");
      _errorMessage = "일기 목록을 새로고침하는 중 오류가 발생했습니다.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _updateDerivedData() {
    // 달력에 표시할 날짜 업데이트 (UTC 기준 날짜만 사용)
    _daysWithDiary = {};
    for (var diary in _diaries) {
      if (diary.createdAt != null) {
        _daysWithDiary.add(DateTime.utc(diary.createdAt!.year, diary.createdAt!.month, diary.createdAt!.day));
      }
    }

    // 주간 작성 수 업데이트
    DateTime now = DateTime.now();
    DateTime startOfWeekLocal = now.subtract(Duration(days: now.weekday - DateTime.monday));
    DateTime endOfWeekLocal = startOfWeekLocal.add(const Duration(days: 6));

    // 비교를 위해 Local 날짜들을 UTC 날짜(시간=0)로 변환
    DateTime startOfWeekUtc = DateTime.utc(startOfWeekLocal.year, startOfWeekLocal.month, startOfWeekLocal.day);
    DateTime endOfWeekUtc = DateTime.utc(endOfWeekLocal.year, endOfWeekLocal.month, endOfWeekLocal.day);

    int count = 0;
    for (DateTime diaryDateUtc in _daysWithDiary) { // _daysWithDiary는 이미 UTC 날짜만 포함
      if (!diaryDateUtc.isBefore(startOfWeekUtc) && !diaryDateUtc.isAfter(endOfWeekUtc)) {
        count++;
      }
    }
    _weeklyFlameCount = count;

    // 오늘의 일기 요약 업데이트
    Diary? todayDiary;
    final todayDateUtc = DateTime.utc(now.year, now.month, now.day);
    // 최신 일기부터 찾기 위해 리스트를 뒤집거나, 정렬된 상태라면 마지막부터 탐색
    for (var diary in _diaries.reversed) { // 최신 일기부터
      if (diary.createdAt != null) {
        final diaryDateOnlyUtc = DateTime.utc(diary.createdAt!.year, diary.createdAt!.month, diary.createdAt!.day);
        if (diaryDateOnlyUtc.isAtSameMomentAs(todayDateUtc)) {
          todayDiary = diary;
          break;
        }
      }
    }
    if (todayDiary != null) {
      _todayDiarySummary = todayDiary.summary.isNotEmpty
          ? todayDiary.summary
          : (todayDiary.content.length > 50 // 요약 길이 조절
          ? '${todayDiary.content.substring(0, 50)}...'
          : todayDiary.content);
    } else {
      _todayDiarySummary = null;
    }
  }
}
