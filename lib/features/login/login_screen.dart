import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_qnote/auth/auth_api.dart';
import 'package:flutter_qnote/features/login/styles/sub_text_button_style.dart';
import 'package:flutter_qnote/features/login/widgets/divider_with_text.dart';
import 'package:flutter_qnote/features/login/widgets/login_button_text_widget.dart';
import 'package:flutter_qnote/features/login/widgets/login_text_widget.dart';
import 'package:flutter_qnote/features/login/widgets/pressable_fade_button.dart';
import 'package:flutter_qnote/features/login/widgets/sub_spacer.dart';
import 'package:flutter_qnote/features/login/widgets/sub_text_button.dart';
import 'package:flutter_qnote/features/login/widgets/sub_title.widget.dart';
import 'package:flutter_qnote/features/login/widgets/title.widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscureText = true;
  bool _isPressedKakao = false;
  bool _isPressedGoogle = false;
  bool _isPreseedSignIn = false;

  String? _enteredEmail;
  String? _enteredPassword;
  String? _errorText;

  final _formKey = GlobalKey<FormState>();

  void _onPressedSignUp() {
    //
  }

  void _onPressedFindEmail() {
    //
  }

  void _onPressedFindPassword() {
    //
  }

  void _onPreseedKakaoLogin() {
    //
  }

  void _onPressedGoogleLogin() {
    //
  }

  bool _isLoggingIn = false;

  void _onPressedSignIn() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) return;

    setState(() {
      _isLoggingIn = true;
    });

    bool isSuccess = await AuthApi.getInstance.loginFetch(
      _enteredEmail!,
      _enteredPassword!,
    );

    setState(() {
      _isLoggingIn = false;
    });

    if (isSuccess) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          height: double.infinity,
          width: double.infinity,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 45),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 65),
                const SubTitle(), //
                const SizedBox(height: 10),

                const TitleWidget(),
                const SizedBox(height: 55),
                const LoginTextWidget(),
                const SizedBox(height: 33),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        style: TextStyle(fontFamily: 'Inter'),
                        decoration: InputDecoration(
                          errorText: _errorText,
                          errorStyle: TextStyle(fontFamily: 'Inter'),
                          hintText: '이메일을 입력하세요',
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.blue,
                              width: 2,
                            ),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,

                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            _errorText = null;
                            return '이메일을 입력해주세요';
                          }

                          // 이메일 형식 정규식 (간단하고 실용적인 버전)
                          final emailRegExp = RegExp(
                            r'^[\w\.-]+@[\w\.-]+\.\w+$',
                          );
                          if (!emailRegExp.hasMatch(value.trim())) {
                            _errorText = null;
                            return '올바른 이메일 형식을 입력해주세요';
                          }

                          return null; // 검증 통과
                        },

                        onSaved: (newValue) {
                          _enteredEmail = newValue;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        keyboardType: TextInputType.text,
                        style: TextStyle(fontFamily: 'Inter'),
                        obscureText: _obscureText,
                        decoration: InputDecoration(
                          errorStyle: TextStyle(fontFamily: 'Inter'),
                          hintText: '비밀번호를 입력하세요',
                          border: OutlineInputBorder(),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscureText ^= true;
                              });
                            },
                            icon: Icon(
                              _obscureText
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '비밀번호를 입력해주세요';
                          }

                          if (value.trim().length < 6) {
                            return '비밀번호는 6자 이상이어야 합니다';
                          }

                          return null; // 검증 통과
                        },

                        onSaved: (newValue) {
                          _enteredPassword = newValue;
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 60),

                //이메일로 로그인 위젯 컨테이너.
                PressableFadeButton(signInCallBack: _onPressedSignIn),

                const SizedBox(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _onPressedSignUp,
                      style: sub_text_button_style,
                      child: const SubTextButton(text: '회원가입'),
                    ),

                    const SubSpacer(),
                    ElevatedButton(
                      onPressed: _onPressedFindEmail,
                      style: sub_text_button_style,
                      child: const SubTextButton(text: '이메일 찾기'),
                    ),
                    const SubSpacer(),
                    ElevatedButton(
                      onPressed: _onPressedFindPassword,
                      style: sub_text_button_style,
                      child: const SubTextButton(text: '비밀번호 찾기'),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                const DividerWithText(text: '간편 로그인'),

                const SizedBox(height: 20),

                // 이 InkWell 하나는 카카오 이미지 하나임.
                InkWell(
                  onTap: _onPreseedKakaoLogin,
                  onHighlightChanged: (value) {
                    setState(() {
                      _isPressedKakao = value;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        _isPressedKakao
                            ? Colors.black.withValues(alpha: 0.2)
                            : Colors.transparent,
                        BlendMode.darken,
                      ),
                      child: Image.asset(
                        'assets/images/kakao_login_large_wide.png',
                        width: 300,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                InkWell(
                  onTap: _onPressedGoogleLogin,
                  onHighlightChanged: (value) {
                    setState(() {
                      _isPressedGoogle = value;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        _isPressedGoogle
                            ? Colors.black.withValues(alpha: 0.2)
                            : Colors.transparent,
                        BlendMode.darken,
                      ),
                      child: Image.asset(
                        'assets/images/google_login_large_wide.png',
                        width: 300,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
