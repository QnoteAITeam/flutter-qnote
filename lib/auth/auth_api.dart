import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_qnote/main.dart';
import 'package:flutter_qnote/models/user.dart';
import 'package:flutter_qnote/screens/authscreen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class Tokens {
  String? accessToken;
  String? refreshToken;

  Tokens(this.accessToken, this.refreshToken);

  factory Tokens.from(Map<String, dynamic> json) {
    return Tokens(json['accessToken'], json['accessToken']);
  }
}

class AuthApi {
  final String? baseUrl;

  static AuthApi? _instance;

  AuthApi._internal(this.baseUrl);

  static AuthApi getInstance() {
    if (_instance != null) return _instance!;

    _instance = AuthApi._internal(dotenv.env['API_URL']);
    return _instance!;
  }

  //refreshToken을 활용하여, accessToken 재발급.
  Future<Tokens?> restoreToken(String? refreshToken) async {
    if (refreshToken == null) return null;

    final response = await http.post(
      Uri.parse('$baseUrl/auth/restore'),
      headers: {'Authorization': 'Bearer $refreshToken'},
    );

    if (response.statusCode == 201) {
      final json = jsonDecode(response.body);
      return Tokens(json['accessToken'], json['refreshToken']);
    } else {
      return null;
    }
  }

  Future<String?> getAccessTokenHeader() async {
    const _storage = FlutterSecureStorage();
    String? accessToken = await _storage.read(key: 'accessToken');

    if (accessToken == null) return null;
    return 'Bearer $accessToken';
  }

  Future<void> updateTokens(Tokens tokens) async {
    const _storage = FlutterSecureStorage();

    await _storage.write(key: 'accessToken', value: tokens.accessToken);
    await _storage.write(key: 'refreshToken', value: tokens.refreshToken);
  }

  void logOut() {
    const _storage = FlutterSecureStorage();

    _storage.delete(key: 'accessToken');
    _storage.delete(key: 'refreshToken');
  }

  Future<bool> loginFetch(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/local-login'),
      body: {'email': email, 'password': password},
    );

    if (response.statusCode == 201) {
      final Tokens tokens = Tokens.from(jsonDecode(response.body));
      updateTokens(tokens);
      return true;
    }
    return false;
  }

  Future<User> createAccount(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/signup-local'),
      body: {'email': email, 'password': password},
    );

    return User.fromJson(jsonDecode(response.body));
  }

  Future<String?> getRefreshTokenHeader() async {
    const _storage = FlutterSecureStorage();
    String? refreshToken = await _storage.read(key: 'refreshToken');

    if (refreshToken == null) return null;
    return 'Bearer $refreshToken';
  }

  Future<String?> getAccessToken() async {
    const _storage = FlutterSecureStorage();
    return _storage.read(key: 'accessToken');
  }

  Future<String?> getRefreshToken() async {
    const _storage = FlutterSecureStorage();
    return _storage.read(key: 'refreshToken');
  }

  //사용할 수 없으면, restore까지 할 것이고, 그럼에도 불가능해서, 로그인을 해야하면, false 리턴
  Future<bool> isValidAccessToken() async {
    String? accessTokenHeader = await getAccessTokenHeader();

    if (accessTokenHeader != null) {
      // accessToken을 사용하여 유효성 검사
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login/test'),
        headers: {'Authorization': accessTokenHeader},
      );

      if (response.statusCode == 201) return true;
    }

    String? refreshToken = await getRefreshToken();

    // valid가 false이면 refreshToken을 사용하여 새로운 accessToken을 받음
    if (refreshToken == null) return false;

    final Tokens? tokens = await restoreToken(refreshToken);

    //refreshToken 만료.
    if (tokens == null) return false;

    // 새로운 accessToken과 refreshToken을 저장

    await updateTokens(tokens);
    return true;
  }

  //Do Not Use This Function.
  Future<void> beforeUseAccessToken(BuildContext context) async {
    if (baseUrl == null) {
      print('.env 파일이 진짜 있나요??? 확인해주세요.. 프로젝트 폴더 바로 .env 넣어주세요.');
      throw new FileSystemException('ENV 파일이 있는지 확인해주세요.');
    }

    final isValid = await isValidAccessToken();
    if (!isValid) await popLoginScreen(context);
  }

  //Do Not Use This Function.
  Future<void> popLoginScreen(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return AuthScreen();
        },
      ),
    );
  }

  Future<void> checkTokenAndRedirectIfNeeded() async {
    final isValid = await isValidAccessToken();
    if (!isValid) await navigatorKey.currentState?.pushNamed('/login');
  }
}
