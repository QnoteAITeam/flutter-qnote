import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_qnote/api/diary_api.dart';
import 'package:flutter_qnote/api/schedule/dto/get_schedule_bydate_dto.dart';
import 'package:flutter_qnote/auth/auth_api.dart';

import 'package:http/http.dart' as http;

class ScheduleApi {
  final String baseUrl;

  const ScheduleApi._internal({required this.baseUrl});

  static ScheduleApi? _instance;

  static ScheduleApi get instance {
    _instance ??= ScheduleApi._internal(baseUrl: dotenv.env['API_URL']!);
    return _instance!;
  }

  Future<Map<String, String>> _authHeader() async {
    final token = await AuthApi.getInstance.getAccessTokenHeader();
    return {'Authorization': token!, 'Content-Type': 'application/json'};
  }

  //해당 날짜에 대한, 일정들 불러오기.
  Future<List<GetScheduleByDateResponseDto>> getScheduleByDate(
    DateTime date,
  ) async {
    await AuthApi.getInstance.checkTokenAndRedirectIfNeeded();

    final response = await http.get(
      Uri.parse('$baseUrl/schedules/by-date?date=${date.toIso8601String()}'),
      headers: await _authHeader(),
    );

    print('API call to fetch schedule for date: ${date.toIso8601String()}');
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch schedule: ${response.body}');
    }

    final List<dynamic> list = jsonDecode(response.body);
    return GetScheduleByDateResponseDto.fromJsonList(list);
  }
}
