import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/markdown.dart';
import 'package:re_highlight/styles/atom-one-dark.dart';
import 'package:re_highlight/styles/atom-one-light.dart';
import '../../core/constants/app_constants.dart';
import '../../data/providers/app_providers.dart';
import '../editor_controller.dart';
import 'find_replace_bar.dart';

class SourceCodeEditor extends ConsumerStatefulWidget {
  const SourceCodeEditor({super.key});

  @override
  ConsumerState<SourceCodeEditor> createState() => _SourceCodeEditorState();
}

class _SourceCodeEditorState extends ConsumerState<SourceCodeEditor> {
  @override
  Widget build(BuildContext context) {
    final content = ref.watch(currentContentProvider);
    final controller = ref.read(editorControllerProvider);
    final cc = controller.codeController;
    final fc = controller.findController;
    final fontSize = ref.watch(editorFontSizeProvider);
    final cs = Theme.of(context).colorScheme;

    // 同步外部变更到 code controller
    if (cc.text != content) {
      final oldSelection = cc.selection;
      cc.text = content;
      // 尝试恢复选择位置
      if (oldSelection.startOffset <= content.length) {
        cc.selection = oldSelection;
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highlightTheme = CodeHighlightTheme(
      languages: {'markdown': langMarkdown.themeMode},
      theme: isDark ? atomOneDarkTheme : atomOneLightTheme,
    );

    return Container(
      color: cs.surface,
      child: Listener(
        onPointerSignal: (event) {
          if (event is PointerScrollEvent) {
            final keys = HardwareKeyboard.instance.logicalKeysPressed;
            if (keys.contains(LogicalKeyboardKey.controlLeft) ||
                keys.contains(LogicalKeyboardKey.controlRight)) {
              final delta = event.scrollDelta.dy;
              final current = ref.read(editorFontSizeProvider);
              final newSize = (current - delta / 50)
                  .clamp(AppConstants.minFontSize, AppConstants.maxFontSize);
              ref.read(editorFontSizeProvider.notifier).state = newSize;
              ref
                  .read(settingsBoxProvider)
                  .put(AppConstants.editorFontSizeKey, newSize);
            }
          }
        },
        child: CodeEditor(
          controller: cc,
          findController: fc,
          findBuilder: buildFindBar,
          style: CodeEditorStyle(
            fontSize: fontSize,
            fontFamily: 'JetBrains Mono',
            fontHeight: 1.6,
            cursorColor: cs.primary,
            cursorLineColor: cs.primaryContainer.withValues(alpha: 0.3),
            selectionColor: cs.primary.withValues(alpha: 0.2),
            backgroundColor: cs.surface,
            textColor: cs.onSurface,
            codeTheme: highlightTheme,
          ),
          onChanged: (v) =>
              ref.read(currentContentProvider.notifier).state = cc.text,
          indicatorBuilder: (ctx, editingController, chunkController, notifier) {
            return Row(
              children: [
                DefaultCodeLineNumber(
                  controller: editingController,
                  notifier: notifier,
                  textStyle: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: fontSize,
                    color: cs.onSurface.withValues(alpha: 0.35),
                  ),
                  focusedTextStyle: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: fontSize,
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            );
          },
        ),
      ),
    );
  }
}
