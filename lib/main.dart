// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_qnote/features/dashboard/dashboard_screen.dart';
import 'package:flutter_qnote/features/login/login_screen.dart';
import 'package:flutter_qnote/features/login/signup_screen.dart';
import 'package:flutter_qnote/features/login/terms_agreement_screen.dart';
// import 'package:flutter_qnote/features/login/terms_agreement_screen.dart'; // 현재 사용 안 함
import 'package:flutter_qnote/features/splash/splash_screen.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk_share.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // 추가

final colorScheme = ColorScheme.fromSeed(
  seedColor: const Color.fromARGB(255, 124, 124, 255),
  surface: const Color.fromARGB(255, 160, 160, 255),
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  KakaoSdk.init(nativeAppKey: dotenv.env['KAKAO_NATIVE_APP_KEY']);
  await initializeDateFormatting('ko_KR', null); // 한국어 로케일 초기화
  runApp(const MyApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      initialRoute: '/',

      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/agreement': (context) => const TermsAgreementScreen(), // 로그인 화면으로 대체
        '/signup': (context) => const SignupScreen(), // 회원가입 화면으로 대체
        '/dashboard': (context) => const DashboardScreen(), // 대시보드 화면으로 대체
      },

      title: 'Qnote',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
        fontFamily: 'InterVariable', // 기본 폰트 설정
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
        ),
      ),

      // --- MaterialLocalizations 설정 추가 ---
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate, // Cupertino 위젯용 (선택적)
      ],
      supportedLocales: const [
        Locale('ko', 'KR'), // 한국어 지원
        Locale('en', ''), // 영어 지원 (기본값)
        // 다른 지원 언어 추가 가능
      ],
      locale: const Locale('ko', 'KR'), // 기본 로케일을 한국어로 설정 (선택적)
      // ------------------------------------
    );
  }
}
