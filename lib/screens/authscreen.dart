import 'package:flutter/material.dart';
import 'package:flutter_qnote/widgets/emailPasswordForm.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  //OauthKakaoBox 눌렸는지 확인하는 변수
  bool _isPressed = false;

  void _handleKakaoLogin() {
    //카카오 Oauth 인증해서 accessToken 받으면 서버로 날려서, 우리만의 전용토큰을 전역 provider에다가 넣고 상태 관리를 할 것임.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,

      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 90, horizontal: 75),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/qnote_icon.png', width: 200),

                const SizedBox(height: 30),

                const EmailPasswordForm(),
                //
                InkWell(
                  onTap: _handleKakaoLogin,
                  onHighlightChanged: (value) {
                    setState(() {
                      _isPressed = value;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        _isPressed
                            ? Colors.black.withValues(alpha: 0.2)
                            : Colors.transparent,
                        BlendMode.darken,
                      ),
                      child: Image.asset(
                        'assets/kakao_login_large_wide.png',
                        width: 300,
                      ),
                    ),
                  ),
                ),
                //
              ],
            ),
          ),
        ),
      ),
    );
  }
}
