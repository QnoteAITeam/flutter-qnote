// lib/features/diary/diary_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_qnote/api/diary_api.dart';
import 'package:flutter_qnote/models/diary.dart';
import 'package:flutter_qnote/models/tag.dart';
import 'package:flutter_qnote/models/emotion_tag.dart';
import 'package:intl/intl.dart';

class DiaryDetailScreen extends StatefulWidget {
  final String? initialTitle;
  final String? initialContent;
  final String? initialSummaryFromAI;
  final List<String>? initialTags;
  final DateTime? initialDate;
  final Diary? diaryToEdit;

  const DiaryDetailScreen({
    Key? key,
    this.initialTitle,
    this.initialContent,
    this.initialSummaryFromAI,
    this.initialTags,
    this.initialDate,
    this.diaryToEdit,
  }) : super(key: key);

  @override
  State<DiaryDetailScreen> createState() => _DiaryDetailScreenState();
}

class _DiaryDetailScreenState extends State<DiaryDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _tagsController;
  late DateTime _selectedDate;
  List<String> _currentTagsList = [];
  List<EmotionTag> _currentEmotionTags = [];

  bool _isLoading = false;

  final double _labelFontSize = 16.0;
  final FontWeight _labelFontWeight = FontWeight.bold;
  final Color _labelTextColor = Colors.black87;
  final Color _fieldBackgroundColor = Colors.grey.shade100;
  final double _fieldFontSize = 15.0;

  @override
  void initState() {
    super.initState();

    if (widget.diaryToEdit != null) {
      final diary = widget.diaryToEdit!;
      _titleController = TextEditingController(text: diary.title);
      _contentController = TextEditingController(text: diary.content);
      _currentTagsList = diary.tags.map((tag) => tag.name).toList();
      _tagsController = TextEditingController(text: _currentTagsList.join(', '));
      _selectedDate = diary.createdAt ?? diary.updatedAt ?? DateTime.now();
      _currentEmotionTags = List<EmotionTag>.from(diary.emotionTags);
    } else {
      _selectedDate = widget.initialDate ?? DateTime.now();
      _titleController = TextEditingController(
          text: widget.initialTitle ?? '오늘의 일기 (${DateFormat('yyyy.MM.dd. E', 'ko_KR').format(_selectedDate)})');
      _contentController = TextEditingController(text: widget.initialContent ?? '');
      _currentTagsList = List<String>.from(widget.initialTags ?? []);
      _tagsController = TextEditingController(text: _currentTagsList.join(', '));
      _currentEmotionTags = [];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _saveDiary() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final currentTagNames = _tagsController.text.split(',').map((e) => e.trim()).where((t) => t.isNotEmpty).toSet().toList();

    try {
      final List<Tag> tagsToSave = currentTagNames.map((name) => Tag(id: null, name: name)).toList();
      final List<EmotionTag> emotionTagsToSave = List<EmotionTag>.from(_currentEmotionTags);

      Diary diaryData = Diary(
        id: widget.diaryToEdit?.id,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        summary: widget.initialSummaryFromAI ?? widget.diaryToEdit?.summary ?? '',
        createdAt: widget.diaryToEdit?.createdAt ?? _selectedDate,
        updatedAt: DateTime.now(),
        tags: tagsToSave,
        emotionTags: emotionTagsToSave,
      );

      Diary resultDiary;
      if (widget.diaryToEdit != null) {
        resultDiary = await DiaryApi.instance.updateDiary(widget.diaryToEdit!.id!, diaryData);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('일기가 성공적으로 수정되었습니다!')));
      } else {
        resultDiary = await DiaryApi.instance.createDiary(diaryData);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('일기가 성공적으로 저장되었습니다!')));
      }
      if (mounted) Navigator.pop(context, resultDiary);
    } catch (e) {
      print("DiaryDetailScreen: Error saving diary: $e");
      if (mounted) {
        String displayError = "일기 저장 중 오류가 발생했습니다.";
        // ... (오류 메시지 처리 로직)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(displayError)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(now) ? now : _selectedDate,
      firstDate: DateTime(2000),
      lastDate: now, // **미래 날짜 선택 불가 (요청사항 2)**
      helpText: '일기 날짜 선택',
      cancelText: '취소',
      confirmText: '확인',
      locale: const Locale('ko', 'KR'),
    );

    if (picked != null && picked != _selectedDate) {
      if (mounted) {
        setState(() {
          _selectedDate = picked;
          if (widget.diaryToEdit == null &&
              (widget.initialTitle == null ||
                  _titleController.text.startsWith('오늘의 일기 (') ||
                  _titleController.text.isEmpty)) {
            _titleController.text = '오늘의 일기 (${DateFormat('yyyy.MM.dd. E', 'ko_KR').format(_selectedDate)})';
          }
        });
      }
    }
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
      child: Text(label, style: TextStyle(fontSize: _labelFontSize, fontWeight: _labelFontWeight, color: _labelTextColor)),
    );
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
    bool readOnly = false, // readOnly 플래그 추가
    Widget? suffixIcon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      decoration: BoxDecoration(
          color: enabled ? _fieldBackgroundColor : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.grey.shade300, width: 0.5)
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        readOnly: readOnly, // readOnly 설정
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: _fieldFontSize, color: Colors.black87),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: _fieldFontSize),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.diaryToEdit != null ? '일기 수정' : '새 일기 작성'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))),
            )
          else
            TextButton(
              onPressed: _isLoading ? null : _saveDiary,
              child: Text(widget.diaryToEdit != null ? '수정' : '등록',
                  style: TextStyle(
                      color: Theme.of(context).appBarTheme.actionsIconTheme?.color ??
                          (Theme.of(context).brightness == Brightness.dark ? Colors.white : Theme.of(context).primaryColor),
                      fontSize: 16, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16.0)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildSectionLabel('제목'),
            _buildCustomTextField(
              controller: _titleController,
              hintText: '일기 제목을 입력하세요',
            ),
            _buildSectionLabel('날짜'),
            // --- 날짜 선택 UI 수정 ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              decoration: BoxDecoration(
                  color: _fieldBackgroundColor,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey.shade300, width: 0.5)
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded( // 텍스트가 길어질 경우 아이콘 밀어내지 않도록
                    child: Padding( // 텍스트 자체에는 패딩을 주어 클릭 영역처럼 보이지 않게
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      child: Text(
                        DateFormat('yyyy.MM.dd. EEEE', 'ko_KR').format(_selectedDate),
                        style: TextStyle(fontSize: _fieldFontSize, color: Colors.black87),
                      ),
                    ),
                  ),
                  // **요청사항 1 반영: 달력 아이콘 클릭 시 날짜 선택**
                  IconButton(
                    icon: Icon(Icons.calendar_today_outlined, color: Colors.grey[600], size: 22), // 아이콘 색상 및 크기 조절
                    padding: EdgeInsets.zero, // IconButton 기본 패딩 제거
                    constraints: const BoxConstraints(), // IconButton 최소 크기 제한 제거
                    tooltip: '날짜 선택',
                    onPressed: () {
                      _selectDate(context); // 달력 아이콘 클릭 시 _selectDate 호출
                    },
                  ),
                ],
              ),
            ),
            // --- 날짜 선택 UI 수정 끝 ---
            const SizedBox(height: 24),
            _buildSectionLabel('내용'),
            _buildCustomTextField(
              controller: _contentController,
              hintText: '오늘 하루 있었던 일을 자유롭게 적어보세요...',
              maxLines: 10,
              keyboardType: TextInputType.multiline,
            ),
            _buildSectionLabel('태그'),
            _buildCustomTextField(
              controller: _tagsController,
              hintText: '#감정 #오늘한일 (쉼표로 구분하여 입력)',
            ),
            if (widget.initialSummaryFromAI != null && widget.initialSummaryFromAI!.isNotEmpty) ...[
              _buildSectionLabel('AI 요약 (참고용)'),
              Container(
                padding: const EdgeInsets.all(12.0),
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8.0), border: Border.all(color: Colors.blue.shade100)),
                child: Text(widget.initialSummaryFromAI!, style: TextStyle(fontSize: 14.0, color: Colors.blue.shade800, fontStyle: FontStyle.italic, height: 1.5)),
              ),
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
