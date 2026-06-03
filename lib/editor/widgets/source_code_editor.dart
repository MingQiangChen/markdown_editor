import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/app_providers.dart';
import '../editor_controller.dart';

class SourceCodeEditor extends ConsumerStatefulWidget {
  const SourceCodeEditor({super.key});

  @override
  ConsumerState<SourceCodeEditor> createState() => _SourceCodeEditorState();
}

class _SourceCodeEditorState extends ConsumerState<SourceCodeEditor> {
  @override
  Widget build(BuildContext context) {
    final content = ref.watch(currentContentProvider);
    final controller = ref.watch(editorControllerProvider);
    final tc = controller.textController;

    // 同步外部变更到 text controller
    if (tc.text != content) {
      final oldSelection = tc.selection;
      tc.text = content;
      if (oldSelection.baseOffset <= content.length) {
        tc.selection = oldSelection;
      }
    }

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 8, top: 8, bottom: 8),
        child: TextField(
          controller: tc,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          keyboardType: TextInputType.multiline,
          onChanged: (value) =>
              ref.read(currentContentProvider.notifier).state = value,
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 14,
            height: 1.6,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isCollapsed: true,
          ),
        ),
      ),
    );
  }
}
