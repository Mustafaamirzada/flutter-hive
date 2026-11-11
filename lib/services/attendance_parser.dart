import 'dart:convert';

import '../utils/jalali_utils.dart';

enum AttendanceStatus { present, absent, late, unrecorded }

class AttendanceDay {
  AttendanceDay({
    required this.date,
    required this.status,
    this.teacher,
    this.time,
  });

  final JalaliDate date;
  final AttendanceStatus status;
  final String? teacher;
  final String? time;

  String get monthKey => date.monthKey;
}

/// Flattens the `attendance` array inside a score into per-day statuses.
///
/// `attendees` is a JSON-encoded string like
/// `'[{"status": "present", "full_date": "1405-06-09"}]'` – when absent or
/// unparsable, the row falls back to its `created_at` with [AttendanceStatus.
/// unrecorded]. Records for the same day are merged with priority
/// present > late > absent > unrecorded.
class AttendanceParser {
  static const Map<AttendanceStatus, int> _priority = {
    AttendanceStatus.present: 3,
    AttendanceStatus.late: 2,
    AttendanceStatus.absent: 1,
    AttendanceStatus.unrecorded: 0,
  };

  static List<AttendanceDay> parse(List<Map<String, dynamic>> raw) {
    final byDay = <String, AttendanceDay>{};

    for (final record in raw) {
      final created = JalaliDate.tryParse(record['created_at']?.toString());
      final teacher =
          record['teacher'] is String ? record['teacher'] as String : null;
      final time = record['time'] is String ? record['time'] as String : null;

      final sessions = _decodeAttendees(record['attendees']);
      if (sessions.isEmpty) {
        if (created != null) {
          _merge(byDay, AttendanceDay(
            date: created,
            status: AttendanceStatus.unrecorded,
            teacher: teacher,
            time: time,
          ));
        }
        continue;
      }
      for (final session in sessions) {
        final date = JalaliDate.tryParse(session['full_date']?.toString()) ??
            created;
        if (date == null) continue;
        final status = _statusFor(session['status']?.toString());
        _merge(byDay, AttendanceDay(
          date: date,
          status: status,
          teacher: teacher,
          time: time,
        ));
      }
    }

    return byDay.values.toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Groups parsed days by Jalali month key (`1405-6`) in chronological order.
  static Map<String, List<AttendanceDay>> groupByMonth(List<AttendanceDay> days) {
    final grouped = <String, List<AttendanceDay>>{};
    for (final day in days) {
      grouped.putIfAbsent(day.monthKey, () => []).add(day);
    }
    return grouped;
  }

  static List<Map<String, dynamic>> _decodeAttendees(Object? attendees) {
    if (attendees is! String || attendees.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(attendees);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } on FormatException {
      return const [];
    }
  }

  static AttendanceStatus _statusFor(String? raw) => switch (raw?.toLowerCase()) {
        'present' => AttendanceStatus.present,
        'absent' => AttendanceStatus.absent,
        'late' => AttendanceStatus.late,
        _ => AttendanceStatus.unrecorded,
      };

  static void _merge(
      Map<String, AttendanceDay> byDay, AttendanceDay candidate) {
    final existing = byDay[candidate.date.toString()];
    if (existing == null ||
        _priority[candidate.status]! > _priority[existing.status]!) {
      byDay[candidate.date.toString()] = candidate;
    }
  }
}
