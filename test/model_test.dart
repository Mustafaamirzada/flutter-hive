import 'package:flutter_test/flutter_test.dart';

import 'package:fluhiv/models/models.dart';
import 'package:fluhiv/services/attendance_parser.dart';
import 'package:fluhiv/utils/jalali_utils.dart';

void main() {
  group('Jalali utils', () {
    test('parses API date strings', () {
      final date = JalaliDate.tryParse('1405-06-09');
      expect(date, isNotNull);
      expect(date!.year, 1405);
      expect(date.month, 6);
      expect(date.day, 9);
      expect(date.monthName, 'Sunbula');
      expect(JalaliDate.tryParse('not a date'), isNull);
    });

    test('converts known Solar Hijri dates to Gregorian', () {
      // Nowruz of 1405 == 21 March 2026 (Saturday).
      expect(JalaliDate.tryParse('1405-01-01')!.toDateTime(),
          DateTime(2026, 3, 21));
      // Nowruz of 1404 == 21 March 2025.
      expect(JalaliDate.tryParse('1404-01-01')!.toDateTime(),
          DateTime(2025, 3, 21));
      // Second day of Nowruz 1405 = Monday 22 March 2026? No - 21 Mar 2026 is
      // Saturday, so +1 day is Sunday 22 March 2026.
      expect(JalaliDate.tryParse('1405-01-02')!.toDateTime(),
          DateTime(2026, 3, 22));
    });

    test('saturday-first weekday indexes align with the real calendar', () {
      // 2026-03-21 was a Saturday -> index 0.
      expect(
          JalaliDate.tryParse('1405-01-01')!.saturdayFirstWeekday, 0);
      // 2025-03-21 was a Friday -> index 6.
      expect(
          JalaliDate.tryParse('1404-01-01')!.saturdayFirstWeekday, 6);
    });
  });

  group('AttendanceParser', () {
    test('decodes attendees JSON string into present days', () {
      final days = AttendanceParser.parse([
        {
          'attendees': '[{"status": "present", "full_date": "1405-06-09"}]',
          'created_at': '1405-06-09',
          'teacher': 'Ahmad Popal',
          'time': '5:00 PM',
        },
      ]);

      expect(days, hasLength(1));
      expect(days.single.status, AttendanceStatus.present);
      expect(days.single.date, JalaliDate(year: 1405, month: 6, day: 9));
      expect(days.single.time, '5:00 PM');
    });

    test('null attendees fall back to created_at as unrecorded', () {
      final days = AttendanceParser.parse([
        {
          'attendees': null,
          'created_at': '1405-06-23',
        },
      ]);
      expect(days.single.status, AttendanceStatus.unrecorded);
      expect(days.single.date.day, 23);
      expect(days.single.date.month, 6);
    });

    test('groups days by Jalali month and merges duplicates by priority', () {
      final days = AttendanceParser.parse([
        {
          'attendees': null, // same day but weaker status -> ignored
          'created_at': '1405-06-09',
        },
        {
          'attendees':
              '[{"status": "absent", "full_date": "1405-06-09"}]',
          'created_at': '1405-06-09',
        },
        {
          'attendees':
              '[{"status": "present", "full_date": "1405-07-01"}]',
          'created_at': '1405-07-01',
        },
      ]);

      final grouped = AttendanceParser.groupByMonth(days);
      expect(grouped.keys, ['1405-6', '1405-7']);
      expect(grouped['1405-6']!.single.status, AttendanceStatus.absent);
      expect(grouped['1405-7']!.single.status, AttendanceStatus.present);
    });

    test('useRalmalformed attendees strings are ignored safely', () {
      final days = AttendanceParser.parse([
        {'attendees': '[{broken json', 'created_at': '1405-06-21'},
      ]);
      expect(days.single.status, AttendanceStatus.unrecorded);
    });
  });

  group('Model helpers', () {
    test('Score.fromJson maps all primitive and nested fields', () {
      final score = Score.fromJson(const {
        'subject': 'IRC',
        'student': 'mustafa',
        'category': 'English',
        'subject_average': 88,
        'subject_grade': 'B',
        'subject_gpa': 3,
        'homework_count': 2,
        'homework_completed_count': 1,
        'homework_completion_rate': 50,
        'attendance': [],
        'semesters': [],
        'homework': [
          {'is_completed': false, 'note': 'read chapter 1'}
        ],
      });

      expect(score.subject, 'IRC');
      expect(score.subjectAverage, 88);
      expect(score.subjectGrade, 'B');
      expect(score.key, 'IRC');
      expect(score.homework.single['note'], 'read chapter 1');
    });

    test('NewCourse.fromJson parses dates and integers', () {
      final course = NewCourse.fromJson(const {
        'id': '4',
        'title': 'Deep Learning',
        'start_at': '2027-09-30',
      });

      expect(course.id, 4);
      expect(course.startAt, DateTime(2027, 9, 30));
    });
  });
}
