import 'package:flutter/material.dart';

final sub_text_button_style = ButtonStyle(
  backgroundColor: WidgetStateProperty.all(Colors.transparent), // 배경 투명
  shadowColor: WidgetStateProperty.all(Colors.transparent), // 그림자 제거
  overlayColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
    if (states.contains(WidgetState.pressed)) {
      return Colors.grey.withAlpha(80); // 물결 색
    }
    return null; // 기본 없음
  }),
  elevation: WidgetStateProperty.all(0), // 그림자 높이 제거
  padding: WidgetStateProperty.all(EdgeInsets.zero),
);
