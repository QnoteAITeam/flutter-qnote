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

    print("DiaryDetailScreen initState: initialTitle = ${widget.initialTitle}");
    print("DiaryDetailScreen initState: initialContent = ${widget.initialContent}");
    print("DiaryDetailScreen initState: initialTags = ${widget.initialTags}");
    print("DiaryDetailScreen initState: initialDate = ${widget.initialDate}");
    print("DiaryDetailScreen initState: diaryToEdit ID = ${widget.diaryToEdit?.id}");

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

    print("DiaryDetailScreen initState (after init): _titleController.text = ${_titleController.text}");
    print("DiaryDetailScreen initState (after init): _contentController.text = ${_contentController.text}");
    print("DiaryDetailScreen initState (after init): _tagsController.text = ${_tagsController.text}");
    print("DiaryDetailScreen initState (after init): _currentTagsList = $_currentTagsList");
    print("DiaryDetailScreen initState (after init): _currentEmotionTags (names) = ${_currentEmotionTags.map((e) => e.name).toList()}");
    print("DiaryDetailScreen initState (after init): _selectedDate = $_selectedDate");

    _contentController.addListener(_autoSuggestTags);
    if (_currentTagsList.isEmpty) {
      _autoSuggestTags();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _autoSuggestTags() {
    // 현재 내용 기반 자동 태그 제안 로직 없음
  }

  Future<void> _saveDiary() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final currentTagNames = _tagsController.text
        .split(',')
        .map((e) => e.trim())
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList();

    print("DiaryDetailScreen _saveDiary: Title = ${_titleController.text}");
    print("DiaryDetailScreen _saveDiary: Content = ${_contentController.text}");
    print("DiaryDetailScreen _saveDiary: Tag Names for API = $currentTagNames");
    final String dateForApi = DateFormat("yyyy-MM-ddTHH:mm:ss.SSS'Z'").format(_selectedDate.toUtc());
    print("DiaryDetailScreen _saveDiary: Date for API (ISO8601 UTC) = $dateForApi");

    try {
      final List<Tag> tagsToSave = currentTagNames.map((name) => Tag(id: null, name: name)).toList();
      final List<EmotionTag> emotionTagsToSave = List<EmotionTag>.from(_currentEmotionTags); // 현재 UI에서 수정 안하므로 기존 값 사용

      Diary diaryData = Diary(
        id: widget.diaryToEdit?.id,
        title: _titleController.text,
        content: _contentController.text,
        summary: widget.initialSummaryFromAI ?? widget.diaryToEdit?.summary ?? '',
        createdAt: widget.diaryToEdit?.createdAt ?? _selectedDate,
        updatedAt: DateTime.now(),
        tags: tagsToSave,
        emotionTags: emotionTagsToSave,
      );

      Diary resultDiary;
      if (widget.diaryToEdit != null) {
        print("DiaryDetailScreen _saveDiary: Updating diary with ID = ${widget.diaryToEdit!.id!}");
        resultDiary = await DiaryApi.instance.updateDiary(widget.diaryToEdit!.id!, diaryData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('일기가 성공적으로 수정되었습니다!')),
          );
        }
      } else {
        print("DiaryDetailScreen _saveDiary: Creating new diary.");
        resultDiary = await DiaryApi.instance.createDiary(diaryData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('일기가 성공적으로 저장되었습니다!')),
          );
        }
      }
      if (mounted) {
        Navigator.pop(context, resultDiary);
      }
    } catch (e) {
      print("DiaryDetailScreen: Error saving diary: $e");
      if (mounted) {
        String displayError = "일기 저장 중 오류가 발생했습니다.";
        if (e.toString().contains("500") || e.toString().toLowerCase().contains("internal server error")) {
          displayError = "서버에서 오류가 발생하여 일기를 저장하지 못했습니다. (서버 로그 확인 필요)";
        } else if (e.toString().contains("Failed to create diary") || e.toString().contains("Failed to update diary")) {
          displayError = "일기 저장에 실패했습니다. 입력 내용을 확인하거나 다시 시도해주세요.";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(displayError),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(), // 미래 날짜 선택 불가
      helpText: '일기 날짜 선택',
      cancelText: '취소',
      confirmText: '확인',
      locale: const Locale('ko', 'KR'),
    );
    if (picked != null && picked != _selectedDate) {
      if (mounted) {
        setState(() {
          _selectedDate = picked;
          if (widget.diaryToEdit == null && (widget.initialTitle == null || widget.initialTitle!.startsWith('오늘의 일기'))) {
            _titleController.text = '오늘의 일기 (${DateFormat('yyyy.MM.dd. E', 'ko_KR').format(_selectedDate)})';
          }
        });
      }
    }
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
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
    bool enabled = true,
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
        readOnly: !enabled && suffixIcon == null, // suffixIcon이 없으면서 비활성화된 경우만 readOnly (날짜 필드처럼)
        // 일반 텍스트 필드는 enabled=false 만으로도 입력 방지됨
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
              child: Text(
                widget.diaryToEdit != null ? '수정' : '등록',
                style: TextStyle(
                  color: Theme.of(context).appBarTheme.actionsIconTheme?.color ??
                      (Theme.of(context).brightness == Brightness.dark ? Colors.white : Theme.of(context).primaryColor),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
              ),
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
                decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.blue.shade100)
                ),
                child: Text(
                  widget.initialSummaryFromAI!,
                  style: TextStyle(fontSize: 14.0, color: Colors.blue.shade800, fontStyle: FontStyle.italic, height: 1.5),
                ),
              ),
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
