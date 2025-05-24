// lib/features/diary/widgets/diary_detail_app_bar.dart
import 'package:flutter/material.dart';

class DiaryDetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isEditing;       // 현재 일기 수정 모드인지 여부
  final bool isLoading;       // 현재 저장/수정 작업이 로딩 중인지 여부
  final VoidCallback onSave;  // 저장 또는 수정 버튼 클릭 시 실행될 콜백 함수

  const DiaryDetailAppBar({
    Key? key,
    required this.isEditing,
    required this.isLoading,
    required this.onSave,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      // AppBar 제목: 수정 모드 여부에 따라 동적으로 변경
      title: Text(isEditing ? '일기 수정' : '새 일기 작성'),
      // 뒤로 가기 버튼: 클릭 시 이전 화면으로 돌아가기 전 현재 화면의 포커스 해제
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          FocusScope.of(context).unfocus(); // 키보드 숨김 등 포커스 관련 문제 방지
          Navigator.of(context).pop();
        },
      ),
      actions: [
        // 로딩 상태에 따라 다른 위젯 표시
        if (isLoading)
        // 로딩 중일 경우: CircularProgressIndicator 표시
          const Padding(
            padding: EdgeInsets.only(right: 16.0, left: 16.0), // 좌우 패딩으로 AppBar 가장자리와 간격 유지
            child: Center(
              child: SizedBox(
                width: 20,  // 인디케이터 크기
                height: 20, // 인디케이터 크기
                child: CircularProgressIndicator(
                  strokeWidth: 2.5, // 인디케이터 선 두께
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey), // 인디케이터 색상 (AppBar 배경색과 대비되도록)
                ),
              ),
            ),
          )
        else
        // 로딩 중이 아닐 경우: "등록" 또는 "수정" TextButton 표시
          Padding( // TextButton에도 패딩을 주어 터치 영역 확보 및 AppBar 가장자리와 간격 유지
            padding: const EdgeInsets.symmetric(horizontal: 8.0), // 좌우 패딩
            child: TextButton(
              onPressed: onSave, // isLoading이 false일 때만 onSave 콜백 실행
              style: TextButton.styleFrom(
                // 버튼의 최소 크기 및 내부 패딩 설정 (선택 사항)
                // minimumSize: Size(64, 36),
                // padding: EdgeInsets.symmetric(horizontal: 16.0),
                // 버튼 모양 (선택 사항)
                // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
              ),
              child: Text(
                isEditing ? '수정' : '등록',
                style: TextStyle(
                  // AppBar의 actions 텍스트 색상은 현재 테마의 AppBarTheme을 따르거나,
                  // 명시적으로 지정할 수 있습니다.
                  color: Theme.of(context).appBarTheme.actionsIconTheme?.color ??
                      (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white // 어두운 테마일 경우 흰색
                          : Theme.of(context).primaryColorDark), // 밝은 테마일 경우 primaryColorDark 또는 적절한 색상
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight); // 표준 AppBar 높이
}
