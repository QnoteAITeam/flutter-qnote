import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState(); // ✅ 수정됨
}

class _SearchScreenState extends State<SearchScreen> {
  List<dynamic> _results = [];
  String _query = '';

  Future<void> _search(String keyword) async {
    if (keyword.trim().isEmpty) return;

    final uri = Uri.parse('https://api.hy3ons.site/search?q=$keyword');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _results = data;
        });
      } else {
        print('서버 오류: ${response.statusCode}');
      }
    } catch (e) {
      print('연결 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('검색')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: '검색어를 입력하세요',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _query = value;
                _search(_query);
              },
            ),
          ),
          Expanded(
            child: _results.isEmpty
                ? const Center(child: Text('검색 결과가 없습니다'))
                : ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final item = _results[index];
                return ListTile(
                  title: Text(item['title'] ?? '제목 없음'),
                  subtitle: Text(item['content'] ?? '내용 없음'),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
