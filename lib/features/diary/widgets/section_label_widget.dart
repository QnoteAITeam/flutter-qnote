// lib/features/diary/widgets/section_label_widget.dart
import 'package:flutter/material.dart';

class SectionLabelWidget extends StatelessWidget {
  final String label;
  final double topPadding;
  final double bottomPadding;

  const SectionLabelWidget({
    Key? key,
    required this.label,
    this.topPadding = 16.0, // 기본 상단 패딩
    this.bottomPadding = 8.0, // 기본 하단 패딩
  }) : super(key: key);

  // DiaryDetailScreenState의 스타일 값을 상수로 참조하거나 여기서 직접 정의
  static const double _labelFontSize = 16.0;
  static const FontWeight _labelFontWeight = FontWeight.bold;
  static const Color _labelTextColor = Colors.black87;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: _labelFontSize,
          fontWeight: _labelFontWeight,
          color: _labelTextColor,
        ),
      ),
    );
  }
}
