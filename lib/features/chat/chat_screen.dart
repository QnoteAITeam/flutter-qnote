// lib/features/chat/chat_screen.dart
import 'dart:async';
import 'dart:convert'; // SendMessageDto 내부에서 JSON 파싱에 사용될 수 있음
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

  String? _diarySummaryForButton;
  String? _diaryTitleForButton;
  List<String> _diaryTagsForButton = [];
  bool _showAskingZeroDiaryButton = false;

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
    setStateIfMounted(() => _isCreatingSession = true);
    try {
      await ApiService.getInstance.createNewSession();
      if (mounted && chatMessages.isEmpty) {
        chatMessages.add(
          SendMessageDto(
            role: MessageRole.assistance,
            state: MessageState.asking,
            message: '안녕하세요! 오늘 하루는 어떠셨나요? 😊',
            askingNumericValue: 1, // 초기 질문이므로 asking 1 (또는 서버 스펙에 맞게)
          ),
        );
        setStateIfMounted(() {
          _currentChatOptions = [
            '오늘 아침으로 샐러드 먹었어',
            '간단하게 시리얼 먹었어',
            '시간이 없어서 아침을 안먹었어',
            '글쎄, 딱히 기억이 안나네',
          ];
        });
      }
    } catch (e) {
      print("ChatScreen: Error initializing chat session: $e");
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
        setStateIfMounted(() => _isCreatingSession = false);
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
    final userMessage = SendMessageDto.fromMessageByUser(text);
    if (mounted) {
      setStateIfMounted(() {
        chatMessages.add(userMessage);
        _isAiResponding = true;
        _showAskingZeroDiaryButton = false;
        _diarySummaryForButton = null;
        _diaryTagsForButton = [];
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
        _processAiResponseAndUpdateButtonState(aiResponseFromServer);
        setStateIfMounted(() {
          chatMessages.add(aiResponseFromServer);
          if (!_showAskingZeroDiaryButton &&
              aiResponseFromServer.askingNumericValue != null &&
              aiResponseFromServer.askingNumericValue != 0) {
            // 서버에서 choices 필드를 받아와서 동적으로 옵션 구성하는 것이 이상적
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
      print("ChatScreen: Error sending message to AI: $e");
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
        setStateIfMounted(() {
          _showAskingZeroDiaryButton = false;
          _diarySummaryForButton = null;
          _currentChatOptions = [];
        });
        _scrollToBottom();
      }
    } finally {
      if (mounted) {
        setStateIfMounted(() {
          _isAiResponding = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _processAiResponseAndUpdateButtonState(SendMessageDto aiMessageFromServer) {
    // --- 로그 추가 위치 1 ---
    print("ChatScreen: Processing AI response. askingNumericValue: ${aiMessageFromServer.askingNumericValue}, message: <<<${aiMessageFromServer.message}>>>");

    if (aiMessageFromServer.role != MessageRole.assistance) {
      setStateIfMounted(() {
        _showAskingZeroDiaryButton = false;
        _diarySummaryForButton = null;
        _diaryTagsForButton = [];
      });
      return;
    }

    if (aiMessageFromServer.askingNumericValue == 0) {
      String messageContent = aiMessageFromServer.message;
      List<String> extractedTags = []; // 추출된 태그를 저장할 리스트
      try {
        // 1. 기존 #태그 추출 시도
        RegExp exp = RegExp(r"#([\wㄱ-ㅎㅏ-ㅣ가-힣]+)");
        Iterable<Match> matches = exp.allMatches(messageContent);
        extractedTags = matches.map((m) {
          String? tagWithHash = m.group(0);
          if (tagWithHash != null && tagWithHash.startsWith("#")) {
            return tagWithHash.substring(1);
          }
          return null;
        }).where((tag) => tag != null && tag.isNotEmpty).cast<String>().toList();

        // 2. 만약 #태그가 없다면, 내용 기반으로 간단한 자동 태그 생성 시도
        if (extractedTags.isEmpty && messageContent.isNotEmpty) {
          print("ChatScreen: No #tags found in AI message, trying to auto-generate tags from content.");
          // 매우 간단한 예시: 특정 키워드 포함 여부로 태그 생성
          List<String> keywordCandidates = [];
          // 자주 사용될 만한 긍정/부정/일상 관련 키워드 추가 (더 많은 키워드 및 정교한 로직 필요)
          if (messageContent.contains("행복") || messageContent.contains("즐거") || messageContent.contains("기뻤")) keywordCandidates.add("행복");
          if (messageContent.contains("감사") || messageContent.contains("고마")) keywordCandidates.add("감사");
          if (messageContent.contains("슬픔") || messageContent.contains("우울") || messageContent.contains("힘들")) keywordCandidates.add("슬픔");
          if (messageContent.contains("화남") || messageContent.contains("짜증")) keywordCandidates.add("화남");
          if (messageContent.contains("일상") || messageContent.contains("평범") || messageContent.contains("보통")) keywordCandidates.add("일상");
          if (messageContent.contains("샐러드")) keywordCandidates.add("샐러드");
          if (messageContent.contains("아침")) keywordCandidates.add("아침식사");
          if (messageContent.contains("운동")) keywordCandidates.add("운동");
          if (messageContent.contains("공부")) keywordCandidates.add("공부");
          if (messageContent.contains("친구")) keywordCandidates.add("친구");
          if (messageContent.contains("가족")) keywordCandidates.add("가족");

          // 중복을 제거하고 최대 3개의 키워드 태그만 사용
          extractedTags.addAll(keywordCandidates.toSet().take(3));

          // 그래도 태그가 없다면, 메시지에서 길이가 2 이상인 단어 중 처음 2개 (매우 단순)
          if (extractedTags.isEmpty) {
            List<String> words = messageContent
                .replaceAll(RegExp(r'[^\w\sㄱ-ㅎㅏ-ㅣ가-힣]'), '') // 간단한 특수문자 제거
                .split(RegExp(r'\s+'))
                .where((word) => word.length > 1 && !_isCommonWord(word)) // 흔한 단어 제외
                .toList();
            if (words.isNotEmpty) {
              extractedTags = words.take(2).toList();
            }
          }
          print("ChatScreen: Auto-generated tags: $extractedTags");
        }

      } catch (e) {
        print("ChatScreen: Error extracting/generating tags: $e");
      }

      setStateIfMounted(() {
        _diarySummaryForButton = messageContent;
        _diaryTitleForButton = '오늘의 일기 (${DateFormat('MM.dd').format(DateTime.now())})';
        _diaryTagsForButton = extractedTags.toSet().toList(); // 최종적으로 중복 제거
        _showAskingZeroDiaryButton = true;
        // --- 로그 추가 위치 2 ---
        print("ChatScreen: 일기 작성/수정하기 버튼 표시 (askingNumericValue == 0). Final Tags: $_diaryTagsForButton");
      });
    } else {
      setStateIfMounted(() {
        _showAskingZeroDiaryButton = false;
        _diarySummaryForButton = null;
        _diaryTagsForButton = [];
        // --- 로그 추가 위치 3 ---
        print("ChatScreen: 일기 작성/수정하기 버튼 숨김 (askingNumericValue = ${aiMessageFromServer.askingNumericValue})");
      });
    }
  }

  // 흔한 단어 제외를 위한 간단한 헬퍼 함수 (필요시 확장)
  bool _isCommonWord(String word) {
    const commonWords = ['오늘', '어제', '내일', '나는', '나의', '내가', '너는', '너의', '그는', '그녀는', '우리', '그리고', '그래서', '하지만', '그러나', '이제', '정말', '매우', '아주', '너무', '조금', '많이', '항상', '가끔', '때때로', '여기', '저기', '이것', '저것', '그것', '있다', '없다', '했다', '이다', '입니다'];
    return commonWords.contains(word.toLowerCase());
  }

  void setStateIfMounted(VoidCallback fn) {
    if (mounted) {
      setState(fn);
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

  void _navigateToDiaryDetailScreen() async {
    if (!_showAskingZeroDiaryButton || _diarySummaryForButton == null || !mounted) return;

    // --- 로그 추가 위치 4 ---
    print("ChatScreen: Navigating to DiaryDetailScreen with tags: $_diaryTagsForButton, title: $_diaryTitleForButton, summary: $_diarySummaryForButton");

    final result = await Navigator.push<Diary>(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryDetailScreen(
          initialTitle: _diaryTitleForButton,
          initialContent: _diarySummaryForButton!,
          initialSummaryFromAI: _diarySummaryForButton,
          initialTags: _diaryTagsForButton,
          initialDate: DateTime.now(), // 현재 날짜 전달
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
                onBackgroundImageError: (e, s) => print('ChatScreen: Error loading ai_avatar: $e'),
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
              itemCount: chatMessages.length +
                  (_isAiResponding ? 1 : 0) +
                  (_showAskingZeroDiaryButton && !_isAiResponding ? 1 : 0),
              itemBuilder: (context, index) {
                int messageBoundary = chatMessages.length;
                int buttonIndexCandidate = messageBoundary + (_isAiResponding ? 1 : 0);

                if (_isAiResponding && index == messageBoundary) {
                  return _buildShimmerLoadingBubble();
                }
                if (_showAskingZeroDiaryButton && !_isAiResponding && index == buttonIndexCandidate) {
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
