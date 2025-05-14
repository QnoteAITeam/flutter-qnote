import 'package:flutter/material.dart';

class LoginTextWidget extends StatelessWidget {
  const LoginTextWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      '로그인',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.black,
        fontSize: 19.23,
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
        letterSpacing: -0.21,
      ),
    );
  }
}
