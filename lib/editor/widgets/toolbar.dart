import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/app_providers.dart';

class EditorToolbar extends ConsumerWidget {
  const EditorToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(editorControllerProvider);

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _Btn(Icons.undo, '撤销', controller.undo),
            _Btn(Icons.redo, '重做', controller.redo),
            _div(),
            _Btn(Icons.title, 'H1', () => controller.insertBlockPrefix('# ')),
            _Btn(null, 'H2', () => controller.insertBlockPrefix('## ')),
            _Btn(null, 'H3', () => controller.insertBlockPrefix('### ')),
            _div(),
            _Btn(Icons.format_bold, '加粗',
                () => controller.wrapSelection('**', '**')),
            _Btn(Icons.format_italic, '斜体',
                () => controller.wrapSelection('*', '*')),
            _Btn(Icons.format_strikethrough, '删除线',
                () => controller.wrapSelection('~~', '~~')),
            _div(),
            _Btn(Icons.link, '链接',
                () => controller.wrapSelection('[', '](url)')),
            _Btn(Icons.image, '图片',
                () => controller.wrapSelection('![alt](', ')')),
            _Btn(Icons.code, '代码',
                () => controller.wrapSelection('`', '`')),
            _div(),
            _Btn(Icons.format_list_bulleted, '无序列表',
                () => controller.insertBlockPrefix('- ')),
            _Btn(Icons.format_list_numbered, '有序列表',
                () => controller.insertBlockPrefix('1. ')),
            _Btn(Icons.format_quote, '引用',
                () => controller.insertBlockPrefix('> ')),
            _Btn(Icons.code, '代码块',
                () => controller.wrapSelection('```\n', '\n```')),
            _div(),
            _Btn(Icons.horizontal_rule, '分割线',
                () => controller.insertAtCursor('\n---\n')),
            _Btn(Icons.table_chart, '表格',
                () => controller.insertAtCursor(
                    '\n| 列1 | 列2 |\n| --- | --- |\n|     |     |\n')),
          ],
        ),
      ),
    );
  }

  Widget _div() => const VerticalDivider(width: 16);
}

class _Btn extends StatelessWidget {
  final IconData? icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _Btn(this.icon, this.tooltip, this.onPressed);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 32,
        height: 32,
        child: icon != null
            ? IconButton(
                icon: Icon(icon, size: 16),
                onPressed: onPressed,
                padding: EdgeInsets.zero,
                splashRadius: 16,
              )
            : TextButton(
                onPressed: onPressed,
                child: Text(tooltip, style: const TextStyle(fontSize: 12)),
              ),
      ),
    );
  }
}
