// lib/features/search/search_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // 날짜 포맷팅을 위해 추가

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _results = [];
  String _query = '';
  List<String> _recentSearches = ['성수 브런치', '프로젝트 회의', '사이클링']; // 최근 검색어 더미 데이터

  // 더미 데이터 (실제 앱에서는 API 호출 또는 로컬 DB에서 가져옴)
  final List<Map<String, dynamic>> _recentDiaries = [
    {
      'date': DateTime(2025, 5, 16), // 이미지와 동일한 날짜
      'content': '오늘은 샐러드를 먹고 프로젝트 회의를 했어요. 저녁엔 카레를 먹고 도서관에 다녀왔습니다. 생각보다 할 일이 많아서 조금 피곤했지만, 계획했던 일들을 마무리해서 뿌듯한 하루였네요.', // 내용 길게
      'tags': ['#피곤함', '#뿌듯함', '#일상', '#자기계발'] // 이미지 태그 포함 및 추가 태그
    },
    {
      'date': DateTime(2025, 5, 15),
      'content': '아침 일찍 일어나 사이클링을 하고 점심엔 친구와 맛있는 파스타를 먹었어요. 오늘 하루도 즐거웠다!',
      'tags': ['#사이클링', '#점심', '#친구']
    },
    {
      'date': DateTime(2025, 5, 13),
      'content': '새로운 동네 카페를 발견했는데 분위기가 너무 좋아서 자주 가게 될 것 같아요. 커피 맛도 일품!',
      'tags': ['#카페탐방']
    },
  ];

  final List<Map<String, dynamic>> _savedDiaries = [
    {'title': '전체', 'count': 127, 'color': const Color(0xFFB0BEC5)},
    {'title': '주제 1', 'count': 23, 'color': const Color(0xFFA1887F)},
    {'title': '주제 2', 'count': 57, 'color': const Color(0xFF80CBC4)},
    {'title': '주제 3', 'count': 18, 'color': const Color(0xFF9FA8DA)},
    {'title': '주제 4', 'count': 9, 'color': const Color(0xFFF48FB1)},
    {'title': '주제 5', 'count': 31, 'color': const Color(0xFFA5D6A7)},
  ];


  @override
  void initState() {
    super.initState();
    // TODO: 앱 시작 시 저장된 최근 검색어 로드 (예: SharedPreferences 또는 flutter_secure_storage 사용)
  }

  void _addRecentSearch(String term) {
    if (term.isEmpty) return;
    if (mounted) {
      setState(() {
        _recentSearches.remove(term); // 기존에 있으면 제거 후
        _recentSearches.insert(0, term); // 맨 앞에 추가 (최신화)
        if (_recentSearches.length > 5) { // 최근 검색어 최대 5개 유지
          _recentSearches.removeLast();
        }
        // TODO: 변경된 최근 검색어 목록 저장 (예: SharedPreferences에 저장)
      });
    }
  }

  void _removeRecentSearch(String term) {
    if (mounted) {
      setState(() {
        _recentSearches.remove(term);
        // TODO: 변경된 최근 검색어 목록 저장
      });
    }
  }

  void _clearAllRecentSearches() {
    if (mounted) {
      setState(() {
        _recentSearches.clear();
        // TODO: 변경된 최근 검색어 목록 저장
      });
    }
  }

  Future<void> _search(String keyword) async {
    final String trimmedKeyword = keyword.trim();
    if (trimmedKeyword.isEmpty) {
      if (mounted) {
        setState(() {
          _results = [];
          // _query = ''; // 필요에 따라, 검색어가 비면 _query도 초기화하여 초기 화면을 강제로 표시할 수 있음
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _query = trimmedKeyword; // 실제 검색 수행 시 _query 업데이트하여 결과 화면으로 전환
      });
    }
    _addRecentSearch(trimmedKeyword); // 검색 시 최근 검색어에 추가

    final uri = Uri.parse('https://api.hy3ons.site/search?q=${Uri.encodeComponent(trimmedKeyword)}');
    try {
      final response = await http.get(uri);
      if (mounted) { // 비동기 작업 후 mounted 상태 확인
        if (response.statusCode == 200) {
          final List data = json.decode(utf8.decode(response.bodyBytes));
          setState(() {
            _results = data;
          });
        } else {
          print('서버 오류: ${response.statusCode}');
          setState(() { _results = []; }); // 오류 발생 시 결과 목록 비우기
        }
      }
    } catch (e) {
      print('연결 실패: $e');
      if (mounted) {
        setState(() { _results = []; }); // 오류 발생 시 결과 목록 비우기
      }
    }
  }

  Widget _buildSectionTitle(String title, {VoidCallback? onClearAll, bool hasIcon = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0, right: 16.0, top: 24.0, bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
              if (hasIcon)
                const Padding(
                  padding: EdgeInsets.only(left: 6.0, top: 2.0),
                  child: Text("📗", style: TextStyle(fontSize: 17)),
                ),
            ],
          ),
          if (onClearAll != null)
            InkWell(
              onTap: onClearAll,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                child: Text('전체삭제', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentSearches() {
    if (_recentSearches.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Text('최근 검색 기록이 없습니다.', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: _recentSearches.map((term) {
          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            elevation: 0.5,
            shadowColor: Colors.grey.withOpacity(0.2),
            child: InkWell(
              onTap: () {
                _searchController.text = term;
                _searchController.selection = TextSelection.fromPosition(TextPosition(offset: _searchController.text.length));
                _search(term);
              },
              borderRadius: BorderRadius.circular(20),
              child: Chip(
                label: Text(term, style: TextStyle(color: Colors.grey.shade800, fontSize: 13.5)),
                onDeleted: () => _removeRecentSearch(term),
                deleteIconColor: Colors.grey.shade600,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.grey.shade300, width: 0.8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                labelPadding: const EdgeInsets.only(left: 4),
                deleteIcon: const Icon(Icons.close, size: 16),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 각 태그 칩을 생성하는 헬퍼 함수
  Widget _buildTagChip(String label, {required bool isFirstTag}) {
    Color chipBackgroundColor;
    Color chipTextColor;
    FontWeight chipFontWeight = FontWeight.w500;

    if (isFirstTag) { // 첫 번째 태그 스타일
      chipBackgroundColor = const Color(0xFFFDECC8); // 연한 주황
      chipTextColor = const Color(0xFF8D6E63);       // 어두운 주황/갈색
    } else { // 두 번째 태그 스타일
      chipBackgroundColor = const Color(0xFFFCE4EC); // 연한 분홍
      chipTextColor = const Color(0xFFC2185B);       // 어두운 분홍/자주
    }

    return Chip(
      label: Text(label, style: TextStyle(fontSize: 11, color: chipTextColor, fontWeight: chipFontWeight)),
      backgroundColor: chipBackgroundColor,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), // 패딩 약간 줄임
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide.none
      ),
    );
  }


  Widget _buildRecentDiaries() {
    return SizedBox(
      height: 170, // 카드 높이
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20.0, right: 8.0, top: 8.0, bottom: 12.0),
        itemCount: _recentDiaries.length,
        itemBuilder: (context, index) {
          final diary = _recentDiaries[index];
          final tags = diary['tags'] as List<String>;
          final displayTags = tags.take(2).toList(); // 최대 2개의 태그만 가져오기

          return Card(
            margin: const EdgeInsets.only(right: 12),
            elevation: 1.0,
            shadowColor: Colors.grey.withOpacity(0.15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: const Color(0xFFFEFCF9),
            child: Container(
              width: 180,
              padding: const EdgeInsets.fromLTRB(16.0, 14.0, 16.0, 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text( // 날짜
                    DateFormat('yyyy년 M월 d일').format(diary['date']),
                    style: const TextStyle(fontSize: 15, color: Color(0xFF212121), fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Expanded( // 내용 (남은 공간을 채움)
                    child: Text(
                      diary['content'],
                      style: const TextStyle(fontSize: 13, height: 1.40, color: Color(0xFF666666)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 6), // 내용과 태그 사이 간격
                  if (displayTags.isNotEmpty)
                    Row( // 태그를 가로로 나란히 표시
                      children: <Widget>[
                        if (displayTags.isNotEmpty)
                          Flexible( // 첫 번째 태그가 공간에 맞게 줄어들 수 있도록
                            fit: FlexFit.loose, // 필요 이상으로 확장하지 않음
                            child: _buildTagChip(displayTags[0], isFirstTag: true),
                          ),
                        if (displayTags.length > 1)
                          const SizedBox(width: 4.0), // 태그 사이 간격
                        if (displayTags.length > 1)
                          Flexible( // 두 번째 태그도 공간에 맞게 줄어들 수 있도록
                            fit: FlexFit.loose,
                            child: _buildTagChip(displayTags[1], isFirstTag: false),
                          ),
                      ],
                    )
                  else
                    const SizedBox.shrink(), // 태그 없으면 빈 공간
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSavedDiaries() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 16.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _savedDiaries.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10.0,
          mainAxisSpacing: 10.0,
          childAspectRatio: 0.85,
        ),
        itemBuilder: (context, index) {
          final diaryBook = _savedDiaries[index];
          return Container(
            decoration: BoxDecoration(
                color: diaryBook['color'] as Color,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(1,2))
                ]
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 8,
                  top: 12,
                  bottom: 12,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20, right: 10, top: 12, bottom: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        diaryBook['title'],
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: -0.2),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          '${diaryBook['count']}개',
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInitialSearchScreenContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('최근 검색어', onClearAll: _recentSearches.isNotEmpty ? _clearAllRecentSearches : null),
          _buildRecentSearches(),
          _buildSectionTitle('최근에 작성한 일기', hasIcon: true),
          _buildRecentDiaries(),
          _buildSectionTitle('저장된 일기'),
          _buildSavedDiaries(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSearchResultsContent() {
    if (_results.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 16),
        itemCount: _results.length,
        itemBuilder: (context, index) {
          final item = _results[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            elevation: 1.0,
            shadowColor: Colors.grey.withOpacity(0.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            color: Colors.white,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              title: Text(item['title']?.toString() ?? '제목 없음', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(item['content']?.toString() ?? '내용 없음', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
              ),
            ),
          );
        },
      );
    } else {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 60, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                '"$_query"에 대한 검색 결과가 없습니다.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFDFBFA),
      child: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '검색어를 입력해주세요',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade600, size: 22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFF3F3F3),
                contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 15),
              onChanged: (value) {
                if (mounted) {
                  setState(() {
                    _query = value;
                    if (_query.trim().isEmpty && _results.isNotEmpty) {
                      _results = [];
                    }
                  });
                }
              },
              textInputAction: TextInputAction.search,
              onSubmitted: (value) {
                _search(value);
              },
            ),
          ),
          Expanded(
            child: _query.trim().isEmpty
                ? _buildInitialSearchScreenContent()
                : _buildSearchResultsContent(),
          ),
        ],
      ),
    );
  }
}
