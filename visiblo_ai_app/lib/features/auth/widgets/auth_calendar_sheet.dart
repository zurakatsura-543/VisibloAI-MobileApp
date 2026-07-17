import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

Future<DateTime?> showAuthCalendarSheet({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String title = 'Publishing Calendar',
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return _AuthCalendarSheet(
        title: title,
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
      );
    },
  );
}

class _AuthCalendarSheet extends StatefulWidget {
  const _AuthCalendarSheet({
    required this.title,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  final String title;
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<_AuthCalendarSheet> createState() => _AuthCalendarSheetState();
}

class _AuthCalendarSheetState extends State<_AuthCalendarSheet> {
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    _displayedMonth = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
    );
  }

  bool get _canGoPrevious {
    final firstMonth = DateTime(widget.firstDate.year, widget.firstDate.month);
    return _displayedMonth.isAfter(firstMonth);
  }

  bool get _canGoNext {
    final lastMonth = DateTime(widget.lastDate.year, widget.lastDate.month);
    return _displayedMonth.isBefore(lastMonth);
  }

  @override
  Widget build(BuildContext context) {
    final days = _visibleDaysForMonth(_displayedMonth);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6DEE8),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.brandBlue,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF5F8FC),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: Color(0xFFE45A62),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _MonthArrowButton(
                      icon: Icons.chevron_left_rounded,
                      enabled: _canGoPrevious,
                      onTap: _canGoPrevious
                          ? () {
                              setState(() {
                                _displayedMonth = DateTime(
                                  _displayedMonth.year,
                                  _displayedMonth.month - 1,
                                );
                              });
                            }
                          : null,
                    ),
                    Expanded(
                      child: Text(
                        _monthYearLabel(_displayedMonth),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.brandBlue,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _MonthArrowButton(
                      icon: Icons.chevron_right_rounded,
                      enabled: _canGoNext,
                      onTap: _canGoNext
                          ? () {
                              setState(() {
                                _displayedMonth = DateTime(
                                  _displayedMonth.year,
                                  _displayedMonth.month + 1,
                                );
                              });
                            }
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    for (final label in _weekdayLabels)
                      Expanded(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9AA8BA),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFE8EDF3)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 280,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: days.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          childAspectRatio: 0.82,
                        ),
                    itemBuilder: (context, index) {
                      final day = days[index];
                      final isCurrentMonth =
                          day.month == _displayedMonth.month &&
                          day.year == _displayedMonth.year;
                      final isSelected = _isSameDay(day, widget.initialDate);
                      final isDisabled =
                          day.isBefore(_dateOnly(widget.firstDate)) ||
                          day.isAfter(_dateOnly(widget.lastDate));
                      final marker = isCurrentMonth && !isDisabled
                          ? _markerTypeFor(day)
                          : null;

                      return _CalendarDayCell(
                        date: day,
                        isCurrentMonth: isCurrentMonth,
                        isSelected: isSelected,
                        isDisabled: isDisabled,
                        marker: marker,
                        onTap: isDisabled
                            ? null
                            : () => Navigator.of(context).pop(day),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                const Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 14,
                  runSpacing: 8,
                  children: [
                    _CalendarLegend(label: 'Post', color: AppColors.brandBlue),
                    _CalendarLegend(label: 'Offer', color: Color(0xFFF3A21A)),
                    _CalendarLegend(label: 'Event', color: Color(0xFF7C5CF5)),
                    _CalendarLegend(label: 'Photo', color: AppColors.primary),
                    _CalendarLegend(label: 'Product', color: Color(0xFF49BE75)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthArrowButton extends StatelessWidget {
  const _MonthArrowButton({
    required this.icon,
    required this.enabled,
    this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F8FC),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE5EDF6)),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 18,
          color: enabled ? AppColors.brandBlue : const Color(0xFFBFC9D7),
        ),
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.date,
    required this.isCurrentMonth,
    required this.isSelected,
    required this.isDisabled,
    required this.marker,
    this.onTap,
  });

  final DateTime date;
  final bool isCurrentMonth;
  final bool isSelected;
  final bool isDisabled;
  final _CalendarMarkerType? marker;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = isSelected
        ? AppColors.white
        : !isCurrentMonth
        ? const Color(0xFFC7D2E0)
        : isDisabled
        ? const Color(0xFFD4DCE7)
        : AppColors.brandBlue;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.brandBlue : Colors.transparent,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 13.5,
                color: textColor,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 6,
            child: marker == null || isSelected
                ? const SizedBox.shrink()
                : Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: marker!.color,
                      shape: BoxShape.circle,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.mutedText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _CalendarMarkerType {
  const _CalendarMarkerType(this.color);

  final Color color;
}

const _weekdayLabels = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

List<DateTime> _visibleDaysForMonth(DateTime month) {
  final firstDay = DateTime(month.year, month.month, 1);
  final offset = firstDay.weekday % 7;
  final start = firstDay.subtract(Duration(days: offset));
  return List<DateTime>.generate(
    42,
    (index) => DateTime(start.year, start.month, start.day + index),
  );
}

String _monthYearLabel(DateTime value) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[value.month - 1]} ${value.year}';
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

_CalendarMarkerType? _markerTypeFor(DateTime date) {
  if (date.day % 11 == 0) {
    return const _CalendarMarkerType(AppColors.brandBlue);
  }
  if (date.day % 9 == 0) {
    return const _CalendarMarkerType(Color(0xFFF3A21A));
  }
  if (date.day % 8 == 0) {
    return const _CalendarMarkerType(Color(0xFF7C5CF5));
  }
  if (date.day % 6 == 0) {
    return const _CalendarMarkerType(AppColors.primary);
  }
  if (date.day % 5 == 0) {
    return const _CalendarMarkerType(Color(0xFF49BE75));
  }
  return null;
}
