import 'package:hive/hive.dart';

import 'models.dart';

class NewCourse {
  NewCourse({
    required this.id,
    required this.imagePath,
    required this.title,
    required this.description,
    required this.startAt,
    required this.category,
    required this.createdAt,
  });

  final int id;
  final String imagePath;
  final String title;
  final String description;
  final DateTime? startAt;
  final String category;
  final DateTime? createdAt;

  String get key => id.toString();

  static List<NewCourse> fromJsonList(List<dynamic> list) =>
      list.map(asMap).map(fromJson).toList();

  static NewCourse fromJson(Map<String, dynamic> json) => NewCourse(
        id: asDouble(json['id']).toInt(),
        imagePath: asString(json['image_path']),
        title: asString(json['title']),
        description: asString(json['description']),
        startAt: asDate(json['start_at']),
        category: asString(json['category']),
        createdAt: asDate(json['created_at']),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'image_path': imagePath,
        'title': title,
        'description': description,
        'start_at': startAt?.toIso8601String(),
        'category': category,
        'created_at': createdAt?.toIso8601String(),
      };
}

class NewCourseAdapter extends TypeAdapter<NewCourse> {
  @override
  final int typeId = 2;

  @override
  NewCourse read(BinaryReader reader) =>
      NewCourse.fromJson(Map<String, dynamic>.from(reader.readMap()));

  @override
  void write(BinaryWriter writer, NewCourse obj) =>
      writer.writeMap(obj.toJson());
}
