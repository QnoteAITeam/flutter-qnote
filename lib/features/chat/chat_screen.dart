// lib/features/chat/chat_screen.dart
import 'dart:async';
import 'dart:convert'; // JSON 파싱을 위해 필요
import 'package:flutter/material.dart';
import 'package:flutter_qnote/api/api_service.dart';
import 'package:flutter_qnote/api/dto/send_message_dto.dart'; // SendMessageDto 경로 확인
import 'package:flutter_qnote/features/diary/diary_detail_screen.dart';
import 'package:flutter_qnote/models/diary.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isCreatingSession = true;
  bool _isAiResponding = false;
  final List<SendMessageDto> chatMessages = [];

  // "일기 작성/수정하기" 버튼 관련 상태 변수
  String? _diarySummaryForButton; // 버튼이 표시될 때 사용할 요약 (asking:0 일 때의 AI 메시지)
  String? _diaryTitleForButton;
  List<String> _diaryTagsForButton = [];
  bool _showAskingZeroDiaryButton = false; // asking:0 일 때 버튼을 표시할지 결정하는 플래그

  List<String> _currentChatOptions = [];

  final Widget smallAiAvatar = CircleAvatar(
    radius: 12,
    backgroundColor: Colors.grey[300],
    backgroundImage: const AssetImage('assets/images/ai_avatar.png'),
  );

  @override
  void initState() {
    super.initState();
    _initializeChatSession();
  }

  Future<void> _initializeChatSession() async {
    if (!mounted) return;
    setState(() => _isCreatingSession = true);
    try {
      await ApiService.getInstance.createNewSession();
      if (mounted && chatMessages.isEmpty) {
        // SendMessageDto.fromJsonByAssistant를 사용하지 않으므로, 초기 메시지는 state와 message만 명확히.
        chatMessages.add(
          SendMessageDto(
            role: MessageRole.assistance,
            state: MessageState.asking, // 초기 질문은 asking 상태
            message: '안녕하세요! 오늘 하루는 어떠셨나요? 😊',
          ),
        );
        setState(() {
          _currentChatOptions = [
            '오늘 아침으로 샐러드 먹었어',
            '간단하게 시리얼 먹었어',
            '시간이 없어서 아침을 안먹었어',
            '글쎄, 딱히 기억이 안나네',
          ];
        });
      }
    } catch (e) {
      print("Error initializing chat session: $e");
      if (mounted) {
        String errorMessage = "채팅 세션을 시작하는 중 오류가 발생했습니다.";
        if (e.toString().toLowerCase().contains('unauthorized') || e.toString().contains('401')) {
          errorMessage = "세션 시작에 실패했습니다. 다시 로그인 후 시도해주세요.";
        }
        chatMessages.add(
          SendMessageDto(
            role: MessageRole.system,
            state: MessageState.done,
            message: errorMessage,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreatingSession = false);
        _scrollToBottom();
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Timer(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _sendMessage(String text, {bool isFromOption = false}) async {
    final userMessage = SendMessageDto.fromMessageByUser(text);
    if (mounted) {
      setState(() {
        chatMessages.add(userMessage);
        _isAiResponding = true;
        _showAskingZeroDiaryButton = false; // 새 메시지 전송 시 이전 버튼 상태 초기화
        _diarySummaryForButton = null;    // 이전 요약 초기화
        _diaryTagsForButton = [];         // 이전 태그 초기화
        if (isFromOption) {
          _currentChatOptions = [];
        }
      });
      _scrollToBottom();
    }

    if (!isFromOption && text.trim().isNotEmpty && text == _textController.text) {
      _textController.clear();
    }
    if (!isFromOption) {
      FocusScope.of(context).unfocus();
    }

    try {
      // 서버에서 오는 응답은 SendMessageDto.fromJsonByAssistant가 파싱한다고 가정
      final SendMessageDto aiResponseFromServer = await ApiService.getInstance.sendMessageToAI(text);

      if (mounted) {
        // AI 응답 처리 로직 호출
        _processAiResponseAndUpdateState(aiResponseFromServer);

        setState(() {
          chatMessages.add(aiResponseFromServer);
          // 옵션 버튼 로직: AI가 계속 질문 중이고(state == asking), 그 asking 값이 0이 아닐 때만 일반적인 다음 질문 옵션 표시
          if (aiResponseFromServer.state == MessageState.asking && !_showAskingZeroDiaryButton) {
            _currentChatOptions = [
              '네, 다음 질문해주세요.',
              '아니요, 더 할 말 없어요.',
              '음... 잠시만요.',
            ];
          } else {
            _currentChatOptions = []; // asking:0 이거나 done 상태면 옵션 없음
          }
        });
        _scrollToBottom();
      }
    } catch (e) {
      print("Error sending message to AI: $e");
      if (mounted) {
        String errorMessage = "죄송합니다, AI와 대화 중 문제가 발생했습니다.";
        if (e.toString().toLowerCase().contains('unauthorized') || e.toString().contains('401')) {
          errorMessage = "세션이 만료되었거나 인증 오류가 발생했습니다.";
        }
        chatMessages.add(
          SendMessageDto(
            role: MessageRole.system,
            state: MessageState.done,
            message: errorMessage,
          ),
        );
        setState(() {
          _showAskingZeroDiaryButton = false;
          _diarySummaryForButton = null;
          _currentChatOptions = [];
        });
        _scrollToBottom();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAiResponding = false;
        });
        _scrollToBottom();
      }
    }
  }

  // AI 응답을 분석하여 "일기 작성/수정하기" 버튼 표시 여부 및 관련 데이터 설정
  void _processAiResponseAndUpdateState(SendMessageDto aiMessageFromServer) {
    if (aiMessageFromServer.role != MessageRole.assistance) {
      // AI 응답이 아니면 버튼 표시 안 함
      _showAskingZeroDiaryButton = false;
      _diarySummaryForButton = null;
      _diaryTagsForButton = [];
      return;
    }

    // SendMessageDto.fromJsonByAssistant에서 이미 1차 파싱된 message를 사용
    // 여기서 다시 한번 asking 값을 확인해야 함. (SendMessageDto에 askingNumericValue 필드가 없으므로)
    // 실제 AI 응답의 'message' 필드가 여전히 {"message": "...", "asking": 0} 형태의 JSON 문자열이라고 가정.
    // 그리고 SendMessageDto.fromJsonByAssistant가 그 내부 "message"만 추출했다고 가정.
    // 이 부분은 SendMessageDto.fromJsonByAssistant의 구현과 실제 서버 응답 스펙에 따라 달라짐.
    // 가장 좋은 것은 SendMessageDto에 asking 숫자값을 저장하는 필드를 두는 것.
    // 여기서는 SendMessageDto의 state가 MessageState.done으로 설정되었지만,
    // 실제로는 asking:0 에 해당하는 메시지(일기 요약)일 수 있다는 상황을 가정.
    // 또는, 서버 응답 JSON의 최상위에 asking 필드가 있고, SendMessageDto.fromJsonByAssistant가 이를 사용한다고 가정.

    // 현재 SendMessageDto.fromJsonByAssistant는 다음과 같이 구현되어 있음:
    // state: json['asking'] == 1 ? MessageState.asking : MessageState.done,
    // message: jsonDecode(json['message'])['message'],
    // 즉, 서버 응답의 최상위 'asking' 필드 값에 따라 state가 결정되고,
    // 중첩된 JSON의 'message'가 SendMessageDto의 message가 됨.
    // 따라서, asking:0 이면 SendMessageDto.state는 MessageState.done이 됨.
    // 그리고 SendMessageDto.message는 일기 요약 내용을 담게 됨.

    // 결론: "일기 작성/수정하기" 버튼은 AI 응답의 state가 MessageState.done 이고,
    // 그 메시지가 단순한 done 응답이 아니라 asking:0에 해당하는 요약일 때 표시되어야 함.
    // 이 "asking:0에 해당하는 요약"인지 여부를 판단하는 명확한 방법이 SendMessageDto에 필요.
    // 여기서는 임시로, state가 done이고, message가 비어있지 않으면 요약으로 간주. (개선 필요)

    if (aiMessageFromServer.state == MessageState.done && aiMessageFromServer.message.isNotEmpty) {
      // TODO: 이 조건이 정말로 "asking:0" (일기 요약 제안) 상황인지 서버 응답 스펙과 SendMessageDto.fromJsonByAssistant를 보고 다시 확인해야 함.
      // 만약 SendMessageDto에 `askingNumericValue` 필드가 있다면,
      // `if (aiMessageFromServer.askingNumericValue == 0)` 와 같이 명확하게 판단 가능.
      // 현재는 SendMessageDto의 state가 MessageState.done으로 설정된 경우, 이것이 asking:0에 의한 요약이라고 가정.

      String messageContent = aiMessageFromServer.message; // 이것이 요약이라고 가정
      _diarySummaryForButton = messageContent;
      _diaryTitleForButton = '오늘의 일기 (${DateFormat('MM.dd').format(DateTime.now())})';
      RegExp exp = RegExp(r"#([\wㄱ-ㅎㅏ-ㅣ가-힣]+)");
      Iterable<Match> matches = exp.allMatches(messageContent);
      _diaryTagsForButton = matches.map((m) => m.group(1)!).toList();
      _showAskingZeroDiaryButton = true;
      print("일기 작성/수정하기 버튼 표시 조건 충족 (asking:0 추정)");
    } else {
      _showAskingZeroDiaryButton = false;
      _diarySummaryForButton = null;
      _diaryTagsForButton = [];
      print("일기 작성/수정하기 버튼 표시 조건 미충족: state=${aiMessageFromServer.state}, message='${aiMessageFromServer.message}'");
    }
  }

  // _checkForDiarySuggestion 함수는 _processAiResponseAndUpdateState로 대체
  /*
  void _checkForDiarySuggestion(SendMessageDto aiMessage) {
    // ...
  }
  */

  void _onPressedSendButton() {
    final data = _textController.text;
    if (data.trim().isEmpty) return;
    _sendMessage(data, isFromOption: false);
  }

  void _onOptionTapped(String optionText) {
    _sendMessage(optionText, isFromOption: true);
  }

  void _navigateToDiaryDetailScreen() async {
    if (!_showAskingZeroDiaryButton || _diarySummaryForButton == null || !mounted) return;

    final result = await Navigator.push<Diary>(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryDetailScreen(
          initialTitle: _diaryTitleForButton,
          initialContent: _diarySummaryForButton!, // null이 아님을 보장
          initialSummaryFromAI: _diarySummaryForButton,
          initialTags: _diaryTagsForButton,
        ),
      ),
    );
    if (result != null && mounted) {
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: const AssetImage('assets/images/ai_avatar.png'),
                onBackgroundImageError: (e, s) => print('Error loading ai_avatar: $e'),
                child: !const AssetImage('assets/images/ai_avatar.png').assetName.contains('placeholder')
                    ? null
                    : Icon(Icons.support_agent, size: 20, color: Colors.blue.shade700),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('큐노트 AI', style: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.bold)),
                  Text('오늘 하루를 요약해 보세요!', style: TextStyle(color: Colors.black54, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: Colors.grey.shade600, size: 24),
            tooltip: 'AI 챗봇 정보',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('AI 챗봇 정보 버튼 (기능 준비 중)')),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isCreatingSession
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              // itemCount 계산: 메시지 수 + 로딩 인디케이터 (있다면) + 일기 작성 버튼 (있다면)
              itemCount: chatMessages.length +
                  (_isAiResponding ? 1 : 0) +
                  (_showAskingZeroDiaryButton && !_isAiResponding ? 1 : 0), // 수정된 조건
              itemBuilder: (context, index) {
                int messageBoundary = chatMessages.length;
                // 로딩 인디케이터 다음 또는 메시지 다음이 버튼 위치
                int buttonIndexCandidate = messageBoundary + (_isAiResponding ? 1 : 0);

                if (_isAiResponding && index == messageBoundary) {
                  return _buildShimmerLoadingBubble();
                }
                // "일기 작성/수정하기" 버튼 표시 조건
                if (_showAskingZeroDiaryButton && !_isAiResponding && index == buttonIndexCandidate) {
                  return _buildSaveDiaryWidget();
                }
                // 메시지 버블 표시 (인덱스 범위 확인)
                if (index < chatMessages.length) {
                  final msg = chatMessages[index];
                  return _buildChatMessageBubble(msg);
                }
                return const SizedBox.shrink(); // 예상치 못한 인덱스 처리
              },
            ),
          ),
          _buildChatOptionsArea(),
          _buildInputArea(),
        ],
      ),
    );
  }

  // --- 나머지 위젯 빌드 함수들은 이전과 동일하게 유지 ---
  Widget _buildShimmerLoadingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipOval(child: smallAiAvatar),
            const SizedBox(width: 8),
            Container(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 120, height: 10.0, color: Colors.white),
                    const SizedBox(height: 4),
                    Container(width: 80, height: 10.0, color: Colors.white),
                  ],
                ))
          ],
        ),
      ),
    );
  }

  Widget _buildChatMessageBubble(SendMessageDto messageDto) {
    final bool isUserMessage = messageDto.role == MessageRole.user;
    final bool isSystemMessage = messageDto.role == MessageRole.system;

    return Align(
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUserMessage && !isSystemMessage) ...[
            ClipOval(child: smallAiAvatar),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUserMessage
                    ? const Color(0xFFB59A7B)
                    : (isSystemMessage
                    ? Colors.redAccent.withOpacity(0.1)
                    : Colors.grey[200]),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isUserMessage ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: isUserMessage ? const Radius.circular(4) : const Radius.circular(16),
                ),
              ),
              child: Text(
                messageDto.message,
                style: TextStyle(
                    color: isUserMessage
                        ? Colors.white
                        : (isSystemMessage ? Colors.red.shade800 : Colors.black87)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveDiaryWidget() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 40.0, top: 10.0, bottom: 10.0, right: 16.0), // AI 아바타와 유사한 위치
        child: ElevatedButton.icon(
          icon: Icon(Icons.edit_note_outlined, color: Colors.brown.shade700, size: 20),
          label: Text(
            '일기 작성/수정하기',
            style: TextStyle(color: Colors.brown.shade800, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          onPressed: _navigateToDiaryDetailScreen,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEADDCA),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildChatOptionsArea() {
    if (_currentChatOptions.isEmpty || _isAiResponding) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      constraints: const BoxConstraints(maxHeight: 50), // 높이 제한으로 여러 줄 방지
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1.0)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        itemCount: _currentChatOptions.length,
        itemBuilder: (context, index) {
          final optionText = _currentChatOptions[index];
          return _buildOptionButton(optionText, () => _onOptionTapped(optionText));
        },
        separatorBuilder: (context, index) => const SizedBox(width: 8),
      ),
    );
  }

  Widget _buildOptionButton(String text, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFF5F0E9),
        foregroundColor: const Color(0xFF4A4A4A), // 텍스트 색상
        elevation: 0, // 그림자 없음
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ).copyWith(
        overlayColor: MaterialStateProperty.resolveWith<Color?>(
              (Set<MaterialState> states) {
            if (states.contains(MaterialState.pressed)) {
              return Colors.brown.withOpacity(0.1); // 클릭 시 오버레이 색상
            }
            return null; // 기본값 사용
          },
        ),
      ),
      child: Text(text),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -1), // 상단 그림자
            blurRadius: 4,
            color: Colors.grey.withAlpha((0.05 * 255).round()), // 연한 그림자
          ),
        ],
      ),
      child: SafeArea( // 하단 노치 영역 등을 고려
        top: false, // 상단 SafeArea는 AppBar가 처리
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.add_circle_outline, color: Colors.grey[600], size: 28),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('첨부 기능은 준비 중입니다.')),
                );
              },
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[200], // 입력창 배경색
                  borderRadius: BorderRadius.circular(25.0),
                ),
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: '자유롭게 답변하기',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0), // 내부 패딩
                  ),
                  minLines: 1,
                  maxLines: 5, // 여러 줄 입력 가능
                  textInputAction: TextInputAction.send, // 엔터키 액션
                  onSubmitted: (text) => _onPressedSendButton(),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send_rounded, color: const Color(0xFFB59A7B), size: 28),
              onPressed: _onPressedSendButton,
            ),
          ],
        ),
      ),
    );
  }
}
