import 'package:flutter/material.dart';

import '../../services/attendance_parser.dart';
import '../../utils/jalali_utils.dart';
import '../theme.dart';

/// GitHub-style attendance calendar: one solid card per Solar-Hijri month laid
/// out as a real calendar (Saturday-first columns, one row per week).
class AttendanceHeatmap extends StatelessWidget {
  const AttendanceHeatmap({super.key, required this.records});

  /// The raw `attendance` list stored on a [Score].
  final List<Map<String, dynamic>> records;

  @override
  Widget build(BuildContext context) {
    final days = AttendanceParser.parse(records);
    if (days.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Text('No attendance recorded yet.'),
      );
    }

    final months = AttendanceParser.groupByMonth(days);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in months.entries) ...[
          _MonthCalendar(monthKey: entry.key, days: entry.value),
          const SizedBox(height: 12),
        ],
        const _Legend(),
      ],
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({required this.monthKey, required this.days});

  final String monthKey;
  final List<AttendanceDay> days;

  static const List<String> _weekdayLabels = [
    'Sa', 'Su', 'Mo', 'Tu', 'We', 'Th', 'Fr',
  ];

  // Squares a little taller than wide so they read as calendar tiles.
  static const double _cellHeight = 40;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;

    final parts = monthKey.split('-');
    final year = int.parse(parts[0]);
    final monthIndex = int.parse(parts[1]);
    final firstDay = JalaliDate(year: year, month: monthIndex, day: 1);

    final byDay = <int, AttendanceDay>{};
    for (final day in days) {
      byDay[day.date.day] = day;
    }

    final present = days.where((d) => d.status == AttendanceStatus.present).length;
    final absent = days.where((d) => d.status == AttendanceStatus.absent).length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.tone.tile,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.tone.tileBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${firstDay.monthName} $year',
                  style: text.titleSmall
                      ?.copyWith(color: context.tone.text),
                ),
              ),
              Text(
                '$present present · ${absent > 0 ? '$absent absent · ' : ''}'
                '${days.length - present - absent} not recorded',
                style: text.labelSmall?.copyWith(color: context.tone.textDim),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _WeekGrid(
            leadingBlanks: firstDay.saturdayFirstWeekday,
            monthLength: firstDay.monthLength,
            byDay: byDay,
            weekdayLabels: _weekdayLabels,
          ),
        ],
      ),
    );
  }
}

/// Classic calendar layout: weekday columns stretched across the full width,
/// one `TableRow` per week,
class _WeekGrid extends StatelessWidget {
  const _WeekGrid({
    required this.leadingBlanks,
    required this.monthLength,
    required this.byDay,
    required this.weekdayLabels,
  });

  final int leadingBlanks;
  final int monthLength;
  final Map<int, AttendanceDay> byDay;
  final List<String> weekdayLabels;

  @override
  Widget build(BuildContext context) {
    // Slots: leading blanks for weekday alignment, then one slot per day.
    final slots = <_Slot>[];
    for (var i = 0; i < leadingBlanks; i++) {
      slots.add(const _Slot.blank());
    }
    for (var i = 1; i <= monthLength; i++) {
      slots.add(_Slot(day: i, record: byDay[i]));
    }
    while (slots.length % 7 != 0) {
      slots.add(const _Slot.blank());
    }

    // Chunk the flat slot list into week rows.
    final weeks = <List<_Slot>>[
      for (var i = 0; i < slots.length; i += 7) slots.sublist(i, i + 7),
    ];

    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      // Stretch all 7 weekday columns evenly across the card width.
      columnWidths: {
        for (var i = 0; i < 7; i++) i: const FlexColumnWidth(1),
      },
      children: [
        TableRow(
          children: [
            for (final label in weekdayLabels)
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: Theme.of(context).colorScheme.outline),
              ),
          ],
        ),
        for (final week in weeks)
          TableRow(
            children: [
              for (final slot in week)
                Padding(
                  padding: const EdgeInsets.fromLTRB(3, 4, 3, 0),
                  child: _DayCell(slot),
                ),
            ],
          ),
      ],
    );
  }
}

class _Slot {
  const _Slot({required this.day, this.record});
  const _Slot.blank()
      : day = 0,
        record = null;

  /// 0 marks invisible grid padding (outside the real month).
  final int day;
  final AttendanceDay? record;

  bool get isPadding => day == 0;
}

class _DayCell extends StatelessWidget {
  const _DayCell(this.slot);

  final _Slot slot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = context.tone;

    if (slot.isPadding && slot.record == null) {
      return const SizedBox(height: _MonthCalendar._cellHeight);
    }
    final record = slot.record;

    final Color fill;
    final Color border;
    final Widget child;
    if (record == null) {
      fill = tone.emptyDay.withValues(alpha: 0.55);
      border = Colors.transparent;
      child = Text(
        '${slot.day}',
        textAlign: TextAlign.center,
        style: theme.textTheme.labelSmall?.copyWith(
          color: tone.textDim,
          fontSize: 11,
        ),
      );
    } else {
      switch (record.status) {
        case AttendanceStatus.present:
          fill = const Color(0xFF2E7D32);
          border = Colors.transparent;
        case AttendanceStatus.absent:
          fill = const Color(0xFFC62828);
          border = Colors.transparent;
        case AttendanceStatus.late:
          fill = const Color(0xFFF9A825);
          border = Colors.transparent;
        case AttendanceStatus.unrecorded:
          fill = tone.emptyDay;
          border = tone.tileBorder;
      }
      child = record.status == AttendanceStatus.present
          ? const Icon(
              Icons.check_rounded,
              size: 18,
              color: Colors.white,
            )
          : Text(
              '${slot.day}',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: record.status == AttendanceStatus.late
                    ? Colors.black87
                    : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            );
    }

      return Tooltip(
      message: _tooltip,
      child: Container(
        height: _MonthCalendar._cellHeight,
        constraints: const BoxConstraints(
            minHeight: _MonthCalendar._cellHeight),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(9),
          border: border == Colors.transparent
              ? null
              : Border.all(color: border),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }

  String get _tooltip {
    final r = slot.record;
    if (r == null) return 'Day ${slot.day}';
    final label = switch (r.status) {
      AttendanceStatus.present => 'Present',
      AttendanceStatus.absent => 'Absent',
      AttendanceStatus.late => 'Late',
      AttendanceStatus.unrecorded => 'Not recorded',
    };
    return '${r.date} · $label${r.time == null ? '' : ' · ${r.time}'}';
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    Widget dot(Color color, String label, {bool outline = false}) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: outline ? null : color,
              shape: BoxShape.circle,
              border: outline ? Border.all(color: color) : null,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: text.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      );
    }

    return Wrap(
      alignment: WrapAlignment.start,
      spacing: 14,
      runSpacing: 6,
      children: [
        dot(const Color(0xFF2E7D32), 'Present'),
        dot(const Color(0xFFC62828), 'Absent'),
        dot(const Color(0xFFF9A825), 'Late'),
        dot(context.tone.textDim, 'Not recorded', outline: true),
      ],
    );
  }
}
