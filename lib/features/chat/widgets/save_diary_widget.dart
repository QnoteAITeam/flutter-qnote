// lib/features/chat/widgets/save_diary_widget.dart
import 'package:flutter/material.dart';

class SaveDiaryWidget extends StatelessWidget {
  final VoidCallback onPressed;

  const SaveDiaryWidget({Key? key, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 40.0, top: 10.0, bottom: 10.0, right: 16.0),
        child: ElevatedButton.icon(
          icon: Icon(Icons.edit_note_outlined, color: Colors.brown.shade700, size: 20),
          label: Text('일기 수정/저장하기', style: TextStyle(color: Colors.brown.shade800, fontWeight: FontWeight.bold, fontSize: 14)),
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEADDCA),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 1,
          ),
        ),
      ),
    );
  }
}
