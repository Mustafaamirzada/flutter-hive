import 'package:hive_flutter/hive_flutter.dart';

import '../models/models.dart';

/// Reads/writes the three cached collections in Hive boxes and offers
/// reactive `ValueListenable`s so screens rebuild on data refresh.
class HiveStore {
  static const String scoresBoxName = 'scores';
  static const String pdfsBoxName = 'pdfs';
  static const String coursesBoxName = 'new_courses';
  static const String settingsBoxName = 'fluhiv_settings';

  static const int scoreTypeId = 1;
  static const int newCourseTypeId = 2;
  static const int coursePdfTypeId = 3;

  static const String lightModeKey = 'light_mode';

  static Future<void> init() async {
    await Hive.initFlutter('fluhiv_cache');
    if (!Hive.isAdapterRegistered(scoreTypeId)) {
      Hive.registerAdapter(ScoreAdapter());
    }
    if (!Hive.isAdapterRegistered(newCourseTypeId)) {
      Hive.registerAdapter(NewCourseAdapter());
    }
    if (!Hive.isAdapterRegistered(coursePdfTypeId)) {
      Hive.registerAdapter(CoursePdfAdapter());
    }
    await Hive.openBox<Score>(scoresBoxName);
    await Hive.openBox<NewCourse>(coursesBoxName);
    await Hive.openBox<CoursePdf>(pdfsBoxName);
    await Hive.openBox<dynamic>(settingsBoxName);
  }

  bool get isLightMode {
    final box = Hive.box<dynamic>(settingsBoxName);
    return (box.get(lightModeKey) as bool?) ?? false;
  }

  Future<void> setLightMode(bool light) async {
    await Hive.box<dynamic>(settingsBoxName).put(lightModeKey, light);
  }

  Box<Score> get scores => Hive.box<Score>(scoresBoxName);
  Box<NewCourse> get courses => Hive.box<NewCourse>(coursesBoxName);
  Box<CoursePdf> get pdfs => Hive.box<CoursePdf>(pdfsBoxName);

  int countScores() => scores.length;
  int countCourses() => courses.length;
  int countPdfs() => pdfs.length;

  Future<void> saveScores(List<Score> items) async =>
      _saveAll(items, (item) => item.key, scores);

  Future<void> saveCourses(List<NewCourse> items) async =>
      _saveAll(items, (item) => item.key, courses);

  Future<void> savePdfs(List<CoursePdf> items) async =>
      _saveAll(items, (item) => item.key, pdfs);

  Future<void> _saveAll<T>(List<T> items, String Function(T) keyOf, Box<T> box) async {
    await box.clear();
    for (final item in items) {
      await box.put(keyOf(item), item);
    }
  }

  /// Toggles a homework entry as completed/uncompleted for the subject at
  /// [scoreKey] and recomputes the derived counts/rates in place.
  Future<void> setHomeworkCompleted(
      String scoreKey, int homeworkId, bool completed) async {
    final score = scores.get(scoreKey);
    if (score == null) return;
    final homework = score.homework.map((entry) {
      if ((entry['id'] ?? -1) != homeworkId) return entry;
      return Map<String, dynamic>.from(entry)..['is_completed'] = completed;
    }).toList();
    final completedCount =
        homework.where((h) => (h['is_completed'] ?? false) == true).length;
    final updated = Score(
      subject: score.subject,
      student: score.student,
      category: score.category,
      subjectAverage: score.subjectAverage,
      subjectGrade: score.subjectGrade,
      subjectGpa: score.subjectGpa,
      homeworkCount: homework.length,
      homeworkCompletedCount: completedCount,
      homeworkCompletionRate:
          homework.isEmpty ? 0 : completedCount / homework.length * 100,
      attendance: score.attendance,
      semesters: score.semesters,
      homework: homework,
    );
    await scores.put(scoreKey, updated);
  }
}
