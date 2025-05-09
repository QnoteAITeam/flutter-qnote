import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthApi {
  //refreshToken을 활용하여, accessToken 재발급.
  static Future<String?> refreshToken(String refreshToken) async {
    final response = await http.post(
      Uri.parse('http://localhost:3000/auth/refresh'),
      headers: {'Authorization': 'Bearer $refreshToken'},
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['accessToken'];
    } else {
      return null;
    }
  }
}
