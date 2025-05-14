import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_qnote/auth/auth_api.dart';
import 'package:flutter_qnote/models/user.dart';
import 'package:http/http.dart' as http;

class UserApi {
  final String? baseUrl;
  static UserApi? _instance;

  UserApi._internal(this.baseUrl);

  static UserApi get instance {
    if (_instance != null) return _instance!;
    _instance = UserApi._internal(dotenv.env['API_URL']);
    return _instance!;
  }

  //기본적인 유저의 정보를 관리합니다.
  Future<User> getUserCredential() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/my'),
      headers: {
        'Authorization': (await AuthApi.getInstance().getAccessTokenHeader())!,
      },
    );

    return User.fromJson(jsonDecode(response.body));
  }
}
