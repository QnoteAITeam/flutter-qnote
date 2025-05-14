import 'package:flutter/material.dart';

class TitleWidget extends StatelessWidget {
  const TitleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Qnote',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.black,
        fontSize: 40,
        fontFamily: 'NanumMyeongjo',
        fontWeight: FontWeight.w800,
        letterSpacing: -0.16,
      ),
    );
  }
}
