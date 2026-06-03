import 'package:hive_flutter/hive_flutter.dart';
import '../data/models/document.dart';
import 'dart:convert';

class LocalStorage {
  late final Box<Document> _docBox;
  late final Box _settingsBox;

  LocalStorage({
    required Box<Document> docBox,
    required Box settingsBox,
  })  : _docBox = docBox,
        _settingsBox = settingsBox;

  // ─── 文档操作 ──────────────────────────────────────────

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

  // ─── 文件操作 ──────────────────────────────────────────

  /// 从文件系统读取 .md 文件内容
  static Future<String> readFromFile(String path) async {
    final file = await _openFile(path);
    return file.readAsString();
  }

  /// 将文档写入文件系统
  static Future<void> writeToFile(String path, String content) async {
    final file = await _openFile(path);
    await file.writeAsString(content, encoding: utf8);
  }

  // ─── 设置操作 ──────────────────────────────────────────

  void setSetting(String key, dynamic value) {
    _settingsBox.put(key, value);
  }

  dynamic getSetting(String key, {dynamic defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue);
  }
}

/// Stub — 导入 dart:io 的 file 操作需要 Flutter 环境
/// 此处的 _openFile 在编译时由 path_provider 提供
Future<dynamic> _openFile(String path) async {
  throw UnimplementedError('Replace with dart:io File when running in Flutter');
}
