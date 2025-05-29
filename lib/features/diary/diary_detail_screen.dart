import 'package:flutter/material.dart';
import 'package:flutter_qnote/api/diary_api.dart';
import 'package:flutter_qnote/models/diary.dart';
import 'package:flutter_qnote/api/dto/get_diary_info_dto.dart'; // DTO import
import 'package:intl/intl.dart';
import 'widgets/date_selector_widget.dart';

// DTO → Diary 변환 함수
Diary diaryFromDto(FetchDiaryResponseDto dto) {
  return Diary(
    id: dto.id,
    title: dto.title,
    content: dto.content,
    summary: dto.summary,
    createdAt: dto.createdAt,
    updatedAt: dto.createdAt,
    tags: dto.tags,
    emotionTags: dto.emotionTags,
  );
}

class DiaryDetailScreen extends StatefulWidget {
  final Diary? diaryToEdit;
  final String? initialTitle;
  final String? initialContent;
  final String? initialSummaryFromAI;
  final List<String>? initialTags;
  final DateTime? initialDate;

  const DiaryDetailScreen({
    Key? key,
    this.diaryToEdit,
    this.initialTitle,
    this.initialContent,
    this.initialSummaryFromAI,
    this.initialTags,
    this.initialDate,
  }) : super(key: key);

  @override
  State<DiaryDetailScreen> createState() => _DiaryDetailScreenState();
}

