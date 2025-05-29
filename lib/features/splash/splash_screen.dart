import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_qnote/features/dashboard/dashboard_screen.dart';
import 'package:flutter_qnote/features/intro/intro_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initAsync();
  }

  Future<void> _initAsync() async {
    final secureStorage = const FlutterSecureStorage();
    String? hasSeen = await secureStorage.read(key: 'hasSeenIntro');

    if (hasSeen == 'true') {
      print('SplahScreen: User has seen intro, navigating to Dashboard');

      Timer(const Duration(milliseconds: 1500), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      });
    } else {
      print('SplashScreen: User has not seen intro, navigating to IntroScreen');
      Timer(const Duration(milliseconds: 1500), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => IntroScreen()),
        ).then((value) async {
          print('사용자의 소개 화면을 본 후, hasSeenIntro 값을 true로 설정합니다.');
          await secureStorage.write(key: 'hasSeenIntro', value: 'true');
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logoicon.png', width: 100, height: 100),
            const SizedBox(height: 24),
            const Text(
              'Qnote',
              style: TextStyle(
                fontFamily: 'NanumMyeongjo',
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '나만의 AI Assistance',
              style: TextStyle(
                fontFamily: 'SingleDay',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
