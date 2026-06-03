import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'editor_controller.dart';
import 'widgets/source_code_editor.dart';
import 'widgets/markdown_preview.dart';
import 'widgets/toolbar.dart';
import '../core/constants/app_constants.dart';
import '../data/providers/app_providers.dart';

class EditorScreen extends ConsumerWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorMode = ref.watch(editorModeProvider);

    // 确保 EditorController 被初始化
    ref.watch(editorControllerProvider);

    return Scaffold(
      body: Column(
        children: [
          const EditorToolbar(),
          Expanded(child: _buildEditorLayout(context, editorMode)),
          _buildStatusBar(context, ref),
        ],
      ),
    );
  }

  Widget _buildEditorLayout(BuildContext context, EditorMode mode) {
    switch (mode) {
      case EditorMode.editOnly:
        return const SourceCodeEditor();
      case EditorMode.previewOnly:
        return const MarkdownPreview();
      case EditorMode.split:
        return Row(
          children: [
            const Expanded(child: SourceCodeEditor()),
            Container(width: 1, color: Theme.of(context).dividerColor),
            const Expanded(child: MarkdownPreview()),
          ],
        );
    }
  }

  Widget _buildStatusBar(BuildContext context, WidgetRef ref) {
    final content = ref.watch(currentContentProvider);
    final lineCount = '\n'.allMatches(content).length + 1;
    final charCount = content.length;

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Text('$lineCount 行 · $charCount 字符',
              style: const TextStyle(fontSize: 11)),
          const Spacer(),
          Text('UTF-8 · Markdown', style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
