import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:re_editor/re_editor.dart';
import '../data/providers/app_providers.dart';

final editorControllerProvider = Provider<EditorController>((ref) {
  return EditorController(ref: ref);
});

class EditorController {
  final Ref _ref;
  late final CodeLineEditingController codeController;
  late final CodeFindController findController;

  EditorController({required Ref ref}) : _ref = ref {
    codeController =
        CodeLineEditingController.fromText(ref.read(currentContentProvider));
    findController = CodeFindController(codeController);
  }

  void dispose() {
    findController.dispose();
    codeController.dispose();
  }

  /// 将平铺字符索引转换为 (行索引, 行内偏移)
  CodeLinePosition _flatIndexToPosition(int flatIndex) {
    var offset = 0;
    for (var i = 0; i < codeController.codeLines.length; i++) {
      final lineLen = codeController.codeLines[i].length;
      if (offset + lineLen > flatIndex) {
        return CodeLinePosition(index: i, offset: flatIndex - offset);
      }
      offset += lineLen;
    }
    final last = codeController.codeLines.last;
    return CodeLinePosition(
        index: codeController.codeLines.length - 1, offset: last.length);
  }

  void insertAtCursor(String text) {
    final sel = codeController.selection;
    final start = sel.startOffset;
    if (!sel.isCollapsed) {
      codeController.replaceSelection(text);
    } else {
      final current = codeController.text;
      final newText =
          '${current.substring(0, start)}$text${current.substring(start)}';
      codeController.text = newText;
      codeController.selection = CodeLineSelection.fromPosition(
          position: _flatIndexToPosition(start + text.length));
    }
    _syncProvider();
  }

  void wrapSelection(String prefix, String suffix) {
    final sel = codeController.selection;
    final current = codeController.text;
    final start = sel.startOffset;
    final end = sel.endOffset;
    final selectedText = sel.isCollapsed ? '' : current.substring(start, end);

    final newText =
        '${current.substring(0, start)}$prefix$selectedText$suffix${current.substring(end)}';

    codeController.text = newText;
    final newOffset = sel.isCollapsed
        ? start + prefix.length
        : start + prefix.length + selectedText.length + suffix.length;
    codeController.selection = CodeLineSelection.fromPosition(
        position: _flatIndexToPosition(newOffset));
    _syncProvider();
  }

  void insertBlockPrefix(String prefix) {
    final sel = codeController.selection;
    final current = codeController.text;
    final lineStart = _findLineStart(current, sel.startOffset);

    final newText =
        '${current.substring(0, lineStart)}$prefix${current.substring(lineStart)}';

    codeController.text = newText;
    codeController.selection = CodeLineSelection.fromPosition(
        position: _flatIndexToPosition(lineStart + prefix.length));
    _syncProvider();
  }

  void undo() => codeController.undo();
  void redo() => codeController.redo();

  void _syncProvider() {
    _ref.read(currentContentProvider.notifier).state = codeController.text;
  }

  int _findLineStart(String text, int position) {
    if (position <= 0) return 0;
    final before = text.substring(0, position);
    final lastNewline = before.lastIndexOf('\n');
    return lastNewline == -1 ? 0 : lastNewline + 1;
  }
}
