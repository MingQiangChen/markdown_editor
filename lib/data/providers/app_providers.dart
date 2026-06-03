import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../models/document.dart';

/// Box provider - 文档存储
final documentBoxProvider = Provider<Box<Document>>((ref) {
  throw UnimplementedError('Must be overridden in main()');
});

/// Box provider - 设置存储
final settingsBoxProvider = Provider<Box>((ref) {
  throw UnimplementedError('Must be overridden in main()');
});

// ─── 编辑器状态 ───────────────────────────────────────────

/// 当前编辑器模式
final editorModeProvider = StateProvider<EditorMode>(
  (ref) => EditorMode.split,
);

/// 是否显示预览
final showPreviewProvider = StateProvider<bool>((ref) => true);

// ─── 主题 ─────────────────────────────────────────────────

/// 主题模式 (亮色/暗色/跟随系统)
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

// ─── 当前文档 ─────────────────────────────────────────────

/// 当前打开的文档 ID
final currentDocumentIdProvider = StateProvider<String?>((ref) => null);

/// 当前文档内容 (编辑器中的文本)
final currentContentProvider = StateProvider<String>((ref) => '');

/// 文档标题
final currentTitleProvider = StateProvider<String>((ref) => '未命名文档');
