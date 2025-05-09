import 'dart:convert';
import 'package:flutter_qnote/api/get_messages_dto.dart';
import 'package:flutter_qnote/api/send_message_request.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;

  static const _storage = FlutterSecureStorage();

  ApiService({required this.baseUrl});

  Future<GetMessagesDto> getMessages() async {
    final token = await _storage.read(key: 'accessToken');

    if (token == null) {
      throw Exception('No access token');
    }

    final url = Uri.parse('$baseUrl/messages');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      // return GetMessagesDto.fromJson(jsonDecode(response.body));

      //임시 더미 값.
      return GetMessagesDto.dummy();
    } else {
      throw Exception('Failed to load messages: ${response.body}');
    }
  }

  //chatGpt
  Future<SendMessageRequestDto> sendMessage(String message) async {
    final token = await _storage.read(key: 'accessToken');
    final url = Uri.parse('$baseUrl/openai/send-message');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'message': message}),
    );

    if (response.statusCode == 200) {
      // return SendMessageRequestDto.fromJson(jsonDecode(response.body));

      //임시 dummy 값입니다.
      return SendMessageRequestDto.dummy();
    } else {
      throw Exception('Failed to send message: ${response.body}');
    }
  }
}
