import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_qnote/api/api_service.dart';
import 'package:flutter_qnote/api/dto/send_message_dto.dart';
import 'package:flutter_qnote/auth/auth_api.dart';
import 'package:flutter_qnote/features/diary/diary_detail_screen.dart';
import 'package:flutter_qnote/models/chat_session.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  //아래 입력바 지켜 보고 있는 Controller
  final _textController = TextEditingController();

  //세션만들어지는 동안, 로딩화면 띄울려고 확인하는 변수
  bool _isCreatingSession = true;

  //현재 ChatScreen의 채팅방의 정보. 이 변수로 아직 아무것도 안함 그냥 일단 정보 저장용 변수.
  late ChatSession _chatSession;

  //chatMessages 리스트 안에는, SendMessageDto로 구성되어, 정보들이 있다.
  final List<SendMessageDto> chatMessages = [];

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    await AuthApi.beforeUseAccessToken(context);
    _chatSession = await ApiService.createNewSession();

    print('현재 보내는 채팅 세션은, ChatSession Primary_ID = ${_chatSession.id} 입니다.');

    setState(() {
      _isCreatingSession = false;
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onPressedSendButton() async {
    final data = _textController.text;
    if (data.isEmpty || data.trim().length == 0) return;

    _textController.clear();

    final response = await ApiService.sendMessageToAI(data);

    setState(() {
      chatMessages.add(SendMessageDto.fromMessageByUser(data));
      chatMessages.add(response);

      // chatMessages.forEach((value) {
      //   print(jsonEncode(value));
      // });
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Align(
            alignment: Alignment.topLeft,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '안녕! 오늘 하루 어땠어? 😊',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),

        const Spacer(),

        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildOptionButton(
                context,
                '어 나 생각보다 피곤해',
                onTap: () => _navigateToDiaryDetail(context),
              ),
              const SizedBox(height: 12),
              _buildOptionButton(
                context,
                '오늘은 그냥 지치고 피곤해',
                onTap: () => _navigateToDiaryDetail(context),
              ),
              const SizedBox(height: 12),
              _buildOptionButton(
                context,
                '오늘 하루은 잘 버텼어',
                onTap: () => _navigateToDiaryDetail(context),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: '직접 입력하기',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          border: InputBorder.none,
                        ),

                        controller: _textController,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.mic, color: Colors.blue),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.blue),
                      onPressed: _onPressedSendButton,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        BottomNavigationBar(
          currentIndex: 2,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: '검색'),
            BottomNavigationBarItem(
              icon: CircleAvatar(
                backgroundColor: Color(0xFF4A86F7),
                child: Icon(Icons.chat_bubble, color: Colors.white),
              ),
              label: '',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.schedule), label: '일정'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: '내 계정'),
          ],
          type: BottomNavigationBarType.fixed,
        ),
      ],
    );

    if (_isCreatingSession) {
      content = Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: content,
    );
  }

  Widget _buildOptionButton(
    BuildContext context,
    String text, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFE6F0FF),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            const Icon(Icons.circle, size: 10, color: Color(0xFF4A86F7)),
            const SizedBox(width: 12),
            Text(text, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  void _navigateToDiaryDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DiaryDetailScreen()),
    );
  }
}
