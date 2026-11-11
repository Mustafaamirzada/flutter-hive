import 'package:hive/hive.dart';

import 'models.dart';

class Score {
  Score({
    required this.subject,
    required this.student,
    required this.category,
    required this.subjectAverage,
    required this.subjectGrade,
    required this.subjectGpa,
    required this.homeworkCount,
    required this.homeworkCompletedCount,
    required this.homeworkCompletionRate,
    required this.attendance,
    required this.semesters,
    required this.homework,
  });

  final String subject;
  final String student;
  final String category;
  final double subjectAverage;
  final String subjectGrade;
  final double subjectGpa;
  final int homeworkCount;
  final int homeworkCompletedCount;
  final double homeworkCompletionRate;

  /// Raw maps kept dynamically – Hive serializes nested maps/lists natively.
  final List<Map<String, dynamic>> attendance;
  final List<Map<String, dynamic>> semesters;
  final List<Map<String, dynamic>> homework;

  String get key => subject;

  static List<Score> fromJsonList(List<dynamic> list) =>
      list.map(asMap).map(fromJson).toList();

  static Score fromJson(Map<String, dynamic> json) => Score(
        subject: asString(json['subject']),
        student: asString(json['student']),
        category: asString(json['category']),
        subjectAverage: asDouble(json['subject_average']),
        subjectGrade: asString(json['subject_grade']),
        subjectGpa: asDouble(json['subject_gpa']),
        homeworkCount: asDouble(json['homework_count']).toInt(),
        homeworkCompletedCount:
            asDouble(json['homework_completed_count']).toInt(),
        homeworkCompletionRate: asDouble(json['homework_completion_rate']),
        attendance: asMapList(json['attendance']),
        semesters: asMapList(json['semesters']),
        homework: asMapList(json['homework']),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'subject': subject,
        'student': student,
        'category': category,
        'subject_average': subjectAverage,
        'subject_grade': subjectGrade,
        'subject_gpa': subjectGpa,
        'homework_count': homeworkCount,
        'homework_completed_count': homeworkCompletedCount,
        'homework_completion_rate': homeworkCompletionRate,
        'attendance': attendance,
        'semesters': semesters,
        'homework': homework,
      };
}

class ScoreAdapter extends TypeAdapter<Score> {
  @override
  final int typeId = 1;

  @override
  Score read(BinaryReader reader) =>
      Score.fromJson(Map<String, dynamic>.from(reader.readMap()));

  @override
  void write(BinaryWriter writer, Score obj) => writer.writeMap(obj.toJson());
}
