import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/document.dart';
import '../../data/providers/app_providers.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docs = ref.watch(documentListProvider);
    final currentId = ref.watch(currentDocumentIdProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '搜索文件',
            onPressed: () => _showSearch(context, ref),
          ),
          IconButton(
            icon: Icon(
              themeMode == ThemeMode.dark
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            tooltip: '切换主题',
            onPressed: () {
              final newMode = themeMode == ThemeMode.dark
                  ? ThemeMode.light
                  : ThemeMode.dark;
              ref.read(themeModeProvider.notifier).state = newMode;
              ref
                  .read(settingsBoxProvider)
                  .put(AppConstants.themeModeKey, newMode.index);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '设置',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: docs.isEmpty
          ? _buildEmptyState(context)
          : _buildFileList(context, ref, docs, currentId),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createDocument(ref, context),
        tooltip: '新建文档',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final surface = Theme.of(context).colorScheme.onSurface;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article_outlined,
              size: 64, color: surface.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text('还没有文档',
              style: TextStyle(
                  color: surface.withValues(alpha: 0.5), fontSize: 16)),
          const SizedBox(height: 8),
          Text('点击右下角 + 创建第一篇文档',
              style: TextStyle(
                  color: surface.withValues(alpha: 0.3), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildFileList(BuildContext context, WidgetRef ref,
      List<Document> docs, String? currentId) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: docs.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
      itemBuilder: (context, index) {
        final doc = docs[index];
        final isActive = doc.id == currentId;
        return ListTile(
          selected: isActive,
          leading: Icon(
            isActive ? Icons.article : Icons.article_outlined,
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.4),
          ),
          title: Text(
            doc.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Text(
            _formatDate(doc.updatedAt),
            style: const TextStyle(fontSize: 12),
          ),
          onTap: () => _openDocument(ref, context, doc),
          onLongPress: () => _showContextMenu(context, ref, doc),
        );
      },
    );
  }

  void _createDocument(WidgetRef ref, BuildContext context) async {
    final doc = Document(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '未命名文档',
    );
    final box = ref.read(documentBoxProvider);
    await box.put(doc.id, doc);
    ref.read(currentDocumentIdProvider.notifier).state = doc.id;
    ref.read(currentContentProvider.notifier).state = '';
    ref.read(currentTitleProvider.notifier).state = doc.title;
    if (context.mounted) {
      Navigator.pushNamed(context, '/editor');
    }
  }

  void _openDocument(WidgetRef ref, BuildContext context, Document doc) {
    ref.read(currentDocumentIdProvider.notifier).state = doc.id;
    ref.read(currentContentProvider.notifier).state = doc.content;
    ref.read(currentTitleProvider.notifier).state = doc.title;
    Navigator.pushNamed(context, '/editor');
  }

  void _showContextMenu(
      BuildContext context, WidgetRef ref, Document doc) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('重命名'),
              onTap: () {
                Navigator.pop(ctx);
                _renameDialog(context, ref, doc);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('删除',
                  style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(ctx);
                final box = ref.read(documentBoxProvider);
                await box.delete(doc.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _renameDialog(
      BuildContext context, WidgetRef ref, Document doc) {
    final controller = TextEditingController(text: doc.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重命名'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '输入新名称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                doc.rename(newTitle);
                final box = ref.read(documentBoxProvider);
                await box.put(doc.id, doc);
                if (context.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showSearch(BuildContext context, WidgetRef ref) {
    final docs = ref.read(documentListProvider);
    showSearch(
      context: context,
      delegate: _DocumentSearch(docs: docs, ref: ref),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

/// 文档列表 Provider
final documentListProvider = Provider<List<Document>>((ref) {
  final box = ref.watch(documentBoxProvider);
  final docs = box.values.toList()
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return docs;
});

// ─── 搜索代理 ─────────────────────────────────────────────

class _DocumentSearch extends SearchDelegate<String> {
  final List<Document> docs;
  final WidgetRef ref;

  _DocumentSearch({required this.docs, required this.ref});

  @override
  String get searchFieldLabel => '搜索文档标题或内容...';

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: '清除',
            onPressed: () => query = '',
          ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, ''),
      );

  @override
  Widget buildResults(BuildContext context) =>
      _buildSearchResults(context);

  @override
  Widget buildSuggestions(BuildContext context) =>
      _buildSearchResults(context);

  Widget _buildSearchResults(BuildContext context) {
    if (query.isEmpty) {
      return _buildSearchPrompt(context);
    }

    final results = _search(query.toLowerCase());

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off,
                size: 48,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text('未找到 "$query" 相关文档',
                style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5))),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: results.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
      itemBuilder: (context, index) {
        final (doc, matchSnippet) = results[index];
        return ListTile(
          leading: const Icon(Icons.article_outlined),
          title: _highlightMatch(doc.title, query, context),
          subtitle: matchSnippet != null
              ? Text(matchSnippet,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ))
              : Text(_formatSearchDate(doc.updatedAt),
                  style: const TextStyle(fontSize: 12)),
          onTap: () {
            close(context, doc.id);
            ref.read(currentDocumentIdProvider.notifier).state = doc.id;
            ref.read(currentContentProvider.notifier).state = doc.content;
            ref.read(currentTitleProvider.notifier).state = doc.title;
            Navigator.pushNamed(context, '/editor');
          },
        );
      },
    );
  }

  Widget _buildSearchPrompt(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search, size: 48,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Text('输入关键词搜索文档',
              style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.4))),
          const SizedBox(height: 4),
          Text('共 ${docs.length} 篇文档',
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

  /// 搜索文档，返回 (文档, 匹配摘要)
  List<(Document, String?)> _search(String q) {
    final results = <(Document, String?)>[];
    for (final doc in docs) {
      // 标题精确匹配
      if (doc.title.toLowerCase().contains(q)) {
        results.add((doc, null));
        continue;
      }
      // 内容模糊匹配 - 找到相关行作为摘要
      final contentLower = doc.content.toLowerCase();
      final idx = contentLower.indexOf(q);
      if (idx != -1) {
        // 截取匹配位置周围的内容作为摘要
        final start = idx > 40 ? idx - 40 : 0;
        final end = (idx + q.length + 60) < doc.content.length
            ? idx + q.length + 60
            : doc.content.length;
        var snippet = doc.content.substring(start, end);
        if (start > 0) snippet = '...$snippet';
        if (end < doc.content.length) snippet = '$snippet...';
        results.add((doc, snippet.trim()));
      }
    }
    return results;
  }

  /// 标题高亮匹配部分
  Widget _highlightMatch(
      String title, String query, BuildContext context) {
    final lower = title.toLowerCase();
    final idx = lower.indexOf(query.toLowerCase());
    if (idx == -1) return Text(title);

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: [
          TextSpan(text: title.substring(0, idx)),
          TextSpan(
            text: title.substring(idx, idx + query.length),
            style: TextStyle(
              backgroundColor:
                  Theme.of(context).colorScheme.primaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: title.substring(idx + query.length)),
        ],
      ),
    );
  }

  String _formatSearchDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
