// lib/features/diary/diary_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_qnote/api/diary_api.dart';    // DiaryApi 임포트
import 'package:flutter_qnote/models/diary.dart';      // 제공된 Diary 모델
import 'package:flutter_qnote/models/tag.dart';     // 제공된 Tag 모델
// import 'package:flutter_qnote/models/emotion_tag.dart'; // 현재 직접 사용 안함
import 'package:intl/intl.dart';                       // DateFormat 사용

class DiaryDetailScreen extends StatefulWidget {
  final String? initialTitle;
  final String initialContent;
  final String? initialSummaryFromAI; // ChatScreen에서 전달된 요약본 (실제 저장될 요약)
  final List<String>? initialTags;   // ChatScreen에서 문자열 리스트로 전달된 태그

  const DiaryDetailScreen({
    Key? key,
    this.initialTitle,
    required this.initialContent, // AI가 생성한 내용 (편집 가능)
    this.initialSummaryFromAI,   // AI가 생성한 요약 (저장 시 사용)
    this.initialTags,
  }) : super(key: key);

  @override
  _DiaryDetailScreenState createState() => _DiaryDetailScreenState();
}

class _DiaryDetailScreenState extends State<DiaryDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _tagsController;
  late DateTime _selectedDate;
  bool _isSaving = false;

  // 디자인에 사용될 색상 및 스타일 정의 (이미지 참고)
  final Color _labelTextColor = Colors.black54;
  final Color _fieldBackgroundColor = Colors.grey.shade100; // 연한 회색 배경
  final double _labelFontSize = 14.0;
  final double _fieldFontSize = 15.0;
  final FontWeight _labelFontWeight = FontWeight.w500;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _titleController = TextEditingController(
        text: widget.initialTitle ??
            '오늘의 일기 (${DateFormat('yyyy.MM.dd').format(_selectedDate)})'); // 기본 제목 형식
    _contentController = TextEditingController(text: widget.initialContent);
    _tagsController =
        TextEditingController(text: widget.initialTags?.join(', ') ?? '');

    // 내용 컨트롤러에 리스너 추가하여 내용 변경 시 태그 자동 추천
    _contentController.addListener(_autoSuggestTags);

    // 초기 내용에 대해서도 태그 추천 실행 (initialTags가 없을 때만)
    if (widget.initialTags == null || widget.initialTags!.isEmpty) {
      _autoSuggestTags();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.removeListener(_autoSuggestTags); // 리스너 제거
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  // 간단한 규칙 기반 태그 자동 추천 함수
  void _autoSuggestTags() {
    final content = _contentController.text.toLowerCase(); // 소문자로 변환하여 비교
    List<String> suggestedTags = [];

    if (content.contains('피곤') || content.contains('힘들었') || content.contains('지쳤')) {
      suggestedTags.add('#피곤함');
    }
    if (content.contains('뿌듯') || content.contains('성공') || content.contains('잘했')) {
      suggestedTags.add('#뿌듯함');
    }
    if (content.contains('귀찮') || content.contains('아무것도 안했') || content.length < 50) { // 내용이 짧으면
      if (!suggestedTags.contains('#피곤함')) { // 피곤함과 중복 방지
        suggestedTags.add('#귀찮음');
      }
    }
    if (content.contains('슬펐') || content.contains('우울')) {
      suggestedTags.add('#슬픔');
    }
    if (content.contains('기뻤') || content.contains('행복') || content.contains('즐거웠')) {
      suggestedTags.add('#행복함');
    }
    // 추가적인 키워드 및 태그 매칭 규칙을 여기에 추가할 수 있습니다.

    // initialTags가 제공되지 않았거나 비어있을 때만 자동 추천된 태그로 설정
    if (widget.initialTags == null || widget.initialTags!.isEmpty) {
      if (mounted && suggestedTags.isNotEmpty) { // 위젯이 아직 마운트된 상태이고 추천 태그가 있을 때
        // 현재 _tagsController의 값과 suggestedTags를 비교하여 중복 없이 합치거나,
        // 단순히 suggestedTags로 덮어쓸 수 있습니다. 여기서는 덮어쓰기로 구현합니다.
        // 또는, 사용자가 이미 태그를 입력했다면 덮어쓰지 않도록 할 수도 있습니다.
        // 지금은 내용 변경 시 항상 자동 추천 태그로 업데이트.
        _tagsController.text = suggestedTags.join(', ');
      } else if (mounted && suggestedTags.isEmpty) {
        // 추천 태그가 없으면 기존 태그 필드를 비우거나 유지할 수 있습니다.
        // 여기서는 비웁니다. (단, 사용자가 직접 입력한 내용이 있다면 유지하는 것이 좋을 수 있음)
        _tagsController.text = '';
      }
    }
  }

  Future<void> _saveDiary() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목과 내용을 모두 입력해주세요.')),
      );
      return;
    }
    setState(() => _isSaving = true);

    final List<Tag> tagsToSave = _tagsController.text
        .split(',')
        .map((tagName) => tagName.trim())
        .where((tagName) => tagName.isNotEmpty)
        .map((tagName) => Tag(id: null, name: tagName)) // Tag 객체로 변환
        .toList();

    String summaryToSave = widget.initialSummaryFromAI ??
        (_contentController.text.length > 50
            ? '${_contentController.text.substring(0, 50)}...'
            : _contentController.text);

    final newDiaryToCreate = Diary(
      id: 0, // 서버에서 생성되므로 ID는 0 또는 null (API 설계에 따라)
      title: _titleController.text,
      content: _contentController.text,
      summary: summaryToSave,
      tags: tagsToSave,
      emotionTags: [], // 현재 UI에서 입력받지 않으므로 빈 리스트
      createdAt: _selectedDate, // 사용자가 선택한 날짜
      updatedAt: _selectedDate, // 생성 시에는 createdAt과 동일
    );

    try {
      final savedDiary = await DiaryApi.instance.createDiary(newDiaryToCreate);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('일기가 성공적으로 저장되었습니다!'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context, savedDiary); // 저장된 Diary 객체와 함께 이전 화면으로 돌아감
      }
    } catch (e) {
      print("Error saving diary: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('일기 저장에 실패했습니다: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(), // --- 미래 날짜 선택 불가하도록 수정 ---
      locale: const Locale('ko', 'KR'), // 한국어 로케일 사용
      helpText: '날짜 선택',
      cancelText: '취소',
      confirmText: '확인',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        if (widget.initialTitle == null ||
            widget.initialTitle!.startsWith('오늘의 일기')) {
          _titleController.text =
          '오늘의 일기 (${DateFormat('yyyy.MM.dd').format(_selectedDate)})';
        }
      });
    }
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: TextStyle(
            fontSize: _labelFontSize,
            fontWeight: _labelFontWeight,
            color: _labelTextColor),
      ),
    );
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: _fieldBackgroundColor,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: _fieldFontSize, color: Colors.black87),
        decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: _fieldFontSize),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 10.0)
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '일기 저장',
          style: TextStyle(
              color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: TextButton(
              onPressed: _isSaving ? null : _saveDiary,
              style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)
              ),
              child: _isSaving
                  ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5, // 두께 조절
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent), // 색상 조절
                  ))
                  : const Text('등록'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildSectionLabel('제목'),
            _buildCustomTextField(
              controller: _titleController,
              hintText: '제목을 입력해주세요',
            ),
            const SizedBox(height: 24),

            _buildSectionLabel('날짜'),
            InkWell(
              onTap: () => _selectDate(context),
              child: Container(
                width: double.infinity,
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: _fieldBackgroundColor,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('yyyy.MM.dd. EEEE', 'ko_KR').format(_selectedDate), // 요일도 포함
                      style: TextStyle(fontSize: _fieldFontSize, color: Colors.black87),
                    ),
                    Icon(Icons.calendar_today_outlined,
                        color: Colors.grey[600], size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionLabel('내용'),
            _buildCustomTextField(
              controller: _contentController,
              hintText: '오늘 하루 있었던 일을 자유롭게 작성해주세요.',
              maxLines: 10,
            ),
            const SizedBox(height: 24),

            _buildSectionLabel('태그'),
            _buildCustomTextField(
              controller: _tagsController,
              hintText: '#감정 #오늘한일 (쉼표로 구분)',
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
