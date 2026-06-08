import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_mermaid/flutter_mermaid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:re_highlight/re_highlight.dart';
import 'package:re_highlight/languages/all.dart';
import 'package:re_highlight/styles/atom-one-dark.dart';
import 'package:re_highlight/styles/atom-one-light.dart';
import '../../data/providers/app_providers.dart';

final _highlighter = Highlight();
var _highlighterReady = false;

void _ensureHighlighter() {
  if (_highlighterReady) return;
  _highlighter.registerLanguages(builtinAllLanguages);
  _highlighterReady = true;
}

class MarkdownPreview extends ConsumerWidget {
  const MarkdownPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _ensureHighlighter();
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
          : InteractiveViewer(
              minScale: 0.5,
              maxScale: 3.0,
              child: Markdown(
                data: content,
                selectable: true,
                padding: EdgeInsets.zero,
                inlineSyntaxes: [InlineMathSyntax()],
                builders: {
                  'code': _CodeBlockBuilder(context),
                  'math-inline': _InlineMathBuilder(context),
                },
                checkboxBuilder: (checked) => Icon(
                  checked ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 18,
                  color: checked
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
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
            ),
    );
  }
}

class InlineMathSyntax extends md.InlineSyntax {
  InlineMathSyntax() : super(r'\$(.+?)\$', startCharacter: 0x24);

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final expression = match[1]!;
    parser.addNode(md.Element('math-inline', [md.Text(expression)]));
    return true;
  }
}

class _InlineMathBuilder extends MarkdownElementBuilder {
  final BuildContext context;

  _InlineMathBuilder(this.context);

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final expression = element.textContent.trim();
    if (expression.isEmpty) return null;

    final onSurface = Theme.of(context).colorScheme.onSurface;
    try {
      return Math.tex(
        expression,
        mathStyle: MathStyle.text,
        textStyle: TextStyle(
          color: onSurface,
          fontSize: (preferredStyle?.fontSize ?? 14) * 1.05,
        ),
      );
    } catch (_) {
      return Text('\$$expression\$', style: preferredStyle);
    }
  }
}

class _CodeBlockBuilder extends MarkdownElementBuilder {
  final BuildContext context;

  _CodeBlockBuilder(this.context);

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final language = element.attributes['class'] ?? '';
    final code = element.textContent.trim();
    if (code.isEmpty) return null;

    if (language == 'math' || language == 'latex') {
      return _buildMathBlock(code);
    }
    if (language == 'mermaid') {
      return _buildMermaidBlock(code);
    }

    return _buildHighlightedBlock(code, language);
  }

  Widget _buildHighlightedBlock(String code, String language) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final theme = isDark ? atomOneDarkTheme : atomOneLightTheme;

    final langName = language.isEmpty ? null : language;

    TextSpan span;
    if (langName != null && _highlighter.getLanguage(langName) != null) {
      try {
        final result = _highlighter.highlight(code: code, language: langName);
        final renderer = TextSpanRenderer(null, theme);
        result.render(renderer);
        span = renderer.span ?? TextSpan(text: code);
      } catch (_) {
        span = TextSpan(text: code);
      }
    } else {
      span = TextSpan(text: code);
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xff282c34)
            : const Color(0xfff5f5f5),
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (langName != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.08),
              ),
              child: Text(
                langName,
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11,
                  color: cs.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 13,
                  height: 1.6,
                  color: isDark
                      ? const Color(0xffabb2bf)
                      : const Color(0xff383a42),
                ),
                children: span.children ?? [span],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMathBlock(String code) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    try {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Math.tex(
            code,
            mathStyle: MathStyle.display,
            textStyle: TextStyle(
              color: onSurface,
              fontSize: 16,
            ),
          ),
        ),
      );
    } catch (_) {
      return _buildErrorBlock('LaTeX 渲染失败，请检查公式语法');
    }
  }

  Widget _buildMermaidBlock(String code) {
    try {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: MermaidDiagram(code: code),
      );
    } catch (_) {
      return _buildErrorBlock('Mermaid 渲染失败，请检查图表语法');
    }
  }

  Widget _buildErrorBlock(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red.withValues(alpha: 0.8),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
