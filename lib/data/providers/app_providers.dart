import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:re_editor/re_editor.dart';
import '../../core/constants/app_constants.dart';
import '../../editor/editor_controller.dart';
import '../models/document.dart';

/// Box provider - 文档存储
final documentBoxProvider = Provider<Box<Document>>((ref) {
  throw UnimplementedError('Must be overridden in main()');
});

/// Box provider - 设置存储
final settingsBoxProvider = Provider<Box>((ref) {
  throw UnimplementedError('Must be overridden in main()');
});

/// Box provider - 版本历史存储 (key: docId_timestamp, value: content)
final versionBoxProvider = Provider<Box<String>>((ref) {
  throw UnimplementedError('Must be overridden in main()');
});

// ─── 编辑器状态 ───────────────────────────────────────────

/// 默认编辑模式
final editorModeProvider = StateProvider<EditorMode>((ref) => EditorMode.split);

/// 是否显示预览
final showPreviewProvider = StateProvider<bool>((ref) => true);

/// 编辑器字体大小
final editorFontSizeProvider = StateProvider<double>(
  (ref) => AppConstants.defaultFontSize,
);

/// 自动保存 (秒，0=关闭)
final autoSaveProvider = StateProvider<int>((ref) => 0);

// ─── 主题 ─────────────────────────────────────────────────

/// 主题模式
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

// ─── 当前文档 ─────────────────────────────────────────────

final currentDocumentIdProvider = StateProvider<String?>((ref) => null);
final currentContentProvider = StateProvider<String>((ref) => '');
final currentTitleProvider = StateProvider<String>((ref) => '未命名文档');
final currentFilePathProvider = StateProvider<String?>((ref) => null);

/// 编辑器控制器 — 长生命周期，通过双向同步切换文档
final editorControllerProvider = Provider<EditorController>((ref) {
  final controller =
      EditorController(initialContent: ref.read(currentContentProvider));

  // Guard to prevent syncToProvider from firing during external updates
  bool suppressSync = false;

  // 控制器 → Provider（用户输入、工具栏操作）
  void syncToProvider() {
    if (suppressSync) return;
    final text = controller.codeController.text;
    final current = ref.read(currentContentProvider);
    if (text != current) {
      ref.read(currentContentProvider.notifier).state = text;
    }
  }

  controller.codeController.addListener(syncToProvider);

  // Provider → 控制器（文档切换、版本恢复等外部修改）
  ref.listen(currentContentProvider, (prev, next) {
    final currentText = controller.codeController.text;
    if (currentText != next) {
      suppressSync = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Re-check after frame boundary — content may have changed again
        if (controller.codeController.text != next) {
          controller.codeController.text = next;
          controller.codeController.selection =
              const CodeLineSelection.zero();
        }
        suppressSync = false;
      });
    }
  });

  ref.onDispose(() {
    controller.codeController.removeListener(syncToProvider);
    controller.dispose();
  });
  return controller;
});

// ─── 设置持久化 ───────────────────────────────────────────

/// 从 Hive 加载所有持久化设置
void loadSettings(WidgetRef ref) {
  final box = ref.read(settingsBoxProvider);

  final themeModeIdx = box.get(AppConstants.themeModeKey);
  if (themeModeIdx != null) {
    ref.read(themeModeProvider.notifier).state = ThemeMode.values[themeModeIdx as int];
  }

  final editorModeIdx = box.get('editor_mode');
  if (editorModeIdx != null) {
    ref.read(editorModeProvider.notifier).state = EditorMode.values[editorModeIdx as int];
  }

  final showPreview = box.get(AppConstants.showPreviewKey);
  if (showPreview != null) {
    ref.read(showPreviewProvider.notifier).state = showPreview as bool;
  }

  final fontSize = box.get(AppConstants.editorFontSizeKey);
  if (fontSize != null) {
    ref.read(editorFontSizeProvider.notifier).state = fontSize as double;
  }

  final autoSave = box.get('auto_save');
  if (autoSave != null) {
    ref.read(autoSaveProvider.notifier).state = autoSave as int;
  }
}
