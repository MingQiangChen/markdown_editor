import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/providers/app_providers.dart';

/// 编辑器控制器 — 通过 Riverpod 提供给 Toolbar 和 SourceCodeEditor
final editorControllerProvider = Provider<EditorController>((ref) {
  return EditorController(ref: ref);
});

class EditorController {
  final Ref _ref;
  late final TextEditingController textController;

  EditorController({required Ref ref}) : _ref = ref {
    textController = TextEditingController(
        text: ref.read(currentContentProvider));
  }

  void dispose() {
    textController.dispose();
  }

  /// 在光标处插入文本
  void insertAtCursor(String text) {
    final selection = textController.selection;
    final current = textController.text;
    final start = selection.start;
    final end = selection.end;

    final newText = '${current.substring(0, start)}$text${current.substring(end)}';

    textController.text = newText;
    textController.selection = TextSelection.collapsed(
      offset: start + text.length,
    );
    _ref.read(currentContentProvider.notifier).state = newText;
  }

  /// 包裹选中文本 (加粗、斜体等)
  void wrapSelection(String prefix, String suffix) {
    final selection = textController.selection;
    final current = textController.text;
    final start = selection.start;
    final end = selection.end;
    final selectedText =
        selection.isCollapsed ? '' : current.substring(start, end);

    final newText = current.substring(0, start) +
        '$prefix$selectedText$suffix' +
        current.substring(end);

    textController.text = newText;
    final newOffset = selection.isCollapsed
        ? start + prefix.length
        : start + prefix.length + selectedText.length + suffix.length;
    textController.selection = TextSelection.collapsed(offset: newOffset);
    _ref.read(currentContentProvider.notifier).state = newText;
  }

  /// 在当前行首插入块级前缀 (标题、引用、列表等)
  void insertBlockPrefix(String prefix) {
    final selection = textController.selection;
    final current = textController.text;
    final lineStart = _findLineStart(current, selection.start);

    final newText = current.substring(0, lineStart) +
        prefix +
        current.substring(lineStart);

    textController.text = newText;
    textController.selection = TextSelection.collapsed(
      offset: lineStart + prefix.length,
    );
    _ref.read(currentContentProvider.notifier).state = newText;
  }

  /// 撤销 (占位 — 后续接入 undo stack)
  void undo() {
    // TODO: 实现基于 ChangeRecord 的撤销栈
  }

  /// 重做
  void redo() {
    // TODO: 实现重做
  }

  int _findLineStart(String text, int position) {
    if (position <= 0) return 0;
    final before = text.substring(0, position);
    final lastNewline = before.lastIndexOf('\n');
    return lastNewline == -1 ? 0 : lastNewline + 1;
  }
}
