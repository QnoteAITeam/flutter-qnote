import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_qnote/api/api_service.dart';
import 'package:flutter_qnote/api/dto/send_message_dto.dart';
import 'package:flutter_qnote/features/diary/diary_detail_screen.dart';
import 'package:flutter_qnote/models/diary.dart';
import 'package:intl/intl.dart';
import 'package:flutter_qnote/models/chat_session.dart';

import 'widgets/chat_app_bar.dart';
import 'widgets/chat_message_bubble.dart';
import 'widgets/shimmer_loading_bubble.dart';
import 'widgets/save_diary_widget.dart';
import 'widgets/chat_options_area.dart';
import 'widgets/chat_input_area.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isCreatingSession = true;
  bool _isAiResponding = false;
  final List<SendMessageDto> _chatMessages = [];

  String? _diarySummaryForButton;
  String? _diaryTitleForButton;
  List<String> _diaryTagsForButton = [];
  bool _showAskingZeroDiaryButton = false;

  ChatSession? _currentSession;
  List<String> _currentChatOptions = [];

  static const Widget smallAiAvatar = CircleAvatar(
    radius: 12,
    backgroundColor: Colors.transparent,
    backgroundImage: AssetImage('assets/images/ai_avatar.png'),
  );

  @override
  void initState() {
    super.initState();
    _initializeChatSession();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void setStateIfMounted(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  Future<void> _initializeChatSession() async {
    if (!mounted) return;
    setStateIfMounted(() => _isCreatingSession = true);

    try {
      final ChatSession newSession = await ApiService.getInstance.createNewSession();
      if (mounted) {
        _currentSession = newSession;
        if (_chatMessages.isEmpty) {
          _chatMessages.add(
            SendMessageDto(
              role: MessageRole.assistance,
              state: MessageState.asking,
              message: '안녕하세요! 오늘 하루는 어떠셨나요? 😊',
              askingNumericValue: 1,
            ),
          );
          setStateIfMounted(() {
            _currentChatOptions = [
              '오늘 아침으로 샐러드 먹었어', '간단하게 시리얼 먹었어',
              '시간이 없어서 아침을 안먹었어', '글쎄, 딱히 기억이 안나네',
            ];
          });
        }
      }
    } catch (_) {
      if (mounted) {
        _chatMessages.add(SendMessageDto(
          role: MessageRole.system,
          state: MessageState.done,
          message: "채팅 세션을 시작하는 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.",
        ));
      }
    } finally {
      if (mounted) {
        setStateIfMounted(() => _isCreatingSession = false);
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Timer(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _sendMessage(String text, {bool isFromOption = false}) async {
    final String trimmedText = text.trim();
    if (trimmedText.isEmpty) return;
    if (_currentSession == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('채팅 세션이 활성화되지 않았습니다.')));
      return;
    }

    final userMessage = SendMessageDto.fromMessageByUser(trimmedText);
    setStateIfMounted(() {
      _chatMessages.add(userMessage);
      _isAiResponding = true;
      _showAskingZeroDiaryButton = false;
      _diarySummaryForButton = null;
      _diaryTagsForButton = [];
      if (isFromOption) _currentChatOptions = [];
    });
    _scrollToBottom();

    if (!isFromOption) _textController.clear();

    try {
      final SendMessageDto aiResponse = await ApiService.getInstance.sendMessageToAI(trimmedText);
      if (mounted) {
        _processAiResponse(aiResponse);
        setStateIfMounted(() {
          _chatMessages.add(aiResponse);
          if (!_showAskingZeroDiaryButton &&
              aiResponse.askingNumericValue != null &&
              aiResponse.askingNumericValue != 0) {
            _currentChatOptions = ['네, 다음 질문해주세요.', '아니요, 더 할 말 없어요.', '음... 잠시만요.'];
          } else {
            _currentChatOptions = [];
          }
        });
      }
    } catch (_) {
      if (mounted) {
        _chatMessages.add(SendMessageDto(
          role: MessageRole.assistance,
          state: MessageState.done,
          message: "죄송합니다, AI와 대화 중 문제가 발생했습니다.",
        ));
        setStateIfMounted(() {
          _isAiResponding = false;
          _showAskingZeroDiaryButton = false;
          _diarySummaryForButton = null;
          _currentChatOptions = [];
        });
      }
    } finally {
      if (mounted) {
        setStateIfMounted(() => _isAiResponding = false);
        _scrollToBottom();
      }
    }
  }

  // AI 응답에서 태그/감정태그를 모두 List<String>으로 합쳐서 저장
  void _processAiResponse(SendMessageDto aiMessage) {
    if (aiMessage.role != MessageRole.assistance) {
      setStateIfMounted(() {
        _showAskingZeroDiaryButton = false;
        _diarySummaryForButton = null;
        _diaryTagsForButton = [];
      });
      return;
    }

    if (aiMessage.askingNumericValue == 0 && aiMessage.state == MessageState.done) {

      print('[DEBUG] suggestedTags: ${aiMessage.suggestedTags}');
      print('[DEBUG] suggestedEmotionTags: ${aiMessage.suggestedEmotionTags}');

      String finalSummary = aiMessage.message;
      String? finalTitle = aiMessage.suggestedTitle;

      List<String> allSuggestedTags = [
        ...aiMessage.suggestedTags,
        ...aiMessage.suggestedEmotionTags
      ];
      List<String> finalUniqueTags = allSuggestedTags
          .where((tag) => tag.isNotEmpty)
          .toSet()
          .toList();

      print('[DEBUG] 최종 태그: $finalUniqueTags');

      setStateIfMounted(() {
        _diarySummaryForButton = finalSummary;
        _diaryTitleForButton = finalTitle ?? '오늘의 일기 (${DateFormat('MM.dd').format(DateTime.now())})';
        _diaryTagsForButton = finalUniqueTags;
        _showAskingZeroDiaryButton = true;
      });
    } else {
      setStateIfMounted(() {
        _showAskingZeroDiaryButton = false;
        _diarySummaryForButton = null;
        _diaryTagsForButton = [];
      });
    }
  }

  void _onPressedSendButton() {
    if (_textController.text.trim().isEmpty) return;
    _sendMessage(_textController.text);
  }

  void _onOptionTapped(String optionText) {
    _sendMessage(optionText, isFromOption: true);
  }

  // DiaryDetailScreen 호출 시 initialTags에 _diaryTagsForButton 전달
  void _navigateToDiaryDetailScreen() async {
    if (!_showAskingZeroDiaryButton || _diarySummaryForButton == null || !mounted) return;
    FocusScope.of(context).unfocus();

    final Diary? savedDiary = await Navigator.push<Diary>(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryDetailScreen(
          initialTitle: _diaryTitleForButton,
          initialContent: _diarySummaryForButton!,
          initialSummaryFromAI: _diarySummaryForButton,
          initialTags: _diaryTagsForButton,
          initialDate: DateTime.now(),
        ),
      ),
    );

    if (!mounted) return;
    FocusScope.of(context).unfocus();

    if (savedDiary != null) {
      setStateIfMounted(() {
        _showAskingZeroDiaryButton = false;
        _diarySummaryForButton = null;
        _diaryTagsForButton = [];
        _currentChatOptions = [];
        _chatMessages.add(SendMessageDto(
          role: MessageRole.assistance,
          state: MessageState.done,
          message: "AI가 요약하여 일기를 저장했어요! 이용해줘서 고마워요! 🎉",
        ));
      });
      _scrollToBottom();
    } else {
      setStateIfMounted(() => _showAskingZeroDiaryButton = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: ChatAppBar(onInfoPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI 챗봇 정보 버튼 (기능 준비 중)')));
        }),
        body: _isCreatingSession
            ? const Center(child: CircularProgressIndicator(key: ValueKey("chat_session_loading")))
            : Column(
          children: [
            Expanded(child: _buildChatList()),
            ChatOptionsArea(
              options: _currentChatOptions,
              isAiResponding: _isAiResponding,
              onOptionTapped: _onOptionTapped,
            ),
            ChatInputArea(
              textController: _textController,
              onSendPressed: _onPressedSendButton,
              onAttachPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('첨부 기능은 준비 중입니다.')));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      itemCount: _chatMessages.length + (_isAiResponding ? 1 : 0) + (_showAskingZeroDiaryButton && !_isAiResponding ? 1 : 0),
      itemBuilder: (context, index) {
        int messageBoundary = _chatMessages.length;
        int potentialButtonIndex = messageBoundary + (_isAiResponding ? 1 : 0);

        if (_isAiResponding && index == messageBoundary) {
          return const ShimmerLoadingBubble(smallAiAvatar: smallAiAvatar);
        }
        if (_showAskingZeroDiaryButton && !_isAiResponding && index == potentialButtonIndex) {
          return SaveDiaryWidget(onPressed: _navigateToDiaryDetailScreen);
        }
        if (index < _chatMessages.length) {
          return ChatMessageBubble(messageDto: _chatMessages[index], smallAiAvatar: smallAiAvatar);
        }
        return const SizedBox.shrink();
      },
    );
  }
}
