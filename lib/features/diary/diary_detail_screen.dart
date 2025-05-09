import 'package:flutter/material.dart';

class DiaryDetailScreen extends StatelessWidget {
  const DiaryDetailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: const Text(
                    '오늘 생각보다 피곤했어. \n\n'
                    '이만 자야겠다. 고생했어, 나😊\n\n',
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('저장하기'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('다른 거 추천하기'),
                  ),
                ),
              ],
            ),
          ),

          BottomNavigationBar(
            currentIndex: 2,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
              BottomNavigationBarItem(
                icon: CircleAvatar(
                  backgroundColor: Color(0xFF4A86F7),
                  child: Icon(Icons.chat_bubble, color: Colors.white),
                ),
                label: '',
              ),
              BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'Schedule'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
            ],
            type: BottomNavigationBarType.fixed,
          ),
        ],
      ),
    );
  }
}
