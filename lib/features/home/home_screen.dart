import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/document.dart';
import '../../data/providers/app_providers.dart';

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
            onPressed: () => _showSearch(context),
          ),
          IconButton(
            icon: Icon(
              themeMode == ThemeMode.dark
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            tooltip: '切换主题',
            onPressed: () {
              ref.read(themeModeProvider.notifier).state = themeMode ==
                      ThemeMode.dark
                  ? ThemeMode.light
                  : ThemeMode.dark;
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '设置',
            onPressed: () {},
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
              style: TextStyle(color: surface.withValues(alpha: 0.5), fontSize: 16)),
          const SizedBox(height: 8),
          Text('点击右下角 + 创建第一篇文档',
              style: TextStyle(color: surface.withValues(alpha: 0.3), fontSize: 13)),
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
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('删除', style: TextStyle(color: Colors.red)),
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

  void _showSearch(BuildContext context) {
    showSearch(context: context, delegate: _DocumentSearch());
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

/// 文档搜索代理
class _DocumentSearch extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, ''),
      );

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults(context);

  Widget _buildSearchResults(BuildContext context) {
    return const Center(child: Text('搜索功能开发中'));
  }
}

/// 文档列表 Provider
final documentListProvider = Provider<List<Document>>((ref) {
  final box = ref.watch(documentBoxProvider);
  final docs = box.values.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return docs;
});
