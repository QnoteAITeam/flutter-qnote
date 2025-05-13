// lib/features/dashboard/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_qnote/features/chat/chat_screen.dart';
import 'package:flutter_qnote/widgets/calendar_widget.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // FontAwesome 아이콘 사용 시 주석 해제
import 'package:flutter_qnote/features/search/search_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _flameCount = 0;
  int _currentIndex = 0; // 하단 네비게이션 바 현재 인덱스

  // 이미지의 "OOO님"을 위한 임시 사용자 이름
  final String _userName = "사용자"; // 실제로는 로그인 정보에서 가져와야 함

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFB59A7B), // 이미지의 갈색 배경
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: SafeArea( // SafeArea를 헤더 부분에만 적용
        bottom: false, // 하단 SafeArea는 Scaffold에서 처리
        child: Text.rich(
          TextSpan(
            children: [
              const TextSpan(
                text: '나만의 AI Assistance, ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  // fontFamily: 'SingleDay', // 필요시 폰트 적용
                ),
              ),
              TextSpan(
                text: 'Qnote',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26, // Qnote 폰트 크기 키움
                  fontWeight: FontWeight.bold,
                  fontFamily: 'NanumMyeongjo', // Qnote에 적용된 폰트
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildGreetingCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$_userName님, 오늘은 어떤 하루였나요? 😊',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '오늘 하루는 무슨 일들이 있었는지 저에게 알려주세요!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 화면 상단 부분 (Qnote 헤더 + 인사말 카드)은 스크롤되지 않음
    // 그 아래 내용 (작성횟수, 캘린더, 일기요약)은 스크롤 가능
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8), // 화면 전체 배경색
      body: Column( // SafeArea를 여기에 적용하지 않고, _buildHeader 내부에 적용
        children: [
          _buildHeader(),
          _buildGreetingCard(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16), // 좌우 패딩
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // "이번주에 총 N회 작성했어요!" 위치 적용
                  Padding(
                    padding: const EdgeInsets.only(top: 0, bottom: 16), // 간격 조정
                    child: Text(
                      '이번 주에 총 $_flameCount회 작성했어요!',
                      style: const TextStyle( // NanumMyeongjo 대신 기본 폰트 또는 다른 어울리는 폰트
                        fontSize: 18,         // 이미지에 맞게 크기 조정
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  CalendarWidget(
                    onFlameCountChanged: (count) {
                      setState(() {
                        _flameCount = count;
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  // "오늘의 일기 요약" 섹션
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.15),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '오늘의 일기 요약',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          '오늘 생각보다 피곤했어.\n'
                              '이만 자야겠다. 고생했어, 나😊',
                          style: TextStyle(fontSize: 15, height: 1.5, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24), // 하단 여백
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: Colors.black, // 선택된 아이콘 색
        unselectedItemColor: Colors.grey.shade500, // 선택되지 않은 아이콘 색
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        onTap: (idx) {
          if (idx == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            );
          } else if (idx == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatScreen()),
            );
          }
        },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: '홈'),
          const BottomNavigationBarItem(icon: Icon(Icons.search), label: '검색'),
          BottomNavigationBarItem(
            icon: Container( // 이미지의 가운데 큰 버튼과 유사하도록 조정
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFB59A7B), // 이미지의 갈색과 유사하도록 조정
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit_outlined, color: Colors.white, size: 28), // 펜 아이콘
            ),
            label: '', // 라벨 없음
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.schedule), label: '일정'),
          const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: '프로필'),
        ],
      ),
    );
  }
}
