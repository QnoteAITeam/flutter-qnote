import 'package:flutter/material.dart';

// 개별 설정 항목 정의
class SettingItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  SettingItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}

// 주제별 설정 모으기
class SettingSection {
  final String title;
  final List<SettingItem> items;

  SettingSection({required this.title, required this.items});
}

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  // 설정 섹션 정의 (주제, 각 설정 리스트)
  final List<SettingSection> sections = [
    SettingSection(
      title: '화면 / 테마',
      items: [
        SettingItem(icon: Icons.image_outlined, title: '배경화면 설정', onTap: () {}),
        SettingItem(icon: Icons.park_outlined, title: '테마 설정', onTap: () {}),
        SettingItem(icon: Icons.text_fields, title: '글자 설정', onTap: () {}),
      ],
    ),
    SettingSection(
      title: '알림',
      items: [
        SettingItem(icon: Icons.notifications_none, title: '알림음 설정', onTap: () {}),
        SettingItem(icon: Icons.access_time_outlined, title: '알림 시간 설정', onTap: () {}),
      ],
    ),
    SettingSection(
      title: '보안',
      items: [
        SettingItem(icon: Icons.vpn_key_outlined, title: '비밀번호 변경', onTap: () {}),
        SettingItem(icon: Icons.lock_outline, title: '잠금 방식', onTap: () {}),
        SettingItem(icon: Icons.fingerprint, title: '생체인증 설정', onTap: () {}),
        SettingItem(icon: Icons.shield_outlined, title: '계정 보안 진단', onTap: () {}),
      ]
    )
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "설정",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: ListView(
        children: sections.map((section) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 37, vertical: 12),
                child: Text(
                  section.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 35),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: section.items.map((item) {
                    final isLast = item == section.items.last;
                    return Column(
                      children: [
                        ListTile(
                          leading: Icon(item.icon, color: const Color(0xFF937B58)),
                          title: Text(
                            item.title,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: item.onTap,
                        ),
                        if (!isLast)
                          const Divider(height: 1, indent: 16, endIndent: 16),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
