import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_qnote/api/dto/get_diary_info_dto.dart';
import 'package:flutter_qnote/api/dto/send_message_dto.dart';
import 'package:flutter_qnote/auth/auth_api.dart';
import 'package:flutter_qnote/models/chat_message.dart';
import 'package:flutter_qnote/models/chat_session.dart';
import 'package:flutter_qnote/models/diary.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiService {
  final String? baseUrl;
  final FlutterSecureStorage _storage;

  static ApiService? _instance;

  ApiService._internal(this.baseUrl, this._storage);

  static ApiService get getInstance {
    if (_instance != null) return _instance!;

    _instance = ApiService._internal(
      dotenv.env['API_URL'],
      FlutterSecureStorage(),
    );

    return _instance!;
  }

  Future<List<ChatSession>> getAllSessions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/sessions'),
      headers: {
        'Authorization': '${await AuthApi.getInstance.getAccessTokenHeader()}',
      },
    );

    final List<Map<String, dynamic>> temp = jsonDecode(response.body);

    return temp.map((e) {
      return ChatSession.fromJson(e);
    }).toList();
  }

  Future<List<ChatSession>> getRecentSessions(int count) async {
    final response = await http.get(
      Uri.parse('$baseUrl/sessions/recent?count=$count'),
      headers: {
        'Authorization': '${await AuthApi.getInstance.getAccessTokenHeader()}',
      },
    );

    final List<Map<String, dynamic>> temp = jsonDecode(response.body);

    return temp.map((e) {
      return ChatSession.fromJson(e);
    }).toList();
  }

  Future<ChatSession> getMostSession() async {
    final response = await http.get(
      Uri.parse('$baseUrl/sessions/latest'),
      headers: {
        'Authorization': (await AuthApi.getInstance.getAccessTokenHeader())!,
      },
    );

    return ChatSession.fromJson(jsonDecode(response.body));
  }

  Future<ChatSession> createNewSession() async {
    final response = await http.post(
      Uri.parse('$baseUrl/sessions'),
      headers: {
        'Authorization': (await AuthApi.getInstance.getAccessTokenHeader())!,
      },
    );

    print('ChatScreen 을 성공적으로 만들었습니다.');
    print(response.body);

    return ChatSession.fromJson(jsonDecode(response.body));
  }

  getAllMessagesBySession(int sessionId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/chat-messages/session/$sessionId'),
      headers: {
        'Authorization': (await AuthApi.getInstance.getAccessTokenHeader())!,
      },
    );

    List<Map<String, dynamic>> temp = json.decode(response.body);

    return temp.map((e) {
      return ChatMessage.fromJson(e);
    }).toList();
  }

  Future<List<ChatMessage>> getRecentMessagesBySession(
    int sessionId,
    int limit,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/chat-messages/session/$sessionId/recent?count=$limit',
      ),
      headers: {
        'Authorization': (await AuthApi.getInstance.getAccessTokenHeader())!,
      },
    );

    List<Map<String, dynamic>> temp = json.decode(response.body);

    return temp.map((e) {
      return ChatMessage.fromJson(e);
    }).toList();
  }

  Future<List<ChatMessage>> getRecentMessagesFromLatestSession(
    int limit,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/chat-messages/my/recent-messages?limit=$limit'),
      headers: {
        'Authorization': (await AuthApi.getInstance.getAccessTokenHeader())!,
      },
    );

    final List<Map<String, dynamic>> temp = json.decode(response.body);

    return temp.map((e) {
      return ChatMessage.fromJson(e);
    }).toList();
  }

  Future<List<ChatMessage>> getAllMessagesFromLatestSession() async {
    final response = await http.get(
      Uri.parse('$baseUrl/chat-messages/my/messages'),
      headers: {
        'Authorization': (await AuthApi.getInstance.getAccessTokenHeader())!,
      },
    );

    final List<Map<String, dynamic>> temp = json.decode(response.body);

    return temp.map((e) {
      return ChatMessage.fromJson(e);
    }).toList();
  }

  //chatGpt
  Future<SendMessageDto> sendMessageToAI(String message) async {
    await AuthApi.getInstance.checkTokenAndRedirectIfNeeded();
    print('User가, AI에게 $message 전송하였습니다.');
    final url = Uri.parse('$baseUrl/openai/send-message');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': (await AuthApi.getInstance.getAccessTokenHeader())!,
      },
      body: jsonEncode({'message': message}),
    );

    if (response.statusCode == 201) {
      // return SendMessageRequestDto.fromJson(jsonDecode(response.body));
      print(response.body);
      //임시 dummy 값입니다.
      return SendMessageDto.fromJsonByAssistant(jsonDecode(response.body));
    } else {
      throw Exception('Failed to send message: ${response.body}');
    }
  }

  //파라미터로 다이어리의 내용을 주면 api서버에 호출 해서, 알아 내 옵니다.
  Future<GetDiaryInfoDto> getDiaryInfoByContent(String content) async {
    await AuthApi.getInstance.checkTokenAndRedirectIfNeeded();

    final response = await http.post(
      Uri.parse('$baseUrl/openai/summary'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': (await AuthApi.getInstance.getAccessTokenHeader())!,
      },
      body: {'content': content},
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return GetDiaryInfoDto.fromJson(jsonDecode(response.body));
    } else {
      throw new Exception('Get Diary Info By Content, 요약을 가져오던 중 문제가 생겼습니다.');
    }
  }
}
