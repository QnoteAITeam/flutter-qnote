import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_qnote/api/diary_api.dart';
import 'package:flutter_qnote/api/dto/get_diary_info_dto.dart';
import 'package:flutter_qnote/models/diary.dart';
import 'package:flutter_qnote/features/diary/diary_detail_screen.dart';
import 'package:intl/intl.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<FetchDiaryResponseDto> _results = [];
  bool _isLoading = false;
  String _query = '';

  void _search(String query) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final results = await DiaryApi.instance.searchDiaries(query);
      setState(() {
        _results = results;
        _query = query;
      });
    } catch (e) {
      print('검색 오류: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Diary _convertToDiary(FetchDiaryResponseDto dto) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBFA),
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: '검색어를 입력하세요',
            border: InputBorder.none,
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: _search,
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _results.isEmpty
              ? const Center(child: Text('검색 결과가 없습니다.'))
              : ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final diaryDto = _results[index];
                  final diary = _convertToDiary(diaryDto);
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => DiaryDetailScreen(diaryToEdit: diary),
                          ),
                        );
                      },
                      child: ListTile(
                        title: Text(diary.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              diary.summary,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat(
                                'yyyy년 M월 d일 EEEE',
                                'ko_KR',
                              ).format(diary.createdAt!),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
