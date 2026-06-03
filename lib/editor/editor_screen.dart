import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:re_editor/re_editor.dart';
import '../core/utils/file_io_stub.dart'
    if (dart.library.io) '../core/utils/file_io_native.dart';
import 'editor_controller.dart';
import 'widgets/source_code_editor.dart';
import 'widgets/markdown_preview.dart';
import 'widgets/toolbar.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/download_stub.dart'
    if (dart.library.html) '../core/utils/download_web.dart';
import 'package:printing/printing.dart';
import '../core/utils/export_utils.dart';
import '../data/providers/app_providers.dart';

// ─── 快捷键 Intents ─────────────────────────────────────────

class _SaveIntent extends Intent {}
class _UndoIntent extends Intent {}
class _RedoIntent extends Intent {}
class _BoldIntent extends Intent {}
class _ItalicIntent extends Intent {}
class _LinkIntent extends Intent {}

// ─── EditorScreen ───────────────────────────────────────────

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  bool _canPop = false;
  Timer? _autoSaveTimer;
  bool _isDirty = false;
  bool _mobileShowPreview = false;

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  void _setupAutoSaveTimer(int seconds) {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
    if (seconds > 0) {
      _autoSaveTimer = Timer.periodic(Duration(seconds: seconds), (_) {
        if (_isDirty) {
          _saveDocument();
          _isDirty = false;
        }
      });
    }
  }

  void _handlePop() {
    if (!_canPop) {
      _saveDocument();
      setState(() => _canPop = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final editorMode = ref.watch(editorModeProvider);
    final docTitle = ref.watch(currentTitleProvider);
    final controller = ref.watch(editorControllerProvider);

    // 监听自动保存设置变化
    ref.listen(autoSaveProvider, (_, next) => _setupAutoSaveTimer(next));

    // 追踪未保存修改
    ref.listen(currentContentProvider, (prev, next) {
      if (prev != next) _isDirty = true;
    });

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS):
            _SaveIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ):
            _UndoIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyY):
            _RedoIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyB):
            _BoldIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyI):
            _ItalicIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyK):
            _LinkIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _SaveIntent: CallbackAction<_SaveIntent>(
              onInvoke: (_) => _saveDocument()),
          _UndoIntent:
              CallbackAction<_UndoIntent>(onInvoke: (_) => controller.undo()),
          _RedoIntent:
              CallbackAction<_RedoIntent>(onInvoke: (_) => controller.redo()),
          _BoldIntent: CallbackAction<_BoldIntent>(
              onInvoke: (_) => controller.wrapSelection('**', '**')),
          _ItalicIntent: CallbackAction<_ItalicIntent>(
              onInvoke: (_) => controller.wrapSelection('*', '*')),
          _LinkIntent: CallbackAction<_LinkIntent>(
              onInvoke: (_) => controller.wrapSelection('[', '](url)')),
        },
        child: PopScope(
          canPop: _canPop,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _handlePop();
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(docTitle),
              actions: [
                IconButton(
                  icon: const Icon(Icons.history),
                  tooltip: '版本历史',
                  onPressed: () => _showVersionHistory(context),
                ),
                IconButton(
                  icon: const Icon(Icons.ios_share),
                  tooltip: '导出 HTML',
                  onPressed: () => _showExportSheet(context),
                ),
                IconButton(
                  icon: const Icon(Icons.save),
                  tooltip: '保存 (Ctrl+S)',
                  onPressed: _saveDocument,
                ),
              ],
            ),
            body: Builder(builder: (context) {
              final width = MediaQuery.of(context).size.width;
              final compact = width < AppConstants.compactWidthBreakpoint;
              final effectiveMode = compact && editorMode == EditorMode.split
                  ? EditorMode.editOnly
                  : editorMode;
              return Column(
                children: [
                  const EditorToolbar(),
                  Expanded(
                      child: _buildEditorLayout(context, effectiveMode)),
                  if (compact) _buildMobileToggle(context),
                  _buildStatusBar(context),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  void _saveDocument() {
    final docId = ref.read(currentDocumentIdProvider);
    if (docId == null) return;
    final content = ref.read(currentContentProvider);
    final title = ref.read(currentTitleProvider);
    final box = ref.read(documentBoxProvider);
    final doc = box.get(docId);
    if (doc != null) {
      _createVersion(docId, doc.content);
      doc.update(content);
      doc.rename(title);
      box.put(docId, doc);
      _isDirty = false;
      // 如果从本地文件打开，同时写回文件
      final filePath = ref.read(currentFilePathProvider);
      if (filePath != null) {
        try {
          writeStringToFile(filePath, content);
        } catch (_) {
          // 文件写入失败不阻断 Hive 保存
        }
      }
    }
  }

  void _createVersion(String docId, String content) {
    final vBox = ref.read(versionBoxProvider);
    final key = '${docId}_${DateTime.now().millisecondsSinceEpoch}';
    vBox.put(key, content);
    // 每个文档最多保留 50 个版本
    final keys = vBox.keys
        .where((k) => k.startsWith('${docId}_'))
        .toList()
      ..sort();
    while (keys.length > 50) {
      vBox.delete(keys.first);
      keys.removeAt(0);
    }
  }

  void _showExportSheet(BuildContext context) {
    final content = ref.read(currentContentProvider);
    final title = ref.read(currentTitleProvider);
    final html = ExportUtils.markdownToHtmlDocument(content, title);

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('导出 HTML',
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 120,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    html,
                    style: const TextStyle(fontSize: 11, fontFamily: 'JetBrains Mono'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: html));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('HTML 已复制到剪贴板')),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('复制 HTML'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        downloadFile(html, '$title.html', 'text/html');
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('正在下载 HTML 文件...')),
                        );
                      },
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('下载文件'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Printing.layoutPdf(
                      onLayout: (format) =>
                          Printing.convertHtml(format: format, html: html),
                      name: title,
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label: const Text('导出 PDF'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showVersionHistory(BuildContext context) {
    final docId = ref.read(currentDocumentIdProvider);
    if (docId == null) return;
    final vBox = ref.read(versionBoxProvider);
    final keys = vBox.keys
        .where((k) => k.startsWith('${docId}_'))
        .toList()
      ..sort((a, b) => b.compareTo(a)); // 最新的在前

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (ctx, scrollCtrl) {
            if (keys.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history,
                        size: 48,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.2)),
                    const SizedBox(height: 12),
                    Text('暂无版本历史',
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5))),
                    const SizedBox(height: 4),
                    Text('手动保存 (Ctrl+S) 后自动创建版本',
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.3))),
                  ],
                ),
              );
            }
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.history),
                      const SizedBox(width: 8),
                      Text('版本历史',
                          style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      Text('${keys.length} 个版本',
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5))),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: scrollCtrl,
                    itemCount: keys.length,
                    itemBuilder: (_, index) {
                      final key = keys[index];
                      final content = vBox.get(key) ?? '';
                      final ts = int.parse(
                          key.substring(key.lastIndexOf('_') + 1));
                      final dt = DateTime.fromMillisecondsSinceEpoch(ts);
                      final preview = content.length > 80
                          ? '${content.substring(0, 80)}...'
                          : content;
                      return ListTile(
                        leading: const Icon(Icons.description_outlined),
                        title: Text(_formatVersionTime(dt),
                            style: const TextStyle(fontSize: 14)),
                        subtitle: Text(preview,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12)),
                        onTap: () {
                          Navigator.pop(ctx);
                          _previewVersion(context, content, dt);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _previewVersion(
      BuildContext context, String content, DateTime dt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.3,
          expand: false,
          builder: (ctx, scrollCtrl) => Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text('版本预览 — ${_formatVersionTime(dt)}',
                        style:
                            Theme.of(context).textTheme.titleSmall),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _restoreVersion(context, content);
                      },
                      icon: const Icon(Icons.restore, size: 16),
                      label: const Text('恢复'),
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    content,
                    style: const TextStyle(
                        fontFamily: 'JetBrains Mono', fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _restoreVersion(BuildContext context, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('恢复版本'),
        content: const Text('当前编辑内容将被替换为所选版本。确定恢复吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              final cc = ref.read(editorControllerProvider).codeController;
              cc.text = content;
              cc.selection = const CodeLineSelection.zero();
              ref.read(currentContentProvider.notifier).state = content;
              setState(() => _isDirty = true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已恢复到所选版本')),
              );
            },
            child: const Text('恢复'),
          ),
        ],
      ),
    );
  }

  String _formatVersionTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  Widget _buildMobileToggle(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _mobileShowPreview = false),
              child: Container(
                alignment: Alignment.center,
                color: _mobileShowPreview
                    ? Colors.transparent
                    : cs.primaryContainer.withValues(alpha: 0.4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit, size: 14,
                        color: _mobileShowPreview ? cs.onSurface : cs.primary),
                    const SizedBox(width: 4),
                    Text('编辑',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _mobileShowPreview
                              ? FontWeight.normal
                              : FontWeight.bold,
                          color: _mobileShowPreview ? cs.onSurface : cs.primary,
                        )),
                  ],
                ),
              ),
            ),
          ),
          Container(width: 1, color: Theme.of(context).dividerColor),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _mobileShowPreview = true),
              child: Container(
                alignment: Alignment.center,
                color: _mobileShowPreview
                    ? cs.primaryContainer.withValues(alpha: 0.4)
                    : Colors.transparent,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.visibility, size: 14,
                        color: _mobileShowPreview ? cs.primary : cs.onSurface),
                    const SizedBox(width: 4),
                    Text('预览',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _mobileShowPreview
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _mobileShowPreview ? cs.primary : cs.onSurface,
                        )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorLayout(BuildContext context, EditorMode mode) {
    final width = MediaQuery.of(context).size.width;
    final compact = width < AppConstants.compactWidthBreakpoint;
    if (compact) {
      return _mobileShowPreview
          ? const MarkdownPreview()
          : const SourceCodeEditor();
    }
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

  Widget _buildStatusBar(BuildContext context) {
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
          if (_isDirty)
            const Text(' · 未保存',
                style: TextStyle(fontSize: 11, color: Colors.orange)),
          const Spacer(),
          const Text('UTF-8 · Markdown', style: TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
