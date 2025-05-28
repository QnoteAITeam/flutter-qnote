import 'package:flutter/material.dart';
import 'package:flutter_qnote/auth/auth_api.dart';
import 'package:flutter_qnote/features/login/widgets/login_text_widget.dart';
import 'package:flutter_qnote/features/login/widgets/pressable_fade_button.dart';
import 'package:flutter_qnote/features/login/widgets/sub_title.widget.dart';
import 'package:flutter_qnote/features/login/widgets/title.widget.dart';
import 'package:flutter_qnote/main.dart';
import 'package:flutter_qnote/models/user.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _enteredEmail, _enteredName;
  String? _enteredPassword;
  String? _errorText;

  bool _obscureText = true;

  bool _isLoading = false;

  void _onPressedSignUp() async {
    final isValid = await _formKey.currentState!.validate();
    if (!isValid) return;

    setState(() {
      _isLoading = true;
    });

    _formKey.currentState!.save();
    try {
      final User? response = await AuthApi.getInstance.createAccountWithName(
        _enteredEmail!,
        _enteredPassword!,
        _enteredName!,
      );

      print(response);

      final success = await AuthApi.getInstance.loginFetch(
        _enteredEmail!,
        _enteredPassword!,
      );

      if (success) {
        navigatorKey.currentState!.pushNamedAndRemoveUntil(
          '/',
          (route) => false,
        );
      } else {
        throw new Exception('알 수 없는 오류로 인해 로그인 실패');
      }
    } catch (err) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err.toString()),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Container(
          height: double.infinity,
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 45),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 65),
                  const SubTitle(), //
                  const SizedBox(height: 10),

                  const TitleWidget(),
                  const SizedBox(height: 55),

                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              '회원가입',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 22,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.21,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          style: TextStyle(fontFamily: 'Inter'),
                          decoration: InputDecoration(
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
                          onChanged: (value) {
                            _enteredPassword = value;
                          },
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '비밀번호를 입력해주세요';
                            }

                            if (value.trim().length < 6) {
                              return '비밀번호는 6자 이상이어야 합니다';
                            }

                            return null; // 검증 통과
                          },
                        ),

                        const SizedBox(height: 16),
                        TextFormField(
                          keyboardType: TextInputType.text,
                          style: TextStyle(fontFamily: 'Inter'),
                          obscureText: _obscureText,
                          forceErrorText: _errorText,
                          decoration: InputDecoration(
                            errorStyle: TextStyle(fontFamily: 'Inter'),
                            hintText: '비밀번호를 다시 입력하세요',
                            border: OutlineInputBorder(),
                          ),
                          onSaved: (newValue) {
                            _enteredPassword = newValue;
                          },

                          onChanged: (value) {
                            _formKey.currentState!.validate();
                          },

                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '비밀번호를 입력해주세요';
                            }

                            if (value.trim().length < 6) {
                              return '비밀번호는 6자 이상이어야 합니다';
                            }

                            if (value != _enteredPassword) {
                              return '비밀번호가 일치하지 않습니다.';
                            }

                            return null; // 검증 통과
                          },
                        ),

                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Text(
                              '이름',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 22,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.21,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        TextFormField(
                          keyboardType: TextInputType.text,
                          style: TextStyle(fontFamily: 'Inter'),
                          decoration: InputDecoration(
                            errorStyle: TextStyle(fontFamily: 'Inter'),
                            hintText: '이름이 어떻게 되시나요! >.<',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            _formKey.currentState!.validate();
                          },

                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '이름을 입력해 주세요!';
                            }

                            if (value.contains(' ')) {
                              return '이름에는 공백이 들어갈 수 없습니다!';
                            }

                            return null; // 검증 통과
                          },

                          onSaved: (newValue) {
                            _enteredName = newValue;
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 33),

                  !_isLoading
                      ? PressableFadeButton(
                        signInCallBack: _onPressedSignUp,
                        text: '이메일로 회원가입',
                      )
                      : CircularProgressIndicator(),

                  const SizedBox(height: 33),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
