import 'package:flutter/material.dart';
import 'package:flutter_qnote/auth/auth_api.dart';
import 'package:flutter_qnote/widgets/emailPasswordForm.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  //OauthKakaoBox 눌렸는지 확인하는 변수
  bool _isPressed = false;
  String? _enteredEmail;
  String? _enteredPassword;

  void _saveForm(String email, String password) {
    _enteredEmail = email;
    _enteredPassword = password;
  }

  void _handleKakaoLogin() {}
  void _handleLocalLogin(
    String email,
    String password,
    BuildContext context,
  ) async {
    //로그인 시도... 없으면 계정 만들어버리기.

    var loginTry = await AuthApi.getInstance.loginFetch(email, password);
    if (loginTry) {
      Navigator.of(context).pop();
      return;
    }

    await AuthApi.getInstance.createAccount(email, password);
    loginTry = await AuthApi.getInstance.loginFetch(email, password);

    if (!loginTry) {
      print('authscreendart localLogin Exception');
    }

    if (loginTry) {
      Navigator.of(context).pop();
    }
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
                Image.asset('assets/images/qnote_icon.png', width: 200),

                const SizedBox(height: 30),

                EmailPasswordForm(
                  handleLocalLogin: _handleLocalLogin,
                  handleKakaoLogin: _handleKakaoLogin,
                  saveForm: _saveForm,
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
