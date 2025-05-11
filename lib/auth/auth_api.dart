import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_qnote/screens/authscreen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class Tokens {
  String? accessToken;
  String? refreshToken;

  Tokens(this.accessToken, this.refreshToken);
}

class AuthApi {
  static String baseUrl = 'http://localhost:3000';

  //refreshToken을 활용하여, accessToken 재발급.
  static Future<Tokens?> storeToken(String? refreshToken) async {
    if (refreshToken == null) return null;

    final response = await http.post(
      Uri.parse('$baseUrl/auth/restore'),
      headers: {'Authorization': 'Bearer $refreshToken'},
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return Tokens(json['accessToken'], json['refreshToken']);
    } else {
      return null;
    }
  }

  static Future<String?> getAccessTokenHeader() async {
    const _storage = FlutterSecureStorage();
    String? accessToken = await _storage.read(key: 'accessToken');

    if (accessToken == null) return null;
    return 'Bearer $accessToken';
  }

  static Future<String?> getRefreshTokenHeader() async {
    const _storage = FlutterSecureStorage();
    String? refreshToken = await _storage.read(key: 'refreshToken');

    if (refreshToken == null) return null;
    return 'Bearer $refreshToken';
  }

  static Future<String?> getAccessToken() async {
    const _storage = FlutterSecureStorage();
    return _storage.read(key: 'accessToken');
  }

  static Future<String?> getRefreshToken() async {
    const _storage = FlutterSecureStorage();
    return _storage.read(key: 'refreshToken');
  }

  //사용할 수 없으면, restore까지 할 것이고, 그럼에도 불가능해서, 로그인을 해야하면, false 리턴
  static Future<bool> isValidAccessToken() async {
    String? accessTokenHeader = await getAccessTokenHeader();

    if (accessTokenHeader != null) {
      // accessToken을 사용하여 유효성 검사
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login/test'),
        headers: {'Authorization': accessTokenHeader},
      );

      if (response.statusCode == 200) return true;
    }

    String? refreshToken = await getRefreshToken();

    // valid가 false이면 refreshToken을 사용하여 새로운 accessToken을 받음
    if (refreshToken == null) return false;

    final Tokens? tokens = await storeToken(refreshToken);

    //refreshToken 만료.
    if (tokens == null) return false;

    // 새로운 accessToken과 refreshToken을 저장

    const _storage = FlutterSecureStorage();

    _storage.write(
      key: 'accessToken',
      value: tokens.accessToken, //
    );

    _storage.write(key: 'refreshToken', value: tokens.refreshToken);

    return true;
  }

  static void beforeUseAccessToken(BuildContext context) async {
    final isValid = await isValidAccessToken();
    if (!isValid) popLoginScreen(context);
  }

  static void popLoginScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return AuthScreen();
        },
      ),
    );
  }
}
