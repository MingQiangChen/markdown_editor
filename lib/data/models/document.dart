import 'package:hive/hive.dart';

part 'document.g.dart';

@HiveType(typeId: 0)
class Document extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String content;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  DateTime updatedAt;

  @HiveField(5)
  String? parentId;

  @HiveField(6)
  List<String> tags;

  @HiveField(7)
  bool isFolder;

  Document({
    required this.id,
    required this.title,
    this.content = '',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.parentId,
    List<String>? tags,
    this.isFolder = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        tags = tags ?? [];

  void update(String newContent) {
    content = newContent;
    updatedAt = DateTime.now();
  }

  void rename(String newTitle) {
    title = newTitle;
    updatedAt = DateTime.now();
  }
}
