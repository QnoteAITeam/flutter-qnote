import 'dart:convert';

import 'package:flutter_qnote/auth/auth_api.dart';
import 'package:flutter_qnote/models/user.dart';
import 'package:http/http.dart' as http;

class UserApi {
  static String baseUrl = AuthApi.baseUrl;

  static Future<User> getUserCredential() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/my'),
      headers: {'Authorization': (await AuthApi.getAccessTokenHeader())!},
    );

    return User.fromJson(jsonDecode(response.body));
  }
}
