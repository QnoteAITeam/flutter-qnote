import 'dart:convert';
import 'package:flutter_qnote/api/dto/send_message_dto.dart';
import 'package:flutter_qnote/auth/auth_api.dart';
import 'package:flutter_qnote/models/chat_message.dart';
import 'package:flutter_qnote/models/chat_session.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:3000';

  static const _storage = FlutterSecureStorage();

  static Future<List<ChatSession>> getAllSessions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/sessions'),
      headers: {'Authorization': '${await AuthApi.getAccessTokenHeader()}'},
    );

    final List<Map<String, dynamic>> temp = jsonDecode(response.body);

    return temp.map((e) {
      return ChatSession.fromJson(e);
    }).toList();
  }

  static Future<List<ChatSession>> getRecentSessions(int count) async {
    final response = await http.get(
      Uri.parse('$baseUrl/sessions/recent?count=$count'),
      headers: {'Authorization': '${await AuthApi.getAccessTokenHeader()}'},
    );

    final List<Map<String, dynamic>> temp = jsonDecode(response.body);

    return temp.map((e) {
      return ChatSession.fromJson(e);
    }).toList();
  }

  static Future<ChatSession> getMostSession() async {
    final response = await http.get(
      Uri.parse('$baseUrl/sessions/latest'),
      headers: {'Authorization': (await AuthApi.getAccessTokenHeader())!},
    );

    return ChatSession.fromJson(jsonDecode(response.body));
  }

  static Future<ChatSession> createNewSession() async {
    final response = await http.post(
      Uri.parse('$baseUrl/sessions'),
      headers: {'Authorization': (await AuthApi.getAccessTokenHeader())!},
    );

    return ChatSession.fromJson(jsonDecode(response.body));
  }

  static getAllMessagesBySession(int sessionId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/chat-messages/session/$sessionId'),
      headers: {'Authorization': (await AuthApi.getAccessTokenHeader())!},
    );

    List<Map<String, dynamic>> temp = json.decode(response.body);

    return temp.map((e) {
      return ChatMessage.fromJson(e);
    }).toList();
  }

  static Future<List<ChatMessage>> getRecentMessagesBySession(
    int sessionId,
    int limit,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/chat-messages/session/$sessionId/recent?count=$limit',
      ),
      headers: {'Authorization': (await AuthApi.getAccessTokenHeader())!},
    );

    List<Map<String, dynamic>> temp = json.decode(response.body);

    return temp.map((e) {
      return ChatMessage.fromJson(e);
    }).toList();
  }

  static Future<List<ChatMessage>> getRecentMessagesFromLatestSession(
    int limit,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/chat-messages/my/recent-messages?limit=$limit'),
      headers: {'Authorization': (await AuthApi.getAccessTokenHeader())!},
    );

    final List<Map<String, dynamic>> temp = json.decode(response.body);

    return temp.map((e) {
      return ChatMessage.fromJson(e);
    }).toList();
  }

  static Future<List<ChatMessage>> getAllMessagesFromLatestSession() async {
    final response = await http.get(
      Uri.parse('$baseUrl/chat-messages/my/messages'),
      headers: {'Authorization': (await AuthApi.getAccessTokenHeader())!},
    );

    final List<Map<String, dynamic>> temp = json.decode(response.body);

    return temp.map((e) {
      return ChatMessage.fromJson(e);
    }).toList();
  }

  //chatGpt
  static Future<SendMessageDto> sendMessageToAI(String message) async {
    final url = Uri.parse('$baseUrl/chat-messages/openai/send-message');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': (await AuthApi.getAccessTokenHeader())!,
      },
      body: jsonEncode({'message': message}),
    );

    if (response.statusCode == 200) {
      // return SendMessageRequestDto.fromJson(jsonDecode(response.body));

      //임시 dummy 값입니다.
      return SendMessageDto.dummy();
    } else {
      throw Exception('Failed to send message: ${response.body}');
    }
  }
}
