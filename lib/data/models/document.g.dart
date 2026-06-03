// GENERATED CODE - DO NOT MODIFY BY HAND
// 运行 `flutter pub run build_runner build` 重新生成

part of 'document.dart';

class DocumentAdapter extends TypeAdapter<Document> {
  @override
  final int typeId = 0;

  @override
  Document read(BinaryReader reader) {
    final fields = reader.readMap().cast<int, dynamic>();
    return Document(
      id: fields[0] as String,
      title: fields[1] as String,
      content: fields[2] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(fields[3] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(fields[4] as int),
      parentId: fields[5] as String?,
      tags: (fields[6] as List?)?.cast<String>() ?? [],
      isFolder: fields[7] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, Document obj) {
    writer.writeMap({
      0: obj.id,
      1: obj.title,
      2: obj.content,
      3: obj.createdAt.millisecondsSinceEpoch,
      4: obj.updatedAt.millisecondsSinceEpoch,
      5: obj.parentId,
      6: obj.tags,
      7: obj.isFolder,
    });
  }
}
