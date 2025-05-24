// lib/features/diary/widgets/diary_text_field_widget.dart
import 'package:flutter/material.dart';

class DiaryTextFieldWidget extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final TextInputType keyboardType;
  final bool enabled;
  final bool readOnly;
  final Widget? suffixIcon;
  final Color fieldBackgroundColor;
  final double fieldFontSize;
  final String? Function(String?)? validator; // <<<--- validator 파라미터 추가

  const DiaryTextFieldWidget({
    Key? key,
    required this.controller,
    required this.hintText,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.enabled = true,
    this.readOnly = false,
    this.suffixIcon,
    required this.fieldBackgroundColor,
    required this.fieldFontSize,
    this.validator, // <<<--- 생성자에 validator 추가
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding( // TextFormField는 자체적으로 패딩을 잘 처리하지 못하므로, Container 대신 Padding으로 감싸는 것이 좋을 수 있음
      padding: const EdgeInsets.symmetric(vertical: 8.0), // 위아래 여백을 줌 (이전 Container의 역할 일부 대체)
      child: TextFormField( // TextField 대신 TextFormField 사용
        controller: controller,
        enabled: enabled,
        readOnly: readOnly,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: fieldFontSize, color: enabled ? Colors.black87 : Colors.grey.shade700), // 비활성화 시 텍스트 색상 변경
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: fieldFontSize),
          filled: true, // 배경색을 채우도록 설정
          fillColor: enabled ? fieldBackgroundColor : Colors.grey.shade200, // 비활성화 시 배경색 연하게
          border: OutlineInputBorder( // 테두리 스타일 지정
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 0.8), // 기본 테두리
          ),
          enabledBorder: OutlineInputBorder( // 활성화 상태 테두리
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.grey.shade400, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder( // 포커스 상태 테두리
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
          ),
          errorBorder: OutlineInputBorder( // 에러 상태 테두리
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 1.2),
          ),
          focusedErrorBorder: OutlineInputBorder( // 포커스된 에러 상태 테두리
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 1.8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0), // 내부 content 패딩
          suffixIcon: suffixIcon,
          errorStyle: TextStyle(fontSize: 12.0, height: 0.8), // 에러 메시지 스타일 (높이 조절로 간격 확보)
        ),
        validator: validator, // <<<--- 전달받은 validator 연결
        autovalidateMode: AutovalidateMode.onUserInteraction, // 사용자 상호작용 시 자동 유효성 검사
      ),
    );
  }
}
