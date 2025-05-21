import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_qnote/main.dart';
import 'package:flutter_qnote/models/user.dart';
import 'package:flutter_qnote/screens/authscreen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:kakao_flutter_sdk/kakao_flutter_sdk_talk.dart' as Kakao;
import 'package:kakao_flutter_sdk/kakao_flutter_sdk_template.dart';

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

  static AuthApi get getInstance {
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
    String? accessToken = await _getAccessToken();
    if (accessToken == null) {
      print('AccessToken 꺼냈는데, 없습니다.');
      return null;
    }
    return 'Bearer $accessToken';
  }

  Future<void> _updateTokens(Tokens tokens) async {
    const _storage = FlutterSecureStorage();

    await _storage.write(key: 'accessToken', value: tokens.accessToken);
    await _storage.write(key: 'refreshToken', value: tokens.refreshToken);
  }

  Future<void> logout() async {
    const _storage = FlutterSecureStorage();
    try {
      // 1. 토큰 삭제
      await _storage.delete(key: 'accessToken');
      await _storage.delete(key: 'refreshToken');

      // 2. (선택 사항) 다른 앱 상태 초기화 로직 (Riverpod, Provider 등 사용하는 경우)
      // 예시:
      // _userProvider.resetState(); // 가상의 Riverpod Provider 초기화
      print("User logged out successfully. Tokens deleted.");

    } catch (e) {
      print("Error during logout: $e");
    }
    // 3. (LoginScreen으로 pushAndRemoveUntil 하는 로직은 여기서 하지 않음 - UI 레이어 담당)
    // -> ProfileScreen에서 Navigator 호출
  }


  Future<bool> loginFetch(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/local-login'),
      body: {'email': email, 'password': password},
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final Tokens tokens = Tokens.from(jsonDecode(response.body));
      _updateTokens(tokens);
      return true;
    }

    return false;
  }

  Future<User?> _loginFetchWithKakao(Kakao.OAuthToken token) async {
    // TO DO : Backend에 토큰을 넣어 보내고, 유효성 검사 한뒤 토큰 발급받아 오기.
  }

  Future<Kakao.OAuthToken?> _loginWithKakaoSDK() async {
    // 카카오톡 실행 가능 여부 확인
    // 카카오톡 실행이 가능하면 카카오톡으로 로그인, 아니면 카카오계정으로 로그인
    final bool result = await isKakaoTalkInstalled();
    if (await isKakaoTalkInstalled()) {
      print("카카오톡 있음");
      try {
        final Kakao.OAuthToken token =
            await Kakao.UserApi.instance.loginWithKakaoTalk();

        print('카카오톡으로 로그인 성공');
        return token;
      } catch (error) {
        print('카카오톡으로 로그인 실패 $error');

        // 사용자가 카카오톡 설치 후 디바이스 권한 요청 화면에서 로그인을 취소한 경우,
        // 의도적인 로그인 취소로 보고 카카오계정으로 로그인 시도 없이 로그인 취소로 처리 (예: 뒤로 가기)
        if (error is PlatformException && error.code == 'CANCELED') {
          return null;
        }
        // 카카오톡에 연결된 카카오계정이 없는 경우, 카카오계정으로 로그인
        try {
          final token = await Kakao.UserApi.instance.loginWithKakaoAccount();
          print('카카오계정으로 로그인 성공');
          return token;
        } catch (error) {
          print('카카오계정으로 로그인 실패 $error');
        }
      }
    } else {
      print("카카오톡 없음");
      try {
        Kakao.OAuthToken token =
            await Kakao.UserApi.instance.loginWithKakaoAccount();
        print('카카오계정으로 로그인 성공');
        return token;
      } catch (error) {
        print('카카오계정으로 로그인 실패 $error');
      }
    }

    return null;
  }

  Future<User?> loginWithKakaoTalk() async {
    final token = await _loginWithKakaoSDK();
    if (token == null) return null;

    print(token);

    return _loginFetchWithKakao(token);
  }

  Future<User> createAccount(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/signup-local'),
      body: {'email': email, 'password': password},
    );

    print('System : CreateAccount : result ${response.body}');
    return User.fromJson(jsonDecode(response.body));
  }

  Future<User> createAccountWithName(
    String email,
    String password,
    String username,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users'),
      body: {'email': email, 'password': password, 'username': username},
    );

    if (response.statusCode == 409) {
      throw new Exception(response.body);
    }

    print('System : CreateAccount : result ${response.body}');
    return User.fromJson(jsonDecode(response.body));
  }

  Future<String?> getRefreshTokenHeader() async {
    const _storage = FlutterSecureStorage();
    String? refreshToken = await _storage.read(key: 'refreshToken');

    if (refreshToken == null) return null;
    return 'Bearer $refreshToken';
  }

  Future<String?> _getAccessToken() async {
    const _storage = FlutterSecureStorage();
    return _storage.read(key: 'accessToken');
  }

  Future<String?> _getRefreshToken() async {
    const _storage = FlutterSecureStorage();
    return _storage.read(key: 'refreshToken');
  }

  //사용할 수 없으면, restore까지 할 것이고, 그럼에도 불가능해서, 로그인을 해야하면, false 리턴
  Future<bool> _isValidAccessToken() async {
    String? accessTokenHeader = await getAccessTokenHeader();

    if (accessTokenHeader != null) {
      // accessToken을 사용하여 유효성 검사
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login/test'),
        headers: {'Authorization': accessTokenHeader},
      );

      if (response.statusCode == 201 || response.statusCode == 200) return true;
    }

    String? refreshToken = await _getRefreshToken();

    // valid가 false이면 refreshToken을 사용하여 새로운 accessToken을 받음
    if (refreshToken == null) return false;

    final Tokens? tokens = await restoreToken(refreshToken);

    //refreshToken 만료.
    if (tokens == null) return false;

    // 새로운 accessToken과 refreshToken을 저장

    await _updateTokens(tokens);
    return true;
  }

  //Do Not Use This Function.
  // Future<void> beforeUseAccessToken(BuildContext context) async {
  //   if (baseUrl == null) {
  //     print('.env 파일이 진짜 있나요??? 확인해주세요.. 프로젝트 폴더 바로 .env 넣어주세요.');
  //     throw new FileSystemException('ENV 파일이 있는지 확인해주세요.');
  //   }

  //   final isValid = await isValidAccessToken();
  //   if (!isValid) await popLoginScreen(context);
  // }

  //Do Not Use This Function.
  // Future<void> popLoginScreen(BuildContext context) async {
  //   await Navigator.of(context).push(
  //     MaterialPageRoute(
  //       builder: (context) {
  //         return AuthScreen();
  //       },
  //     ),
  //   );
  // }

  Future<void> checkTokenAndRedirectIfNeeded() async {
    final isValid = await _isValidAccessToken();
    if (!isValid) await navigatorKey.currentState?.pushNamed('/login');
  }
}
