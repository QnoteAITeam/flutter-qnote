import 'package:flutter/material.dart';

class SubTitle extends StatelessWidget {
  const SubTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      '나만의 AI Assistance',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: const Color(0xFF6E6E6E),
        fontSize: 20,
        fontFamily: 'Inter',
        fontWeight: FontWeight.w500,
        height: 2,
        letterSpacing: -0.21,
      ),
    );
  }
}
