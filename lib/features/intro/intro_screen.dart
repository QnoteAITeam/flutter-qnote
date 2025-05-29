import 'package:flutter/material.dart';
import 'package:flutter_qnote/features/login/login_screen.dart';

class IntroScreen extends StatefulWidget {
  @override
  _IntroScreenState createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> tutorialData = const [
    {
      'image': 'assets/images/intro_1.png',
      'title': 'AI가 질문을 통해 당신의 하루를 들어요',
      'subtitle': '매일매일 AI가 당신과 대화를 이어가요',
    },
    {
      'image': 'assets/images/intro_2.png',
      'title': '감정, 활동, 사건 등을 정리해요',
      'subtitle': '오늘 하루 나의 감정을 일기로 정리해봐요',
    },
    {
      'image': 'assets/images/intro_3.png',
      'title': '나만의 스타일로 일기를 완성해줘요',
      'subtitle': 'AI가 스스로 일기를 요약해서 정리해줘요',
    },
  ];

  void _nextPage() async {
    if (_currentPage < tutorialData.length - 1) {
      _controller.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // 로그인 화면으로 이동 (Navigator)
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/dashboard', (Route<dynamic> route) => false);
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _controller.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 4),
          width: 20,
          height: 6,
          decoration: BoxDecoration(
            color:
                _currentPage == index ? Color(0xFF7B5D3B) : Color(0xFFE7DCCF),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.65,
            child: PageView.builder(
              controller: _controller,
              itemCount: tutorialData.length,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemBuilder: (context, index) {
                final item = tutorialData[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Image.asset(item['image']!, fit: BoxFit.contain),

                      const SizedBox(height: 40),

                      Text(
                        item['title']!,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item['subtitle']!,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                );
              },
            ),
          ),

          _buildPageIndicator(),
          const Spacer(),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Row(
              mainAxisAlignment:
                  _currentPage == 0
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.spaceBetween,
              children: [
                if (_currentPage != 0)
                  TextButton(
                    onPressed: _previousPage,

                    child: Text(
                      _currentPage == 0 ? '' : '이전',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),

                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                  ),

                ElevatedButton(
                  onPressed: _nextPage,

                  child: Text(
                    _currentPage == tutorialData.length - 1 ? '시작하기' : '다음',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown[200],
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 50),
        ],
      ),
    );
  }
}
