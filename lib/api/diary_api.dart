import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_qnote/api/dto/update_diary_dto.dart';
import 'package:flutter_qnote/auth/auth_api.dart';
import 'package:flutter_qnote/models/diary.dart';
import 'package:flutter_qnote/models/emotion_tag.dart';
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

  // 실제 쿼리 어떻게 받는지 모습.
  //   export class CreateDiaryDto {
  //   title: string;
  //   content: string;
  //   tags: string[]; // tag names
  //   emotionTags: string[]; // emotion tag names
  // }

  Future<Diary> createDiary(Diary dto) async {
    await AuthApi.getInstance.checkTokenAndRedirectIfNeeded();

    final response = await http.post(
      Uri.parse('$baseUrl/diaries'),
      headers: await _authHeader(),
      body: jsonEncode({
        'title': dto.title,
        'content': dto.content,
        'tags': dto.tags.map((e) => e.name).toList(),
        'emotionTags': dto.emotionTags.map((e) => e.name).toList(),
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create diary: ${response.body}');
    }

    print(response.body);

    return Diary.fromJson(jsonDecode(response.body));
  }

  //한 페이지당 10개 단위로 줍니다.
  Future<List<Diary>> getAllDiaries(int page) async {
    await AuthApi.getInstance.checkTokenAndRedirectIfNeeded();

    final response = await http.get(
      Uri.parse('$baseUrl/diaries?page=$page'),
      headers: await _authHeader(),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch diaries: ${response.body}');
    }
    final List<dynamic> list = jsonDecode(response.body);
    return list.map((e) => Diary.fromJson(e)).toList();
  }

  //
  Future<List<Diary>> getRecentDiaries(int count) async {
    await AuthApi.getInstance.checkTokenAndRedirectIfNeeded();

    final response = await http.get(
      Uri.parse('$baseUrl/diaries/recent?count=$count'),
      headers: await _authHeader(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch recent diaries: ${response.body}');
    }

    final List<dynamic> list = jsonDecode(response.body);
    return Diary.fromJsonList(list);
  }

  //가장 최근 다이어리 가져오기
  Future<Diary> getMostRecentDiary() async {
    await AuthApi.getInstance.checkTokenAndRedirectIfNeeded();

    final response = await http.get(
      Uri.parse('$baseUrl/diaries/recent/one'),
      headers: await _authHeader(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch most recent diary: ${response.body}');
    }

    return Diary.fromJson(jsonDecode(response.body));
  }

  Future<Diary> getDiaryById(int id) async {
    await AuthApi.getInstance.checkTokenAndRedirectIfNeeded();

    final response = await http.get(Uri.parse('$baseUrl/diaries/$id'));

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch diary: ${response.body}');
    }
    return Diary.fromJson(jsonDecode(response.body));
  }

  Future<Diary> updateDiary(int id, Diary dto) async {
    await AuthApi.getInstance.checkTokenAndRedirectIfNeeded();
    final response = await http.put(
      Uri.parse('$baseUrl/diaries/$id'),
      headers: await _authHeader(),
      body: jsonEncode({
        'title': dto.title,
        'content': dto.content,
        'tags': dto.tags.map((e) => e.name).toList(),
        'emotionTags': dto.emotionTags.map((e) => e.name).toList(),
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to update diary: ${response.body}');
    }
    return Diary.fromJson(jsonDecode(response.body));
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

  //   export interface PredictDto {
  //   predicts: string[];
  // }

  // 가장 마지막 세션에서의 유저의 예측된 대답을 리턴합니다.
  Future<List<String>> getUserPredictedAnswerMostSession() async {
    await AuthApi.getInstance.checkTokenAndRedirectIfNeeded();

    final response = await http.get(
      Uri.parse('$baseUrl/openai/predict/recent'),
      headers: await _authHeader(),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to get PredictedAnswer: ${response.body}');
    }

    return jsonDecode(response.body)['predicts'];
  }
}
