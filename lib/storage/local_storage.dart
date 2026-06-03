import 'package:hive_flutter/hive_flutter.dart';
import '../data/models/document.dart';
import '../core/utils/file_io_stub.dart'
    if (dart.library.io) '../core/utils/file_io_native.dart';

class LocalStorage {
  late final Box<Document> _docBox;
  late final Box _settingsBox;

  LocalStorage({
    required Box<Document> docBox,
    required Box settingsBox,
  })  : _docBox = docBox,
        _settingsBox = settingsBox;

  Future<void> saveDocument(Document doc) async {
    await _docBox.put(doc.id, doc);
  }

  Document? getDocument(String id) {
    return _docBox.get(id);
  }

  List<Document> getAllDocuments() {
    return _docBox.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  List<Document> getRecentDocuments({int limit = 10}) {
    final docs = getAllDocuments();
    return docs.take(limit).toList();
  }

  Future<void> deleteDocument(String id) async {
    await _docBox.delete(id);
  }

  int get documentCount => _docBox.length;

  static void writeToFile(String path, String content) {
    writeStringToFile(path, content);
  }

  void setSetting(String key, dynamic value) {
    _settingsBox.put(key, value);
  }

  dynamic getSetting(String key, {dynamic defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue);
  }
}
