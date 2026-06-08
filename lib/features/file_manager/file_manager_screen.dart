import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/file_io_stub.dart'
    if (dart.library.io) '../../core/utils/file_io_native.dart';
import '../../data/models/document.dart';
import '../../data/providers/app_providers.dart';

enum FileSortField { name, date, size }

final fileSortFieldProvider = StateProvider<FileSortField>((ref) => FileSortField.date);
final fileSortAscendingProvider = StateProvider<bool>((ref) => false);

final allDocumentsProvider = Provider<List<Document>>((ref) {
  final box = ref.watch(documentBoxProvider);
  final sortField = ref.watch(fileSortFieldProvider);
  final ascending = ref.watch(fileSortAscendingProvider);
  final docs = box.values.toList();
  docs.sort((a, b) {
    int cmp;
    switch (sortField) {
      case FileSortField.name:
        cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
      case FileSortField.size:
        cmp = a.content.length.compareTo(b.content.length);
      case FileSortField.date:
        cmp = a.updatedAt.compareTo(b.updatedAt);
    }
    return ascending ? cmp : -cmp;
  });
  return docs;
});

class FileManagerScreen extends ConsumerStatefulWidget {
  const FileManagerScreen({super.key});

  @override
  ConsumerState<FileManagerScreen> createState() => _FileManagerScreenState();
}

class _FileManagerScreenState extends ConsumerState<FileManagerScreen> {
  bool _batchMode = false;
  final _selectedIds = <String>{};

