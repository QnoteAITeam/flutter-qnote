import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_qnote/api/dto/get_diary_info_dto.dart';
import 'package:flutter_qnote/auth/auth_api.dart';
import 'package:flutter_qnote/models/diary.dart';
import 'package:http/http.dart' as http;

class DiaryApi {
  final String baseUrl;
  static DiaryApi? _instance;

  DiaryApi._internal(this.baseUrl);

  static DiaryApi get instance {
    _instance ??= DiaryApi._internal(dotenv.env['API_URL']!);
    return _instance!;
  }

  Future<Map<String, String>> _authHeader() async {
    final token = await AuthApi.getInstance.getAccessTokenHeader();
    return {'Authorization': token!, 'Content-Type': 'application/json'};
  }

  Future<FetchDiaryResponseDto> createDiary(Diary dto) async {
    await AuthApi.getInstance.checkTokenAndRedirectIfNeeded();

    print(dto.tags);
    print(dto.emotionTags);

    final response = await http.post(
      Uri.parse('$baseUrl/diaries'),
      headers: await _authHeader(),
      body: jsonEncode({
        'title': dto.title,
        'content': dto.content,
        'tags': dto.tags,
        'emotionTags': dto.emotionTags,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create diary: ${response.body}');
    }

    print(
      '[CREATE DIARY RESPONSE] Status: ${response.statusCode}, Body: ${response.body}',
    );

    return FetchDiaryResponseDto.fromJson(jsonDecode(response.body));
  }

  Future<List<FetchDiaryResponseDto>> getAllDiaries(int page) async {
    await AuthApi.getInstance.checkTokenAndRedirectIfNeeded();
    final response = await http.get(
      Uri.parse('$baseUrl/diaries?page=$page'),
      headers: await _authHeader(),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch diaries: ${response.body}');
    }
    final List<dynamic> list = jsonDecode(response.body);
    return FetchDiaryResponseDto.fromJsonList(list);
  }

  Future<List<FetchDiaryResponseDto>> getRecentDiaries(int count) async {
    await AuthApi.getInstance.checkTokenAndRedirectIfNeeded();
    final response = await http.get(
      Uri.parse('$baseUrl/diaries/recent?count=$count'),
      headers: await _authHeader(),
    );
    print(
      '[GET RECENT DIARIES] Status: ${response.statusCode}, Body: ${response.body}',
    );
    if (response.statusCode == 200) {
      if (response.body.isEmpty || response.body.toLowerCase() == 'null')
        return [];
      final decodedBody = jsonDecode(response.body);
      if (decodedBody is List)
        return FetchDiaryResponseDto.fromJsonList(decodedBody);
      return [];
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception(
        'Failed to fetch recent diaries: Status ${response.statusCode}, Body: ${response.body}',
      );
    }
  }

  Future<FetchDiaryResponseDto> getMostRecentDiary() async {
    await AuthApi.getInstance.checkTokenAndRedirectIfNeeded();
    final response = await http.get(
      Uri.parse('$baseUrl/diaries/recent/one'),
      headers: await _authHeader(),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch most recent diary: ${response.body}');
    }
    return FetchDiaryResponseDto.fromJson(jsonDecode(response.body));
  }

  Future<FetchDiaryResponseDto> getDiaryById(int id) async {
    await AuthApi.getInstance.checkTokenAndRedirectIfNeeded();
    final response = await http.get(
      Uri.parse('$baseUrl/diaries/$id'),
      headers: await _authHeader(),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch diary: ${response.body}');
    }
    return FetchDiaryResponseDto.fromJson(jsonDecode(response.body));
  }

  Future<FetchDiaryResponseDto> updateDiary(int id, Diary dto) async {
    await AuthApi.getInstance.checkTokenAndRedirectIfNeeded();
    final response = await http.put(
      Uri.parse('$baseUrl/diaries/$id'),
      headers: await _authHeader(),
      body: jsonEncode({
        'title': dto.title,
        'content': dto.content,
        'tags': dto.tags,
        'emotionTags': dto.emotionTags,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update diary: ${response.body}');
    }
    print(
      '[UPDATE DIARY RESPONSE] Status: ${response.statusCode}, Body: ${response.body}',
    );

    return FetchDiaryResponseDto.fromJson(jsonDecode(response.body));
  }

  Future<void> deleteDiary(int id) async {
    await AuthApi.getInstance.checkTokenAndRedirectIfNeeded();
    final response = await http.delete(
      Uri.parse('$baseUrl/diaries/$id'),
      headers: await _authHeader(),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete diary: ${response.body}');
    }
  }

  Future<List<String>> getUserPredictedAnswerMostSession() async {
    await AuthApi.getInstance.checkTokenAndRedirectIfNeeded();
    final response = await http.get(
      Uri.parse('$baseUrl/openai/predict/recent'),
      headers: await _authHeader(),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      if (response.statusCode == 204 ||
          response.body.isEmpty ||
          response.body.toLowerCase() == 'null') {
        return [];
      }
      throw Exception('Failed to get PredictedAnswer: ${response.body}');
    }
    if (response.body.isEmpty || response.body.toLowerCase() == 'null')
      return [];
    final dynamic decoded = jsonDecode(response.body);
    if (decoded is Map &&
        decoded.containsKey('predicts') &&
        decoded['predicts'] is List) {
      return List<String>.from(
        decoded['predicts'].map((item) => item.toString()),
      );
    }
    return [];
  }
}
