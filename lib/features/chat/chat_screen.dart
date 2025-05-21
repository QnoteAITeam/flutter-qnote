// lib/features/chat/chat_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_qnote/api/api_service.dart';
import 'package:flutter_qnote/api/dto/send_message_dto.dart';
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

  String? _proposedDiarySummary;
  String? _proposedDiaryTitle;
  List<String> _proposedDiaryTags = [];
  List<String> _currentChatOptions = [];

  // AI 아바타 위젯 정의 (메시지 버블용)
  final Widget smallAiAvatar = CircleAvatar(
    radius: 12,
    backgroundColor: Colors.grey[300],
    backgroundImage: const AssetImage('assets/images/ai_avatar.png'), // 실제 에셋 경로 확인
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
        chatMessages.add(
          SendMessageDto(
            role: MessageRole.assistance,
            state: MessageState.asking,
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
        _proposedDiarySummary = null;
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
      final SendMessageDto aiResponseFromServer = await ApiService.getInstance.sendMessageToAI(text);
      if (mounted) {
        _checkForDiarySuggestion(aiResponseFromServer);

        setState(() {
          chatMessages.add(aiResponseFromServer);

          if (aiResponseFromServer.state == MessageState.asking) {
            _currentChatOptions = [
              '네, 다음 질문해주세요.',
              '아니요, 더 할 말 없어요.',
              '음... 잠시만요.',
            ];
          } else {
            _currentChatOptions = [];
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
          _proposedDiarySummary = null;
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

  void _onPressedSendButton() {
    final data = _textController.text;
    if (data.trim().isEmpty) return;
    _sendMessage(data, isFromOption: false);
  }

  void _onOptionTapped(String optionText) {
    _sendMessage(optionText, isFromOption: true);
  }

  void _checkForDiarySuggestion(SendMessageDto aiMessage) {
    if (aiMessage.role == MessageRole.assistance) {
      if (aiMessage.state == MessageState.done) {
        final String messageContent = aiMessage.message;
        if (messageContent.isNotEmpty) {
          _proposedDiarySummary = messageContent;
          _proposedDiaryTitle = '오늘의 일기 (${DateFormat('MM.dd').format(DateTime.now())})';
          RegExp exp = RegExp(r"#([\wㄱ-ㅎㅏ-ㅣ가-힣]+)");
          Iterable<Match> matches = exp.allMatches(messageContent);
          _proposedDiaryTags = matches.map((m) => m.group(1)!).toList();
        } else {
          _proposedDiarySummary = null;
          _proposedDiaryTags = [];
        }
      } else {
        _proposedDiarySummary = null;
        _proposedDiaryTags = [];
      }
    } else {
      _proposedDiarySummary = null;
      _proposedDiaryTags = [];
    }
  }

  void _navigateToDiaryDetailScreen() async {
    if (_proposedDiarySummary == null || !mounted) return;
    final result = await Navigator.push<Diary>(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryDetailScreen(
          initialTitle: _proposedDiaryTitle,
          initialContent: _proposedDiarySummary!,
          initialSummaryFromAI: _proposedDiarySummary,
          initialTags: _proposedDiaryTags,
        ),
      ),
    );
    if (result != null && mounted) {
      // DashboardScreen의 IndexedStack 구조에서는 이 pop이 원하는 대로 동작하지 않을 수 있음.
      // 일기 저장 후 홈 탭으로 이동하고, DashboardScreen에서 데이터를 새로고침하는 로직이 필요.
      // 예: context.findAncestorStateOfType<_DashboardScreenState>()?.navigateToHomeAndRefresh();
      // 지금은 이 pop이 호출되면 ChatScreen이 스택에서 사라지고 DashboardScreen의 이전 상태가 보일 것임.
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( // ChatScreen은 자체 Scaffold와 AppBar를 가짐
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false, // 뒤로가기 버튼 자동 생성 방지
        titleSpacing: 0, // 타이틀과 leading/actions 사이의 기본 간격 제거
        title: Padding(
          padding: const EdgeInsets.only(left: 12.0), // 타이틀 영역 왼쪽 패딩
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: const AssetImage('assets/images/ai_avatar.png'), // 실제 "큐노트 AI" 아바타 경로
                onBackgroundImageError: (e, s) => print('Error loading ai_avatar: $e'),
                child: !const AssetImage('assets/images/ai_avatar.png').assetName.contains('placeholder')
                    ? null
                    : Icon(Icons.support_agent, size: 20, color: Colors.blue.shade700), // 플레이스홀더 아이콘
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
          const SizedBox(width: 8), // 오른쪽 끝 여백
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
              itemCount: chatMessages.length +
                  (_isAiResponding ? 1 : 0) +
                  (_proposedDiarySummary != null && !_isAiResponding ? 1 : 0),
              itemBuilder: (context, index) {
                int messageBoundary = chatMessages.length;
                int loadingBoundary = messageBoundary + (_isAiResponding ? 1 : 0);

                if (_isAiResponding && index == messageBoundary) {
                  return _buildShimmerLoadingBubble();
                }
                if (_proposedDiarySummary != null && !_isAiResponding && index == loadingBoundary) {
                  return _buildSaveDiaryWidget();
                }
                if (index < chatMessages.length) {
                  final msg = chatMessages[index];
                  return _buildChatMessageBubble(msg);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          _buildChatOptionsArea(),
          _buildInputArea(),
        ],
      ),
    );
  }

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
        padding: const EdgeInsets.only(left: 40.0, top: 10.0, bottom: 10.0, right: 16.0),
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
      constraints: const BoxConstraints(maxHeight: 50),
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
        foregroundColor: const Color(0xFF4A4A4A),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ).copyWith(
        overlayColor: MaterialStateProperty.resolveWith<Color?>(
              (Set<MaterialState> states) {
            if (states.contains(MaterialState.pressed)) {
              return Colors.brown.withOpacity(0.1);
            }
            return null;
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
            offset: const Offset(0, -1),
            blurRadius: 4,
            color: Colors.grey.withAlpha((0.05 * 255).round()),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
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
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(25.0),
                ),
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: '자유롭게 답변하기',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
                  ),
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.send,
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
