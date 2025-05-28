import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_qnote/api/dto/get_user_info_dto.dart';
import 'package:flutter_qnote/auth/auth_api.dart';
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
  Future<FetchUserResponseDto> getUserCredential() async {
    await AuthApi.getInstance.checkTokenAndRedirectIfNeeded();

    final response = await http.get(
      Uri.parse('$baseUrl/users/my'),
      headers: {
        'Authorization': (await AuthApi.getInstance.getAccessTokenHeader())!,
      },
    );

    print(response.body);

    return FetchUserResponseDto.fromJson(jsonDecode(response.body));
  }
}
