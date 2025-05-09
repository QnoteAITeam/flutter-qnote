// lib/widgets/calendar_widget.dart
import 'package:flutter/material.dart';

class CalendarWidget extends StatefulWidget {
  final ValueChanged<int>? onFlameCountChanged;
  const CalendarWidget({Key? key, this.onFlameCountChanged}) : super(key: key);

  @override
  _CalendarWidgetState createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  DateTime _focusedDate = DateTime(2025, 1, 1);
  final Set<int> _flameDays = {};
  final Map<String, Set<int>> _savedFlames = {};
  static const List<String> _monthNames = [
    '1월','2월','3월','4월','5월','6월',
    '7월','8월','9월','10월','11월','12월'
  ];

  void _toggleDay(int day) {
    setState(() {
      if (!_flameDays.remove(day)) {
        _flameDays.add(day);
      }

      widget.onFlameCountChanged?.call(_flameDays.length);
    });
  }

  void _prevMonth() {
    setState(() {

      final key = '${_focusedDate.year}-${_focusedDate.month}';
      _savedFlames[key] = Set.from(_flameDays);

      final year = _focusedDate.month == 1
          ? _focusedDate.year - 1
          : _focusedDate.year;
      final month = _focusedDate.month == 1
          ? 12
          : _focusedDate.month - 1;
      _focusedDate = DateTime(year, month, 1);

      final newKey = '${_focusedDate.year}-${_focusedDate.month}';
      _flameDays
        ..clear()
        ..addAll(_savedFlames[newKey] ?? {});
    });
  }

  void _nextMonth() {
    setState(() {
      final key = '${_focusedDate.year}-${_focusedDate.month}';
      _savedFlames[key] = Set.from(_flameDays);

      final year = _focusedDate.month == 12
          ? _focusedDate.year + 1
          : _focusedDate.year;
      final month = _focusedDate.month == 12
          ? 1
          : _focusedDate.month + 1;
      _focusedDate = DateTime(year, month, 1);

      final newKey = '${_focusedDate.year}-${_focusedDate.month}';
      _flameDays
        ..clear()
        ..addAll(_savedFlames[newKey] ?? {});
    });
  }
  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(
      _focusedDate.year, _focusedDate.month + 1, 0,
    ).day;
    final offset = _focusedDate.weekday - 1;
    final totalCells = offset + daysInMonth;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: _prevMonth),
              Text(
                '${_monthNames[_focusedDate.month - 1]} ${_focusedDate.year}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: _nextMonth),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              Text('MON', style: TextStyle(color: Colors.grey)),
              Text('TUE', style: TextStyle(color: Colors.grey)),
              Text('WED', style: TextStyle(color: Colors.grey)),
              Text('THU', style: TextStyle(color: Colors.grey)),
              Text('FRI', style: TextStyle(color: Colors.grey)),
              Text('SAT', style: TextStyle(color: Colors.grey)),
              Text('SUN', style: TextStyle(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            key: ValueKey('${_focusedDate.year}-${_focusedDate.month}'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7, mainAxisSpacing: 8, crossAxisSpacing: 8),
            itemCount: totalCells,
            itemBuilder: (context, idx) {
              if (idx < offset) return const SizedBox();
              final day = idx - offset + 1;
              final isFlame = _flameDays.contains(day);
              return GestureDetector(
                onTap: () => _toggleDay(day),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFlame
                        ? Colors.blue.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                  ),
                  child: Center(
                    child: isFlame
                        ? const Icon(Icons.local_fire_department,
                        color: Colors.orange, size: 20)
                        : const SizedBox.shrink(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
