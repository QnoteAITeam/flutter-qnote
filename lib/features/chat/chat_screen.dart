import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_qnote/api/api_service.dart';
import 'package:flutter_qnote/api/diary_api.dart';
import 'package:flutter_qnote/api/dto/send_message_dto.dart';
import 'package:flutter_qnote/features/diary/diary_detail_screen.dart';
import 'package:flutter_qnote/models/diary.dart';
import 'package:intl/intl.dart';
import 'package:flutter_qnote/models/chat_session.dart';

import 'widgets/chat_app_bar.dart';
import 'widgets/chat_message_bubble.dart';
import 'widgets/shimmer_loading_bubble.dart';
import 'widgets/save_diary_widget.dart';
import 'widgets/chat_input_area.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _chatFocusNode = FocusNode();

  bool _isCreatingSession = true;
  bool _isAiResponding = false;
  bool _isOptionLoading = false; // 옵션 리스트 로딩 상태 추가
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
    });
    _fetchPredictedAnswers();
  }

  @override
  void dispose() {
    _chatFocusNode.dispose();
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
      final ChatSession newSession =
      await ApiService.getInstance.createNewSession();
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
        }
      }
    } catch (_) {
      if (mounted) {
        _chatMessages.add(
          SendMessageDto(
            role: MessageRole.system,
            state: MessageState.done,
            message: "채팅 세션을 시작하는 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.",
          ),
        );
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
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('채팅 세션이 활성화되지 않았습니다.')));
      return;
    }

    final userMessage = SendMessageDto.fromMessageByUser(trimmedText);
    setStateIfMounted(() {
      _chatMessages.add(userMessage);
      _isAiResponding = true;
      _showAskingZeroDiaryButton = false;
      _diarySummaryForButton = null;
      _diaryTagsForButton = [];
      _currentChatOptions = [];
    });
    _scrollToBottom();
    if (!isFromOption) _textController.clear();

    try {
      final SendMessageDto aiResponse = await ApiService.getInstance
          .sendMessageToAI(trimmedText);
      if (mounted) {
        _processAiResponse(aiResponse);
        setStateIfMounted(() {
          _chatMessages.add(aiResponse);
        });
        await _fetchPredictedAnswers(); // 옵션 리스트 새로고침
      }
    } catch (_) {
      if (mounted) {
        _chatMessages.add(
          SendMessageDto(
            role: MessageRole.assistance,
            state: MessageState.done,
            message: "죄송합니다, AI와 대화 중 문제가 발생했습니다.",
          ),
        );
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

  // 옵션 리스트를 API에서 받아와서 상태에 저장 (고정 키워드 추가)
  Future<void> _fetchPredictedAnswers() async {
    setStateIfMounted(() {
      _isOptionLoading = true;
    });
    try {
      final apiList = await DiaryApi.instance.getUserPredictedAnswerMostSession();
      if (_chatMessages.length == 1 && _chatMessages.first.role == MessageRole.assistance) {
        // 첫 인삿말만 있을 때는 옵션 리스트를 비움
        _currentChatOptions = [];
      } else {
        _currentChatOptions = [
          ...apiList,
          '이제 일기를 작성해줘',
        ];
      }
    } catch (_) {
      setStateIfMounted(() {
        _currentChatOptions = ['이제 일기를 작성해줘'];
      });
    } finally {
      setStateIfMounted(() {
        _isOptionLoading = false;
      });
    }
  }

  void _processAiResponse(SendMessageDto aiMessage) {
    if (aiMessage.role != MessageRole.assistance) {
      setStateIfMounted(() {
        _showAskingZeroDiaryButton = false;
        _diarySummaryForButton = null;
        _diaryTagsForButton = [];
      });
      return;
    }

    if (aiMessage.askingNumericValue == 0 &&
        aiMessage.state == MessageState.done) {
      String finalSummary = aiMessage.message;
      String? finalTitle = aiMessage.suggestedTitle;

      List<String> allSuggestedTags = [
        ...aiMessage.suggestedTags,
        ...aiMessage.suggestedEmotionTags,
      ];
      List<String> finalUniqueTags =
      allSuggestedTags.where((tag) => tag.isNotEmpty).toSet().toList();

      setStateIfMounted(() {
        _diarySummaryForButton = finalSummary;
        _diaryTitleForButton =
            finalTitle ?? '오늘의 일기 (${DateFormat('MM.dd').format(DateTime.now().add(const Duration(hours: 9)))})';
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

  void _navigateToDiaryDetailScreen() async {
    if (!_showAskingZeroDiaryButton ||
        _diarySummaryForButton == null ||
        !mounted)
      return;
    FocusScope.of(context).unfocus();

    final diaryMetaData = await ApiService.getInstance.getDiaryInfoByContent(
      _chatMessages.last.message,
    );

    final Diary? savedDiary = await Navigator.push<Diary>(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryDetailScreen(
          initialTitle: diaryMetaData.title,
          initialContent: diaryMetaData.content,
          initialTags: diaryMetaData.tags,
          initialDate: DateTime.now().add(const Duration(hours: 9)),
        ),
      ),
    );

    if (!mounted) return;
    _chatFocusNode.unfocus();
    FocusScope.of(context).unfocus();
    if (savedDiary != null) {
      setStateIfMounted(() {
        _showAskingZeroDiaryButton = false;
        _diarySummaryForButton = null;
        _diaryTagsForButton = [];
        _currentChatOptions = [];
        _chatMessages.add(
          SendMessageDto(
            role: MessageRole.assistance,
            state: MessageState.done,
            message: "AI가 요약하여 일기를 저장했어요! 이용해줘서 고마워요! 🎉",
          ),
        );
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
        appBar: ChatAppBar(
          onInfoPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('AI 챗봇 정보 버튼 (기능 준비 중)')),
            );
          },
        ),
        body: _isCreatingSession
            ? const Center(
          child: CircularProgressIndicator(
            key: ValueKey("chat_session_loading"),
          ),
        )
            : Column(
          children: [
            Expanded(child: _buildChatList()),
            // 옵션 리스트 영역 (입력창 위)
            if (_currentChatOptions.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _currentChatOptions.map((option) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: OutlinedButton(
                          onPressed: () => _onOptionTapped(option),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.grey[100],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            side: BorderSide.none,
                          ),
                          child: Text(
                            option,
                            style: const TextStyle(
                              color: Colors.brown,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ChatInputArea(
              textController: _textController,
              focusNode: _chatFocusNode,
              onSendPressed: _onPressedSendButton,
              onAttachPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('첨부 기능은 준비 중입니다.')),
                );
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
      itemCount: _chatMessages.length +
          (_isAiResponding ? 1 : 0) +
          (_showAskingZeroDiaryButton && !_isAiResponding ? 1 : 0),
      itemBuilder: (context, index) {
        int messageBoundary = _chatMessages.length;
        int potentialButtonIndex = messageBoundary + (_isAiResponding ? 1 : 0);

        if (_isAiResponding && !_isOptionLoading && index == messageBoundary) {
          // AI 답변 생성 중일 때만 shimmer 보여줌
          return const ShimmerLoadingBubble(smallAiAvatar: smallAiAvatar);
        }
        if (_showAskingZeroDiaryButton &&
            !_isAiResponding &&
            index == potentialButtonIndex) {
          return SaveDiaryWidget(onPressed: _navigateToDiaryDetailScreen);
        }
        if (index < _chatMessages.length) {
          return ChatMessageBubble(
            messageDto: _chatMessages[index],
            smallAiAvatar: smallAiAvatar,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
