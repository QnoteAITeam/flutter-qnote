import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_qnote/auth/auth_api.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _results = [];
  String _query = '';

  Future<void> _search(String keyword) async {
    final trimmedKeyword = keyword.trim();
    if (trimmedKeyword.isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _query = trimmedKeyword);

    final uri = Uri.parse('https://qnote.anacnu.kr/diaries/search');

    final String? token = await AuthApi.getInstance.getAccessTokenHeader();
    if (token == null) {
      print('🔐 accessToken 없음');
      return;
    }

    try {
      final response = await http.post(
        uri,
        headers: {'Authorization': token, 'Content-Type': 'application/json'},
        body: jsonEncode({'query': trimmedKeyword, 'page': 1}),
      );

      if (response.statusCode == 200) {
        final List data = json.decode(utf8.decode(response.bodyBytes));
        setState(() => _results = data);
      } else {
        print('서버 오류: ${response.statusCode}');
        setState(() => _results = []);
      }
    } catch (e) {
      print('연결 실패: $e');
      setState(() => _results = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: '검색어를 입력하세요',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onSubmitted: _search,
          ),
        ),
        Expanded(
          child:
              _results.isEmpty
                  ? const Center(child: Text('검색 결과가 없습니다'))
                  : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final item = _results[index];
                      return ListTile(
                        title: Text(item['title'] ?? '제목 없음'),
                        subtitle: Text(
                          item['content'] ?? '내용 없음',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }
}
