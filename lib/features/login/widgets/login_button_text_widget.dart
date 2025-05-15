import 'package:flutter/material.dart';

class LoginButtonTextWidget extends StatelessWidget {
  const LoginButtonTextWidget({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