class _DiaryDetailScreenState extends State<DiaryDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _tagsController;
  late DateTime _selectedDate = DateTime.now().add(const Duration(hours: 9));
  bool _isLoading = false;

  static const Color _fieldBackgroundColor = Colors.white;
  static const double _fieldFontSize = 15.0;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    if (widget.diaryToEdit != null) {
      final diary = widget.diaryToEdit!;
      _titleController = TextEditingController(text: diary.title);
      _contentController = TextEditingController(text: diary.content);
      final allTags = [...diary.tags, ...diary.emotionTags];
      _tagsController = TextEditingController(text: allTags.join(', '));
      _selectedDate = diary.createdAt ?? diary.updatedAt ?? DateTime.now().add(const Duration(hours: 9));
    } else {
      _selectedDate = widget.initialDate ?? DateTime.now().add(const Duration(hours: 9));
      _titleController = TextEditingController(text: widget.initialTitle ?? _defaultTitleForDate(_selectedDate));
      _contentController = TextEditingController(text: widget.initialContent ?? '');
      _tagsController = TextEditingController(text: (widget.initialTags ?? []).join(', '));
    }
  }

  String _defaultTitleForDate(DateTime date) {
    return '오늘의 일기 (${DateFormat('MM.dd', 'ko_KR').format(date)})';
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
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final currentTagNames = _tagsController.text
        .split(RegExp(r'[,\s]+'))
        .map((e) => e.trim())
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList();

    try {
      String diaryTitle = _titleController.text.trim();
      if (diaryTitle.isEmpty) {
        diaryTitle = _defaultTitleForDate(_selectedDate);
      }
      String diaryContent = _contentController.text.trim();

      String clientSideSummary;
      if (widget.initialSummaryFromAI != null && widget.initialSummaryFromAI!.isNotEmpty) {
        clientSideSummary = widget.initialSummaryFromAI!;
      } else if (widget.diaryToEdit?.summary != null && widget.diaryToEdit!.summary.isNotEmpty) {
        clientSideSummary = widget.diaryToEdit!.summary;
      } else if (diaryContent.isNotEmpty) {
        clientSideSummary = diaryContent.length > 80 ? '${diaryContent.substring(0, 80)}...' : diaryContent;
      } else {
        clientSideSummary = '';
      }

      final diaryDataForApi = Diary(
        id: widget.diaryToEdit?.id,
        title: diaryTitle,
        content: diaryContent,
        summary: widget.initialSummaryFromAI ?? clientSideSummary,
        createdAt: widget.diaryToEdit?.createdAt ?? _selectedDate,
        updatedAt: DateTime.now().add(const Duration(hours: 9)),
        tags: currentTagNames,
        emotionTags: [],
      );
      // 수정된 부분: DTO 반환 → 변환 후 Diary로 사용
      FetchDiaryResponseDto resultDto;
      if (widget.diaryToEdit != null) {
        resultDto = await DiaryApi.instance.updateDiary(widget.diaryToEdit!.id!, diaryDataForApi);
      } else {
        resultDto = await DiaryApi.instance.createDiary(diaryDataForApi);
      }

      Diary resultDiaryFromServer = diaryFromDto(resultDto);

      Diary diaryToReturn = Diary(
        id: resultDiaryFromServer.id,
        title: resultDiaryFromServer.title,
        content: resultDiaryFromServer.content,
        summary: (resultDiaryFromServer.summary.isNotEmpty)
            ? resultDiaryFromServer.summary
            : clientSideSummary,
        createdAt: resultDiaryFromServer.createdAt,
        updatedAt: resultDiaryFromServer.updatedAt,
        tags: resultDiaryFromServer.tags,
        emotionTags: resultDiaryFromServer.emotionTags,
      );

      if (mounted) Navigator.pop(context, diaryToReturn);
    } catch (e) {
      if (mounted) {
        String displayError = "일기 저장 중 오류가 발생했습니다. 다시 시도해주세요.";
        if (e.toString().contains("Failed host lookup")) {
          displayError = "서버에 연결할 수 없습니다. 인터넷 연결을 확인해주세요.";
        } else if (e.toString().toLowerCase().contains('unauthorized') || e.toString().contains('401')) {
          displayError = "인증 오류가 발생했습니다. 다시 로그인해주세요.";
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(displayError)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final DateTime now = DateTime.now().add(const Duration(hours: 9));
    final DateTime firstSelectableDate = DateTime(2000);
    final DateTime initialPickerDate = _selectedDate;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialPickerDate,
      firstDate: firstSelectableDate,
      lastDate: now,
      currentDate: now,
      helpText: '일기 날짜 선택',
      cancelText: '취소',
      confirmText: '확인',
      locale: const Locale('ko', 'KR'),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColorDark,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      if (mounted) {
        setState(() {
          _selectedDate = picked;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        FocusScope.of(context).unfocus();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
          title: Text(
            widget.diaryToEdit != null ? '오늘의 일기' : '일기 저장',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              FocusScope.of(context).unfocus();
              Navigator.pop(context);
            },
          ),
          actions: widget.diaryToEdit != null
              ? [] // 오늘의 일기 상세보기면 오른쪽 버튼 없음!
              : [
            IconButton(
              icon: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_alt_rounded, color: Color(0xFFB59A7B)),
              onPressed: _isLoading ? null : _saveDiary,
              tooltip: '저장',
            ),
          ],
        ),

        backgroundColor: const Color(0xFFF4F6F8),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel('제목'),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: '제목을 입력해주세요.',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide(width: 0.7, color: Color(0xFFCCCCCC)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide(width: 0.7, color: Color(0xFFCCCCCC)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide(width: 1.1, color: Color(0xFFB59A7B)),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 18),
              const _SectionLabel('날짜'),
              DateSelectorWidget(
                selectedDate: _selectedDate,
                onDateTap:  widget.diaryToEdit != null
                    ? null
                    : () => _selectDate(context),
                fieldBackgroundColor: _fieldBackgroundColor,
                fieldFontSize: _fieldFontSize,
                showCalendarIcon: widget.diaryToEdit == null,
              ),
              const SizedBox(height: 18),
              const _SectionLabel('내용'),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300, width: 0.5),
                ),
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _contentController,
                  maxLines: 10,
                  minLines: 5,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '오늘 하루 있었던 일을 자유롭게 적어보세요...',
                  ),
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 18),
              const _SectionLabel('태그'),
              TextField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  hintText: '#감정 #오늘한일 (쉼표로 구분하여 입력)',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide(width: 0.7, color: Color(0xFFCCCCCC)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide(width: 0.7, color: Color(0xFFCCCCCC)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide(width: 1.1, color: Color(0xFFB59A7B)),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 2),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
      ),
    );
  }
}
