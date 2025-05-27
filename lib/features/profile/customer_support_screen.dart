import 'package:flutter/material.dart';
import 'package:flutter_qnote/main.dart';

class CustomerSupportScreen extends StatefulWidget {
  const CustomerSupportScreen({super.key});

  @override
  State<CustomerSupportScreen> createState() => _CustomerSupportScreenState();
}

class _CustomerSupportScreenState extends State<CustomerSupportScreen> {
  // 자주 묻는 질문 리스트
  final List<String> faqs = [
    "자주 묻는 질문 1 자주 묻는 질문 1 자주 묻는 질문 1 자주 묻는 질문 1 자주 묻는 질문 1 자주 묻는 질문 1",
    "자주 묻는 질문 2 자주 묻는 질문 2 자주 묻는 질문 2 자주 묻는 질문 2 자주 묻는 질문 2 자주 묻는 질문 2",
  ];

  // 카테고리 정보 리스트
  final List<Map<String, dynamic>> categories = [
    {"icon": Icons.chat_outlined, "label": "대화 백업 / 복원 / 관리"},
    {"icon": Icons.person_outline, "label": "프로필"},
    {"icon": Icons.login_outlined, "label": "로그인 / 인증 / 계정 / 탈퇴"},
    {"icon": Icons.block_outlined, "label": "신고 / 이용제한 / 정책"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "고객센터",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        children: [
          const Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '안녕하세요, ',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: 'Qnote ',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF937B58),
                    fontFamily: 'NanumMyeongjo',
                  ),
                ),
                TextSpan(
                  text: '입니다.\n무엇을 도와드릴까요?',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          TextField(
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: "궁금하신 점을 검색해 보세요.",
              suffixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
          const SizedBox(height: 10),
          const Divider(
            height: 32,
            thickness: 3,
            color: Color(0xFFE0E0E0), // 연한 회색
          ),
          const SizedBox(height: 10),
          _buildFaqSection(),
          const SizedBox(height: 20),
          _buildCategorySection(),
          const Divider(
            height: 32,
            thickness: 3,
            color: Color(0xFFE0E0E0), // 연한 회색
          ),
          _buildInquirySection(),
        ],
      ),
    );
  }

  // 질문 목록
  Widget _buildFaqSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "자주 묻는 질문",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        ...faqs.map((q) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Q. ",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        q,
                        softWrap: true,
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
            ],
          );
        }).toList(),
      ],
    );
  }

  // 카테고리별 구조화
  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "카테고리별로 찾아보세요",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        ...categories.map((c) {
          final isLast = c == categories.last;
          return Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(c["icon"], color: const Color(0xFF937B58)),
                title: Text(c["label"], style: const TextStyle(fontSize: 14)),
                onTap: () {
                  // TODO: 연결할 페이지 추가
                },
              ),
              if (!isLast)
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFE0E0E0),
                ),
            ],
          );
        }).toList(),
      ],
    );
  }

  // 문의 섹션
  Widget _buildInquirySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 10),
        const Text(
          "아직 문제가 해결되지 않으셨나요?",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFE6DED1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.support_agent_outlined,
                  size: 24, color: Color(0xFF937B58)),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "문의하기",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "간편하게 메일로 답변을 받을 수 있어요",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 15),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
            ],
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}
