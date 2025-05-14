import 'package:flutter/material.dart';

class LoginButtonTextWidget extends StatelessWidget {
  const LoginButtonTextWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      '이메일로 로그인',
      style: TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
