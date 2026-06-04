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
import 'find_replace_bar.dart';

class SourceCodeEditor extends ConsumerStatefulWidget {
  const SourceCodeEditor({super.key});

  @override
  ConsumerState<SourceCodeEditor> createState() => _SourceCodeEditorState();
}

class _SourceCodeEditorState extends ConsumerState<SourceCodeEditor> {
  final _focusNode = FocusNode(debugLabel: 'SourceCodeEditor');

  @override
  void initState() {
    super.initState();
    // re_editor's autofocus (FocusScope.autofocus) properly triggers
    // consumeKeyboardToken → opens TextInputConnection.
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(editorControllerProvider);
    final cc = controller.codeController;
    final fc = controller.findController;
    final fontSize = ref.watch(editorFontSizeProvider);
    final cs = Theme.of(context).colorScheme;

    // When content changes externally (doc opened), ensure focus + input
    ref.listen(currentContentProvider, (prev, next) {
      if (prev != next && mounted && !_focusNode.hasFocus) {
        // Delay to let the widget tree settle after text update
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && !_focusNode.hasFocus) {
            _focusNode.requestFocus();
          }
        });
      }
    });

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
          focusNode: _focusNode,
          autofocus: true,
          controller: cc,
          findController: fc,
          findBuilder: buildFindBar,
          style: CodeEditorStyle(
            fontSize: fontSize,
            fontFamily: 'JetBrains Mono',
            fontFamilyFallback: const [
              'Noto Sans CJK SC',
              'WenQuanYi Micro Hei',
              'Noto Sans',
            ],
            fontHeight: 1.6,
            cursorColor: cs.primary,
            cursorLineColor: cs.primaryContainer.withValues(alpha: 0.3),
            selectionColor: cs.primary.withValues(alpha: 0.2),
            backgroundColor: cs.surface,
            textColor: cs.onSurface,
            codeTheme: highlightTheme,
          ),
          onChanged: (_) =>
              ref.read(currentContentProvider.notifier).state = cc.text,
          indicatorBuilder:
              (ctx, editingController, chunkController, notifier) {
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
