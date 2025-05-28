import 'package:flutter/material.dart';
import 'package:flutter_qnote/api/diary_api.dart';
import 'package:flutter_qnote/api/dto/get_diary_info_dto.dart';
import 'package:flutter_qnote/models/diary.dart';
import 'package:flutter_qnote/features/diary/diary_detail_screen.dart'; // ✅ 상세 화면 import
import 'search_screen.dart';
import 'package:intl/intl.dart';

class SearchHomeScreen extends StatefulWidget {
  const SearchHomeScreen({super.key});

  @override
  State<SearchHomeScreen> createState() => _SearchHomeScreenState();
}

class _SearchHomeScreenState extends State<SearchHomeScreen> {
  List<Diary> _recentDiaries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentDiaries();
  }

  Future<void> _loadRecentDiaries() async {
    try {
      final List<FetchDiaryResponseDto> dtoList = await DiaryApi.instance
          .getRecentDiaries(20);
      final List<Diary> diaries =
          dtoList
              .map(
                (dto) => Diary(
                  id: dto.id,
                  title: dto.title,
                  content: dto.content,
                  tags: dto.tags,
                  emotionTags: dto.emotionTags,
                  createdAt: dto.createdAt,
                  updatedAt: dto.updatedAt,
                  summary: dto.summary,
                ),
              )
              .toList();

      setState(() {
        _recentDiaries = diaries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("최근 일기 로딩 실패")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBFA),
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchScreen()),
            );
          },
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F3),
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              '검색어를 입력해주세요',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _recentDiaries.isEmpty
              ? const Center(child: Text("최근 저장된 일기가 없습니다."))
              : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _recentDiaries.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        '📘 최근 일기',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }

                  final diary = _recentDiaries[index - 1];
                  final formattedDate =
                      diary.createdAt != null
                          ? DateFormat(
                            'yyyy.MM.dd',
                          ).format(diary.createdAt!.toLocal())
                          : '날짜 없음';

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DiaryDetailScreen(diaryToEdit: diary),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            diary.title.isNotEmpty ? diary.title : '(제목 없음)',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            diary.summary.isNotEmpty
                                ? diary.summary
                                : diary.content.length > 50
                                ? '${diary.content.substring(0, 50)}...'
                                : diary.content,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
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
}
