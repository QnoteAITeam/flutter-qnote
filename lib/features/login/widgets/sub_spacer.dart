import 'package:flutter/material.dart';

class SubSpacer extends StatelessWidget {
  const SubSpacer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(width: 1, color: Color(0xFFB3B3B3))),
      ),
      child: const SizedBox(height: 17),
    );
  }
}
