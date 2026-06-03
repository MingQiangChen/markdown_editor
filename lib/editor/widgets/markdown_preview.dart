import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/app_providers.dart';

class MarkdownPreview extends ConsumerWidget {
  const MarkdownPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(currentContentProvider);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final surfaceHigh = Theme.of(context).colorScheme.surfaceContainerHighest;

    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: content.isEmpty
          ? Center(
              child: Text(
                '预览区域',
                style: TextStyle(
                  color: onSurface.withValues(alpha: 0.3),
                  fontSize: 16,
                ),
              ),
            )
          : Markdown(
              data: content,
              selectable: true,
              padding: EdgeInsets.zero,
              styleSheet: MarkdownStyleSheet.fromTheme(
                Theme.of(context),
              ).copyWith(
                h1: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: onSurface,
                ),
                h2: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: onSurface,
                ),
                h3: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: onSurface,
                ),
                code: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 13,
                  backgroundColor: surfaceHigh,
                ),
                codeblockDecoration: BoxDecoration(
                  color: surfaceHigh,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
    );
  }
}
