import 'package:flutter/material.dart';

class DiaryDetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isEditing;
  final bool isLoading;
  final VoidCallback? onSave;

  const DiaryDetailAppBar({
    Key? key,
    required this.isEditing,
    required this.isLoading,
    required this.onSave,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      centerTitle: true,
      title: const Text(
        '일기 저장',
        style: TextStyle(
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
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: isLoading
              ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.grey)),
          )
              : IconButton(
            icon: const Icon(Icons.save_alt_rounded, size: 26, color: Color(0xFFB59A7B)),
            onPressed: onSave,
            tooltip: isEditing ? '수정' : '등록',
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
