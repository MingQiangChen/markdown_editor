import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/document.dart';
import '../../data/providers/app_providers.dart';

/// 完整的文件管理器页面 (独立路由)
class FileManagerScreen extends ConsumerStatefulWidget {
  const FileManagerScreen({super.key});

  @override
  ConsumerState<FileManagerScreen> createState() => _FileManagerScreenState();
}

class _FileManagerScreenState extends ConsumerState<FileManagerScreen> {
  @override
  Widget build(BuildContext context) {
    final docs = ref.watch(allDocumentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('文件管理'),
        actions: [
          IconButton(icon: const Icon(Icons.sort), onPressed: _showSortOptions),
          IconButton(
              icon: const Icon(Icons.more_vert), onPressed: _showMoreOptions),
        ],
      ),
      body: docs.isEmpty
          ? const Center(child: Text('暂无文件'))
          : _buildDocumentList(docs),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'import',
            tooltip: '导入文件',
            onPressed: _importFile,
            child: const Icon(Icons.file_open),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'new',
            tooltip: '新建文档',
            onPressed: _createNew,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentList(List<Document> docs) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.article),
            title: Text(doc.title),
            subtitle: Text(
              _formatDate(doc.updatedAt),
              style: const TextStyle(fontSize: 12),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.more_horiz, size: 20),
              onPressed: () => _showDocMenu(doc),
            ),
            onTap: () => _openDocument(doc),
          ),
        );
      },
    );
  }

  void _openDocument(Document doc) {
    ref.read(currentDocumentIdProvider.notifier).state = doc.id;
    ref.read(currentContentProvider.notifier).state = doc.content;
    Navigator.pushNamed(context, '/editor');
  }

  void _createNew() {
    final doc = Document(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '未命名文档',
    );
    ref.read(documentBoxProvider).put(doc.id, doc);
  }

  void _importFile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('文件导入功能开发中')),
    );
  }

  void _showSortOptions() {
    // TODO: 排序选项 (名称/日期/大小)
  }

  void _showMoreOptions() {
    // TODO: 更多操作 (批量删除/导出)
  }

  void _showDocMenu(Document doc) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('删除', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(documentBoxProvider).delete(doc.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

/// 所有文档 (排序后)
final allDocumentsProvider = Provider<List<Document>>((ref) {
  final box = ref.read(documentBoxProvider);
  final docs = box.values.toList()
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return docs;
});
