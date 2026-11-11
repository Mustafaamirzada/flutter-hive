import 'package:hive/hive.dart';

import 'models.dart';

class CoursePdf {
  CoursePdf({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.category,
    required this.teacher,
    required this.time,
    required this.course,
    required this.createdAt,
  });

  final int id;
  final String filePath;
  final String fileName;
  final String category;
  final String teacher;
  final String time;
  final String course;
  final DateTime? createdAt;

  String get key => id.toString();

  static List<CoursePdf> fromJsonList(List<dynamic> list) =>
      list.map(asMap).map(fromJson).toList();

  static CoursePdf fromJson(Map<String, dynamic> json) => CoursePdf(
        id: asDouble(json['id']).toInt(),
        filePath: asString(json['file_path']),
        fileName: asString(json['file_name']),
        category: asString(json['category']),
        teacher: asString(json['teacher']),
        time: asString(json['time']),
        course: asString(json['course']),
        createdAt: asDate(json['created_at']),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'file_path': filePath,
        'file_name': fileName,
        'category': category,
        'teacher': teacher,
        'time': time,
        'course': course,
        'created_at': createdAt?.toIso8601String(),
      };
}

class CoursePdfAdapter extends TypeAdapter<CoursePdf> {
  @override
  final int typeId = 3;

  @override
  CoursePdf read(BinaryReader reader) =>
      CoursePdf.fromJson(Map<String, dynamic>.from(reader.readMap()));

  @override
  void write(BinaryWriter writer, CoursePdf obj) =>
      writer.writeMap(obj.toJson());
}
