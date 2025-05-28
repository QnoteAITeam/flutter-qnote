import 'package:flutter/material.dart';

class DiaryDetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isEditing;
  final bool isLoading;
  final VoidCallback? onSave;
  final bool showActionButton;

  const DiaryDetailAppBar({
    Key? key,
    required this.isEditing,
    required this.isLoading,
    required this.onSave,
    this.showActionButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      centerTitle: true,
      title: Text(
        isEditing ? '일기 저장' : '오늘의 일기', // 화면에 따라 타이틀 변경
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
          fontSize: 20,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          FocusScope.of(context).unfocus();
          Navigator.of(context).pop();
        },
      ),
      actions: showActionButton
          ? [
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: isLoading
              ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor:
                AlwaysStoppedAnimation<Color>(Colors.grey)),
          )
              : IconButton(
            icon: const Icon(Icons.save_alt_rounded,
                size: 26, color: Color(0xFFB59A7B)),
            onPressed: onSave,
          ),
        ),
      ]
          : [],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class DiaryScreen extends StatefulWidget {
  final bool isTodayDiaryView; // true면 오늘의 일기, false면 저장/수정
  const DiaryScreen({Key? key, required this.isTodayDiaryView}) : super(key: key);

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  bool _isLoading = false;

  void _onSave() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('저장 완료!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DiaryDetailAppBar(
        isEditing: !widget.isTodayDiaryView, // 저장/수정이면 true
        isLoading: _isLoading,
        onSave: widget.isTodayDiaryView ? null : _onSave,
        showActionButton: !widget.isTodayDiaryView, // 오늘의 일기면 버튼 숨김
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(
    home: DiaryScreen(isTodayDiaryView: true), // 오늘의 일기 화면(버튼 없음)
    // home: DiaryScreen(isTodayDiaryView: false), // 저장/수정 화면(버튼 보임)
  ));
}
