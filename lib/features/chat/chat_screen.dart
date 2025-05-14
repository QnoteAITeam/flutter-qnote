// lib/features/chat/chat_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_qnote/api/api_service.dart';
import 'package:flutter_qnote/api/dto/send_message_dto.dart';
import 'package:flutter_qnote/auth/auth_api.dart';
import 'package:flutter_qnote/features/diary/diary_detail_screen.dart';
import 'package:flutter_qnote/models/chat_session.dart';

enum InitialViewMode { full, aiMessageOnly, optionsOnly }

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textController = TextEditingController();
  bool _isCreatingSession = true;
  // late ChatSession _chatSession;
  final List<SendMessageDto> chatMessages = [];

  // AI 아바타 SVG 사용하도록 수정
  final Widget aiAvatar = CircleAvatar(
    backgroundColor: Colors.grey[300],
    child: Icon(Icons.smart_toy_outlined, color: Colors.blue[700]), // 임시 아이콘
    // backgroundImage: AssetImage('assets/images/ai_avatar.png'), // 실제 에셋 사용 시 주석 해제
  );

  // 메시지 옆 작은 아바타 SVG
  final Widget smallAiAvatar = CircleAvatar(
    backgroundColor: Colors.grey[300],
    child: Icon(Icons.smart_toy_outlined, color: Colors.blue[700]), // 임시 아이콘
    // backgroundImage: AssetImage('assets/images/ai_avatar.png'), // 실제 에셋 사용 시 주석 해제
  );

  @override
  void initState() {
    super.initState();
    _checkAuthAndInitializeChat();
  }

  Future<void> _checkAuthAndInitializeChat() async {
    // 시뮬레이션을 위해 _isCreatingSession 상태만 변경하고 초기 메시지 추가
    // 실제 앱에서는 여기서 await ApiService.createNewSession() 등을 호출하여
    // _chatSession을 설정하고, 필요한 초기 데이터를 로드할 수 있습니다.
    try {
      // _chatSession = await ApiService.createNewSession(); // 실제 세션 생성 예시
      await Future.delayed(const Duration(seconds: 1)); // 세션 생성 시간 시뮬레이션

      if (mounted) {
        setState(() {
          // chatMessages 리스트가 비어있을 경우에만 초기 AI 질문 메시지를 추가합니다.
          if (chatMessages.isEmpty) {
            chatMessages.add(
              SendMessageDto(
                role:
                    MessageRole
                        .assistance, // send_message_dto.dart의 enum과 일치 확인
                state: MessageState.asking, // AI가 질문하는 상태임을 명시
                message: '안녕! 오늘 아침 뭐 먹었어? 😊',
              ),
            );
          }
          _isCreatingSession = false; // 세션 생성 완료 (로딩 UI 종료)
        });
      }
    } catch (e) {
      print("Error initializing chat session: $e");
      if (mounted) {
        setState(() {
          chatMessages.add(
            SendMessageDto(
              role: MessageRole.system,
              state: MessageState.done,
              message: "채팅을 시작하는 중 오류가 발생했습니다.",
            ),
          );
          _isCreatingSession = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onPressedSendButton() async {
    final data = _textController.text;
    if (data.trim().isEmpty) return;

    final userMessage = SendMessageDto.fromMessageByUser(data);

    if (mounted) {
      setState(() {
        chatMessages.add(userMessage);
      });
    }

    _textController.clear();
    FocusScope.of(context).unfocus();

    try {
      // 2. ApiService를 통해 실제 AI 서버에 메시지 전송 및 응답 받기
      //    ApiService.sendMessageToAI는 SendMessageDto를 반환한다고 가정
      //    서버에 보낼 때는 사용자가 입력한 'data' 문자열만 필요할 수 있음,
      //    또는 SendMessageDto 객체 전체를 보낼 수도 있음 (API 설계에 따라 다름)

      // NOTE: 'data'만 전달해도 서버 측에서 SendMessageDto 형태로 응답을 반환함.
      //       반환된 aiResponseFromServer는 그대로 사용 가능.
      final SendMessageDto aiResponseFromServer = await ApiService.instance
          .sendMessageToAI(data); // 또는 userMessage 객체

      // 3. 서버로부터 받은 AI 응답(SendMessageDto)을 화면에 표시
      if (mounted) {
        setState(() {
          chatMessages.add(aiResponseFromServer);
        });
      }
    } catch (e) {
      print("Error sending message to AI: $e");
      if (mounted) {
        // 오류 발생 시 더미 메시지 또는 시스템 메시지 사용 가능
        // chatMessages.add(SendMessageDto.dummy()); // 더미 메시지 사용 예시
        chatMessages.add(
          SendMessageDto(
            role: MessageRole.system, // 또는 MessageRole.assistant
            state: MessageState.done, // 혹은 오류 상태를 나타내는 enum 값이 있다면 그것 사용
            message: "죄송합니다, AI와 대화 중 문제가 발생했습니다.",
          ),
        );
        setState(() {}); // chatMessages 리스트 변경 후 UI 갱신
      }
    }
  }

  void _onOptionTapped(String optionText) async {
    final userMessage = SendMessageDto.fromMessageByUser(optionText);
    if (mounted) {
      setState(() {
        chatMessages.add(userMessage);
      });
    }

    try {
      // ApiService를 통해 선택된 옵션 텍스트를 AI 서버로 전송
      // ApiService.sendMessageToAI 메소드가 SendMessageDto를 인자로 받거나,
      // 혹은 String을 인자로 받는 새로운 메소드가 필요할 수 있습니다.
      // 여기서는 data 대신 optionText를 사용한다고 가정합니다.
      final SendMessageDto aiResponseFromServer = await ApiService.instance
          .sendMessageToAI(optionText); // 또는 적절한 DTO를 만들어서 전달

      // (선택 사항) "AI가 입력 중..." 메시지 제거 (만약 추가했다면)
      // setState(() {
      //   chatMessages.removeLast(); // 혹은 다른 방식으로 해당 메시지 제거
      // });

      // 서버로부터 받은 실제 AI 응답을 화면에 추가
      if (mounted) {
        setState(() {
          chatMessages.add(aiResponseFromServer);
        });
      }
    } catch (e) {
      String errorMessage = "죄송합니다, 응답을 가져오는 데 문제가 발생했습니다.";
      if (e.toString().contains('Authorization Token is missing')) {
        errorMessage = "로그인이 필요한 서비스입니다. 다시 로그인해주세요.";
        // 필요하다면 여기서 AuthApi.popLoginScreen(context) 호출 고려
      } else if (e.toString().contains('Failed to parse AI response')) {
        errorMessage = "AI의 답변을 이해하는 데 실패했습니다.";
      } else if (e.toString().contains('Received empty response from server')) {
        errorMessage = "서버로부터 응답이 없습니다.";
      }
      print("Error sending message/option to AI: $e");
      if (mounted) {
        setState(() {
          chatMessages.add(
            SendMessageDto(
              role: MessageRole.system,
              state: MessageState.done,
              message: errorMessage,
            ),
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black54),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            // AppBar에 표시될 AI 아바타 (SVG)
            // CircleAvatar로 감싸서 원형으로 만들거나, SVG 자체가 원형이면 그대로 사용
            ClipOval(child: aiAvatar), // 만약 SVG가 사각형이고 원형으로 자르고 싶다면
            // aiAvatar, // SVG가 이미 원형 디자인이라면 ClipOval 없이 사용
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI 챗봇',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '당신의 하루를 저에게 알려주세요!',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
      body:
          _isCreatingSession
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: chatMessages.length,
                      itemBuilder: (context, index) {
                        final msg = chatMessages[index];
                        bool isAiMessage = msg.role == MessageRole.assistance;

                        bool isInitialForAvatar =
                            isAiMessage &&
                            chatMessages
                                    .where(
                                      (m) => m.role == MessageRole.assistance,
                                    )
                                    .toList()
                                    .indexOf(msg) ==
                                0;
                        return _buildChatMessageBubble(
                          msg.message ?? "...",
                          DateTime.now(), // 임시 타임스탬프 (UI 모델 사용 권장)
                          isAiMessage,
                          isInitialMessage: isInitialForAvatar,
                        );
                      },
                    ),
                  ),
                  if (chatMessages.length == 1 &&
                      chatMessages.first.role == MessageRole.assistance &&
                      chatMessages.first.state == MessageState.asking &&
                      !_isCreatingSession)
                    _buildInitialView(
                      mode: InitialViewMode.optionsOnly,
                    ), // 옵션만 표시하도록 플래그 전달
                  _buildInputArea(),
                ],
              ),
    );
  }

  Widget _buildInitialView({InitialViewMode mode = InitialViewMode.full}) {
    // 기본값은 전체 UI
    // 옵션 버튼들 생성 로직 (공통)
    Widget optionButtons = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildOptionButton(
          context,
          '오늘 아침으로 샐러드 먹었어',
          onTap: () => _onOptionTapped('오늘 아침으로 샐러드 먹었어'),
        ),
        const SizedBox(height: 12),
        _buildOptionButton(
          context,
          '간단하게 시리얼 먹었어',
          onTap: () => _onOptionTapped('간단하게 시리얼 먹었어'),
        ),
        const SizedBox(height: 12),
        _buildOptionButton(
          context,
          '시간이 없어서 아침을 안먹었어',
          onTap: () => _onOptionTapped('시간이 없어서 아침을 안먹었어'),
        ),
      ],
    );

    // 초기 AI 메시지 생성 로직 (공통)
    Widget aiInitialMessage = _buildChatMessageBubble(
      '안녕! 오늘 아침 뭐 먹었어? 😊',
      DateTime.now(),
      true,
      isInitialMessage: true,
    );

    // 파라미터 'mode'에 따라 다른 UI 반환
    switch (mode) {
      case InitialViewMode.aiMessageOnly:
        return aiInitialMessage; // 초기 AI 메시지만 반환
      case InitialViewMode.optionsOnly:
        // 옵션 버튼들만 반환 (입력창 위에 위치할 때 사용)
        return Container(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
          color: Colors.white,
          child: optionButtons,
        );
      case InitialViewMode.full: // 기본값
      default:
        // 전체 초기 UI (AI 메시지 + 옵션 버튼들) 반환
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              aiInitialMessage,
              const SizedBox(height: 24),
              optionButtons,
            ],
          ),
        );
    }
  }

  Widget _buildChatMessageBubble(
    String message,
    DateTime timestamp,
    bool isAiMessage, {
    bool isInitialMessage = false,
  }) {
    final align = isAiMessage ? Alignment.centerLeft : Alignment.centerRight;
    final bubbleColor =
        isAiMessage ? Colors.grey[200] : const Color(0xFF4A86F7);
    final textColor = isAiMessage ? Colors.black87 : Colors.white;
    final radius =
        isAiMessage
            ? const BorderRadius.only(
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            )
            : const BorderRadius.only(
              topLeft: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            );

    return Align(
      alignment: align,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAiMessage && isInitialMessage) ...[
            // 메시지 옆 작은 AI 아바타 (SVG)
            ClipOval(child: smallAiAvatar), // SVG가 사각형일 경우 원형으로 자름
            // smallAiAvatar, // SVG가 이미 원형 디자인이라면 ClipOval 없이 사용
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: radius,
              ),
              child: Column(
                crossAxisAlignment:
                    isAiMessage
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message,
                    style: TextStyle(fontSize: 15, color: textColor),
                  ),
                  if (isAiMessage)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        "${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}",
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(
    BuildContext context,
    String text, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F0E9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.circle_outlined, size: 18, color: Colors.brown[300]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -1),
            blurRadius: 4,
            color: Colors.grey.withOpacity(0.15),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.add_circle_outline,
                color: Colors.grey[500],
                size: 28,
              ),
              onPressed: () {},
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: '자유롭게 답변하기',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (text) => _onPressedSendButton(),
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.mic_none_outlined,
                color: Colors.grey[500],
                size: 28,
              ),
              onPressed: () {},
            ),
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
