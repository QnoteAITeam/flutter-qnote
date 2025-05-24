// lib/features/dashboard/widgets/dashboard_app_bar.dart
import 'package:flutter/material.dart';

class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DashboardAppBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: Size.fromHeight(MediaQuery.of(context).padding.top + 60),
      child: Container(
        width: double.infinity,
        color: const Color(0xFFB59A7B),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: MediaQuery.of(context).padding.top + 10,
          bottom: 10,
        ),
        child: const Text.rich(
          TextSpan(children: [
            TextSpan(
              text: '나만의 AI Assistance, ',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            TextSpan(
              text: 'Qnote',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                fontFamily: 'NanumMyeongjo',
              ),
            ),
          ]),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 20); // AppBar 높이 조절
}