  void _exitBatchMode() {
    setState(() {
      _batchMode = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelectAll(List<Document> docs) {
    setState(() {
      if (_selectedIds.length == docs.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(docs.map((d) => d.id));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final docs = ref.watch(allDocumentsProvider);

    return Scaffold(
      appBar: _batchMode ? _batchAppBar(docs) : _normalAppBar(),
      body: docs.isEmpty
          ? const Center(child: Text('暂无文件'))
          : Column(
              children: [
                _buildSortIndicator(),
                Expanded(child: _buildDocumentList(docs)),
              ],
            ),
      floatingActionButton: _batchMode
          ? null
          : Column(
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
      bottomNavigationBar: _batchMode ? _batchBottomBar(docs) : null,
    );
  }

  AppBar _normalAppBar() {
    return AppBar(
      title: const Text('文件管理'),
      actions: [
        IconButton(icon: const Icon(Icons.sort), onPressed: _showSortOptions),
        IconButton(icon: const Icon(Icons.more_vert), onPressed: _showMoreOptions),
      ],
    );
  }

  AppBar _batchAppBar(List<Document> docs) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _exitBatchMode,
      ),
      title: Text('已选择 ${_selectedIds.length} 项'),
      actions: [
        TextButton(
          onPressed: () => _toggleSelectAll(docs),
          child: Text(
            _selectedIds.length == docs.length ? '取消全选' : '全选',
          ),
        ),
      ],
    );
  }

  Widget _buildSortIndicator() {
    final sortField = ref.watch(fileSortFieldProvider);
    final ascending = ref.watch(fileSortAscendingProvider);

    String label;
    switch (sortField) {
      case FileSortField.name:
        label = '按名称';
      case FileSortField.date:
        label = '按日期';
      case FileSortField.size:
        label = '按大小';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Row(
        children: [
          Text(
            '$label ${ascending ? '↑' : '↓'}',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const Spacer(),
          Text(
            '${ref.watch(allDocumentsProvider).length} 个文件',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
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
        final isSelected = _selectedIds.contains(doc.id);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
              : null,
          child: ListTile(
            leading: _batchMode
                ? Checkbox(
                    value: isSelected,
                    onChanged: (_) {
                      setState(() {
                        if (isSelected) {
                          _selectedIds.remove(doc.id);
                        } else {
                          _selectedIds.add(doc.id);
                        }
                      });
                    },
                  )
                : const Icon(Icons.article),
            title: Text(doc.title),
            subtitle: Text(
              _formatSubtitle(doc),
              style: const TextStyle(fontSize: 12),
            ),
            trailing: _batchMode
                ? null
                : IconButton(
                    icon: const Icon(Icons.more_horiz, size: 20),
                    onPressed: () => _showDocMenu(doc),
                  ),
            onTap: _batchMode
                ? () {
                    setState(() {
                      if (isSelected) {
                        _selectedIds.remove(doc.id);
                      } else {
                        _selectedIds.add(doc.id);
                      }
                    });
                  }
                : () => _openDocument(doc),
          ),
        );
      },
    );
  }

  Widget _batchBottomBar(List<Document> docs) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectedIds.isEmpty ? null : () => _batchExport(docs),
                icon: const Icon(Icons.file_download, size: 18),
                label: const Text('导出'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _selectedIds.isEmpty ? null : () => _batchDelete(docs),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('删除'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSubtitle(Document doc) {
    final dateStr = _formatDate(doc.updatedAt);
    final sizeStr = doc.content.isEmpty ? '空' : '${doc.content.length} 字符';
    return '$dateStr · $sizeStr';
  }

  void _openDocument(Document doc) {
    final tabs = ref.read(openTabsProvider);
    if (!tabs.contains(doc.id)) {
      ref.read(openTabsProvider.notifier).state = [...tabs, doc.id];
    }
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

  // ─── 排序 ────────────────────────────────────────────

  void _showSortOptions() {
    final currentField = ref.read(fileSortFieldProvider);
    final currentAsc = ref.read(fileSortAscendingProvider);

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('排序方式',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ...FileSortField.values.map((field) {
              final isSelected = field == currentField && !currentAsc;
              return ListTile(
                leading: Icon(_sortIcon(field)),
                title: Text(_sortLabel(field)),
                trailing: isSelected
                    ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary)
                    : null,
                onTap: () {
                  ref.read(fileSortFieldProvider.notifier).state = field;
                  ref.read(fileSortAscendingProvider.notifier).state = false;
                  Navigator.pop(ctx);
                },
              );
            }),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.arrow_upward),
              title: const Text('升序'),
              trailing: (currentAsc)
                  ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary)
                  : null,
              onTap: () {
                ref.read(fileSortAscendingProvider.notifier).state = true;
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.arrow_downward),
              title: const Text('降序'),
              trailing: (!currentAsc)
                  ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary)
                  : null,
              onTap: () {
                ref.read(fileSortAscendingProvider.notifier).state = false;
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  IconData _sortIcon(FileSortField field) => switch (field) {
        FileSortField.name => Icons.sort_by_alpha,
        FileSortField.date => Icons.calendar_today,
        FileSortField.size => Icons.data_usage,
      };

  String _sortLabel(FileSortField field) => switch (field) {
        FileSortField.name => '按名称',
        FileSortField.date => '按修改日期',
        FileSortField.size => '按文件大小',
      };

  // ─── 导入 ────────────────────────────────────────────

  void _importFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['md', 'markdown', 'txt'],
        withData: true,
        allowMultiple: true,
      );
      if (result == null || result.files.isEmpty) return;

      final box = ref.read(documentBoxProvider);
      var imported = 0;
      for (final file in result.files) {
        String content;
        if (file.path != null) {
          content = readFileAsString(file.path!);
        } else if (file.bytes != null) {
          content = utf8.decode(file.bytes!);
        } else {
          continue;
        }

        final doc = Document(
          id: '${DateTime.now().millisecondsSinceEpoch}_$imported',
          title: file.name,
          content: content,
        );
        await box.put(doc.id, doc);
        imported++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('成功导入 $imported 个文件')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入文件失败: $e')),
        );
      }
    }
  }

  // ─── 更多操作 ────────────────────────────────────────

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('更多操作',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.checklist),
              title: const Text('批量选择'),
              subtitle: const Text('选择多个文件进行批量操作'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _batchMode = true);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_sweep,
                  color: Theme.of(context).colorScheme.error),
              title: Text('删除所有文件',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteAll();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteAll() async {
    final docs = ref.read(allDocumentsProvider);
    if (docs.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除所有文件'),
        content: Text('确定要删除全部 ${docs.length} 个文件吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除全部'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final box = ref.read(documentBoxProvider);
      for (final doc in docs) {
        await box.delete(doc.id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已删除 ${docs.length} 个文件')),
        );
      }
    }
  }

  // ─── 批量操作 ────────────────────────────────────────

  void _batchDelete(List<Document> docs) async {
    final selected = docs.where((d) => _selectedIds.contains(d.id)).toList();
    if (selected.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('批量删除'),
        content: Text('确定要删除选中的 ${selected.length} 个文件吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final box = ref.read(documentBoxProvider);
      for (final doc in selected) {
        await box.delete(doc.id);
      }
      _exitBatchMode();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已删除 ${selected.length} 个文件')),
        );
      }
    }
  }

  void _batchExport(List<Document> docs) async {
    final selected = docs.where((d) => _selectedIds.contains(d.id)).toList();
    if (selected.isEmpty) return;

    try {
      final dir = await FilePicker.platform.getDirectoryPath(
        dialogTitle: '选择导出目录',
      );
      if (dir == null) return;

      var exported = 0;
      for (final doc in selected) {
        final fileName = doc.title.endsWith('.md') ? doc.title : '${doc.title}.md';
        final path = '$dir/$fileName';
        writeStringToFile(path, doc.content);
        exported++;
      }

      _exitBatchMode();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已导出 $exported 个文件到 $dir')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }

  // ─── 单文件操作 ──────────────────────────────────────

  void _showDocMenu(Document doc) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('打开编辑'),
              onTap: () {
                Navigator.pop(ctx);
                _openDocument(doc);
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_download),
              title: const Text('导出为 .md'),
              onTap: () {
                Navigator.pop(ctx);
                _exportSingle(doc);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('删除', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(ctx);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('删除文件'),
                    content: Text('确定删除 "${doc.title}" 吗？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('取消'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('删除'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  ref.read(documentBoxProvider).delete(doc.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _exportSingle(Document doc) async {
    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: '导出文件',
        fileName: doc.title.endsWith('.md') ? doc.title : '${doc.title}.md',
        type: FileType.custom,
        allowedExtensions: ['md', 'markdown', 'txt'],
      );
      if (result == null) return;

      writeStringToFile(result, doc.content);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已导出: $result')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
