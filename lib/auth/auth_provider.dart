// import 'package:flutter_qnote/auth/auth_api.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:riverpod/riverpod.dart';

// final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
//   (ref) => AuthNotifier(),
// );

// class AuthState {
//   final String? accessToken;

//   AuthState({this.accessToken});

//   bool get isLoggedIn {
//     return accessToken != null;
//   }

//   AuthState copyWith({String? accessToken}) {
//     return AuthState(accessToken: accessToken ?? this.accessToken);
//   }
// }

// class AuthNotifier extends StateNotifier<AuthState> {
//   final _storage = const FlutterSecureStorage();

//   AuthNotifier() : super(AuthState()) {
//     _initState();
//   }

//   //기존의 secureStorage의, 토큰들을 사용하여, 초기 AuthState를 구축한다.
//   Future<void> _initState() async {
//     final token = await _storage.read(key: 'accessToken');
//     final refresh = await _storage.read(key: 'refreshToken');

//     if (token != null && refresh != null) {
//       final isValid = await isValidAccessToken(token);

//       if (isValid) {
//         state = AuthState(accessToken: token);
//       } else {
//         await tryRefreshToken();
//       }
//     }
//   }

//   Future<void> login(String accessToken, String refreshToken) async {
//     await _storage.write(key: 'accessToken', value: accessToken);
//     await _storage.write(key: 'refreshToken', value: refreshToken);
//     state = AuthState(accessToken: accessToken);
//   }

//   Future<void> logout() async {
//     await _storage.deleteAll();
//     state = AuthState(accessToken: null);
//   }

//   //refreshtoken 을 사용하여, accesstoken 복구 함수.
//   //성공 여부를 Future<bool> 로 반환한다.
//   Future<bool> tryRefreshToken() async {
//     final refresh = await _storage.read(key: 'refreshToken');
//     if (refresh == null) return false;

//     final tokens = await AuthApi.storeToken(refresh);

//     if (tokens != null) {
//       await _storage.write(key: 'accessToken', value: tokens.accessToken);
//       state = state.copyWith(accessToken: tokens.refreshToken);
//       return true;
//     } else {
//       await logout();
//       return false;
//     }
//   }
// }
