import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/file_io_stub.dart'
    if (dart.library.io) '../../core/utils/file_io_native.dart';
import '../../data/models/document.dart';
import '../../data/providers/app_providers.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _currentFolderId;
  String? _selectedTag;
  bool _showFabMenu = false;

  List<Document> _folders(List<Document> docs) => docs
      .where((d) => d.isFolder && d.parentId == _currentFolderId)
      .toList();

  List<Document> _docs(List<Document> docs) {
    var result = docs
        .where((d) => !d.isFolder && d.parentId == _currentFolderId)
        .toList();
    if (_selectedTag != null) {
      result = result.where((d) => d.tags.contains(_selectedTag)).toList();
    }
    return result;
  }

  List<String> _allTags(List<Document> docs) {
    final tags = <String>{};
    for (final d in docs) {
      if (!d.isFolder) tags.addAll(d.tags);
    }
    return tags.toList()..sort();
  }

  int _childCount(List<Document> allDocs, String folderId) =>
      allDocs.where((d) => d.parentId == folderId && !d.isFolder).length;

  String? _folderTitle(List<Document> docs) {
    if (_currentFolderId == null) return null;
    return docs
        .where((d) => d.id == _currentFolderId)
        .map((d) => d.title)
        .firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final docs = ref.watch(documentListProvider);
    final currentId = ref.watch(currentDocumentIdProvider);
    final themeMode = ref.watch(themeModeProvider);
    final folderTitle = _folderTitle(docs);
    final showBack = _currentFolderId != null;
    final folders = _folders(docs);
    final curDocs = _docs(docs);
    final allTags = _allTags(docs);

    return Scaffold(
      appBar: AppBar(
        leading: showBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _currentFolderId = null),
              )
            : null,
        title: Text(folderTitle ?? AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: '打开文件',
            onPressed: () => _openFromFile(ref),
          ),
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
              ref.read(settingsBoxProvider).put(
                  AppConstants.themeModeKey, newMode.index);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '设置',
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],
      ),
      body: docs.isEmpty
          ? _buildEmptyState(context)
          : Column(
              children: [
                if (!showBack) _buildFolderSection(context, ref, folders),
                if (allTags.isNotEmpty) _buildTagBar(context, allTags),
                if (!showBack && folders.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Row(
                      children: [
                        Text(
                          showBack ? (folderTitle ?? '文档') : '所有文档',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1),
                        ),
                        const Spacer(),
                        Text('${curDocs.length} 篇',
                            style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.4))),
                      ],
                    ),
                  ),
                Expanded(
                    child: curDocs.isEmpty
                        ? _buildEmptyFolder(context)
                        : _buildDocumentList(
                            context, ref, curDocs, currentId)),
              ],
            ),
      floatingActionButton: _showFabMenu
          ? _buildFabMenu(context, ref)
          : FloatingActionButton(
              onPressed: () => setState(() => _showFabMenu = true),
              tooltip: '新建',
              child: const Icon(Icons.add),
            ),
    );
  }

  // ─── FAB 菜单 ─────────────────────────────────────────

  Widget _buildFabMenu(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: 'folder',
          tooltip: '新建文件夹',
          onPressed: () {
            setState(() => _showFabMenu = false);
            _createFolder(ref);
          },
          child: const Icon(Icons.create_new_folder),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: 'doc',
          tooltip: '新建文档',
          onPressed: () {
            setState(() => _showFabMenu = false);
            _createDocument(ref);
          },
          child: const Icon(Icons.note_add),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: 'close',
          tooltip: '关闭',
          onPressed: () => setState(() => _showFabMenu = false),
          child: const Icon(Icons.close),
        ),
      ],
    );
  }

  // ─── 空状态 ───────────────────────────────────────────

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

  Widget _buildEmptyFolder(BuildContext context) {
    final surface = Theme.of(context).colorScheme.onSurface;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open,
              size: 48, color: surface.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Text('此文件夹为空',
              style: TextStyle(
                  color: surface.withValues(alpha: 0.5), fontSize: 15)),
          const SizedBox(height: 6),
          Text('点击右下角 + 新建文档',
              style: TextStyle(
                  color: surface.withValues(alpha: 0.3), fontSize: 12)),
        ],
      ),
    );
  }

  // ─── 文件夹区域 ───────────────────────────────────────

  Widget _buildFolderSection(
      BuildContext context, WidgetRef ref, List<Document> folders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Icon(Icons.folder, size: 16,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 6),
              Text('文件夹',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                    letterSpacing: 1,
                  )),
              const Spacer(),
              if (folders.isNotEmpty)
                Text('${folders.length}',
                    style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.4))),
            ],
          ),
        ),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: folders.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final folder = folders[index];
              final count = _childCount(
                  ref.read(documentListProvider), folder.id);
              return GestureDetector(
                onTap: () => setState(() => _currentFolderId = folder.id),
                onLongPress: () =>
                    _showFolderContextMenu(context, ref, folder),
                child: Container(
                  width: 140,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.folder,
                          size: 22,
                          color: Theme.of(context).colorScheme.primary),
                      const Spacer(),
                      Text(folder.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 13)),
                      Text('$count 篇',
                          style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5))),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── 标签筛选栏 ───────────────────────────────────────

  Widget _buildTagBar(BuildContext context, List<String> allTags) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 36,
      margin: const EdgeInsets.only(top: 4),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          FilterChip(
            label: const Text('全部', style: TextStyle(fontSize: 12)),
            selected: _selectedTag == null,
            onSelected: (_) => setState(() => _selectedTag = null),
            visualDensity: VisualDensity.compact,
            selectedColor: cs.primaryContainer,
            checkmarkColor: cs.primary,
          ),
          const SizedBox(width: 6),
          ...allTags.map((tag) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: Text(tag, style: const TextStyle(fontSize: 12)),
                  selected: _selectedTag == tag,
                  onSelected: (sel) => setState(
                      () => _selectedTag = sel ? tag : null),
                  visualDensity: VisualDensity.compact,
                  selectedColor: cs.primaryContainer,
                  checkmarkColor: cs.primary,
                ),
              )),
        ],
      ),
    );
  }

  // ─── 文档列表 ─────────────────────────────────────────

  Widget _buildDocumentList(BuildContext context, WidgetRef ref,
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
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_formatDate(doc.updatedAt),
                  style: const TextStyle(fontSize: 12)),
              if (doc.tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 2,
                    children: doc.tags
                        .map((t) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondaryContainer
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(t,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSecondaryContainer,
                                  )),
                            ))
                        .toList(),
                  ),
                ),
            ],
          ),
          onTap: () => _openDocument(ref, context, doc),
          onLongPress: () => _showContextMenu(context, ref, doc),
        );
      },
    );
  }

  // ─── 文件夹操作 ───────────────────────────────────────

  void _createFolder(WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建文件夹'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '文件夹名称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              final box = ref.read(documentBoxProvider);
              final folder = Document(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: name,
                isFolder: true,
                parentId: _currentFolderId,
              );
              await box.put(folder.id, folder);
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  void _showFolderContextMenu(
      BuildContext context, WidgetRef ref, Document folder) {
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
                _renameFolder(ref, folder);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('删除', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _deleteFolder(ref, folder);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _renameFolder(WidgetRef ref, Document folder) {
    final controller = TextEditingController(text: folder.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重命名文件夹'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '新名称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              folder.rename(name);
              final box = ref.read(documentBoxProvider);
              await box.put(folder.id, folder);
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _deleteFolder(WidgetRef ref, Document folder) async {
    final allDocs = ref.read(documentListProvider);
    final childCount = _childCount(allDocs, folder.id);
    if (childCount > 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('文件夹 "$folder.title" 中有 $childCount 篇文档，请先移走文档')),
        );
      }
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除文件夹'),
        content: Text('确定删除文件夹 "${folder.title}" 吗？'),
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
      await box.delete(folder.id);
      if (_currentFolderId == folder.id) {
        setState(() => _currentFolderId = null);
      }
    }
  }

  // ─── 文档操作 ─────────────────────────────────────────

  void _createDocument(WidgetRef ref) async {
    final doc = Document(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '未命名文档',
      parentId: _currentFolderId,
    );
    final box = ref.read(documentBoxProvider);
    await box.put(doc.id, doc);
    ref.read(currentContentProvider.notifier).state = '';
    ref.read(currentTitleProvider.notifier).state = doc.title;
    ref.read(currentFilePathProvider.notifier).state = null;
    ref.read(currentDocumentIdProvider.notifier).state = doc.id;
    if (!mounted) return;
    Navigator.pushNamed(context, '/editor');
  }

  void _openFromFile(WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['md', 'markdown', 'txt'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final title = file.name;
      String content;
      if (file.bytes != null) {
        content = utf8.decode(file.bytes!);
      } else if (file.path != null) {
        content = readFileAsString(file.path!);
      } else {
        return;
      }

      final doc = Document(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        content: content,
      );
      final box = ref.read(documentBoxProvider);
      await box.put(doc.id, doc);
      ref.read(currentContentProvider.notifier).state = content;
      ref.read(currentTitleProvider.notifier).state = title;
      ref.read(currentFilePathProvider.notifier).state = file.path;
      ref.read(currentDocumentIdProvider.notifier).state = doc.id;
      if (!mounted) return;
      Navigator.pushNamed(context, '/editor');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('无法打开文件: $e')),
        );
      }
    }
  }

  void _openDocument(WidgetRef ref, BuildContext context, Document doc) {
    ref.read(currentContentProvider.notifier).state = doc.content;
    ref.read(currentTitleProvider.notifier).state = doc.title;
    ref.read(currentFilePathProvider.notifier).state = null;
    ref.read(currentDocumentIdProvider.notifier).state = doc.id;
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
              leading: const Icon(Icons.drive_file_move),
              title: const Text('移动到文件夹'),
              onTap: () {
                Navigator.pop(ctx);
                _moveToFolder(context, ref, doc);
              },
            ),
            ListTile(
              leading: const Icon(Icons.label),
              title: const Text('管理标签'),
              onTap: () {
                Navigator.pop(ctx);
                _manageTags(context, ref, doc);
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

  void _moveToFolder(
      BuildContext context, WidgetRef ref, Document doc) {
    final allDocs = ref.read(documentListProvider);
    final folders = allDocs.where((d) => d.isFolder).toList();

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('移动到文件夹',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: const Text('根目录（无文件夹）'),
              onTap: () async {
                Navigator.pop(ctx);
                final box = ref.read(documentBoxProvider);
                doc.parentId = null;
                await box.put(doc.id, doc);
              },
            ),
            ...folders.map((folder) => ListTile(
                  leading: const Icon(Icons.folder),
                  title: Text(folder.title),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final box = ref.read(documentBoxProvider);
                    doc.parentId = folder.id;
                    await box.put(doc.id, doc);
                  },
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _manageTags(
      BuildContext context, WidgetRef ref, Document doc) {
    final allTags = _allTags(ref.read(documentListProvider));
    final docTags = List<String>.from(doc.tags);
    final newTagCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('管理标签 — ${doc.title}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('已添加的标签',
                    style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5))),
                const SizedBox(height: 8),
                if (docTags.isEmpty)
                  Text('暂无标签',
                      style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.4)))
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: docTags
                        .map((tag) => InputChip(
                              label: Text(tag,
                                  style: const TextStyle(fontSize: 12)),
                              onDeleted: () async {
                                doc.tags.remove(tag);
                                docTags.remove(tag);
                                final box = ref.read(documentBoxProvider);
                                await box.put(doc.id, doc);
                                setSheetState(() {});
                                setState(() {});
                              },
                              visualDensity: VisualDensity.compact,
                            ))
                        .toList(),
                  ),
                const Divider(height: 24),
                Text('可用标签',
                    style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5))),
                const SizedBox(height: 8),
                if (allTags.where((t) => !docTags.contains(t)).isEmpty)
                  Text('没有更多可用标签',
                      style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.4)))
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: allTags
                        .where((t) => !docTags.contains(t))
                        .map((tag) => ActionChip(
                              label: Text(tag,
                                  style: const TextStyle(fontSize: 12)),
                              onPressed: () async {
                                doc.tags.add(tag);
                                docTags.add(tag);
                                final box = ref.read(documentBoxProvider);
                                await box.put(doc.id, doc);
                                setSheetState(() {});
                                setState(() {});
                              },
                              visualDensity: VisualDensity.compact,
                            ))
                        .toList(),
                  ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: newTagCtrl,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: '新建标签...',
                          hintStyle: const TextStyle(fontSize: 13),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4)),
                          isDense: true,
                          isCollapsed: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () async {
                        final name = newTagCtrl.text.trim();
                        if (name.isEmpty) return;
                        if (!doc.tags.contains(name)) {
                          doc.tags.add(name);
                          docTags.add(name);
                          final box = ref.read(documentBoxProvider);
                          await box.put(doc.id, doc);
                          newTagCtrl.clear();
                          setSheetState(() {});
                          setState(() {});
                        }
                      },
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      child: const Text('添加'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
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

  // ─── 搜索 ─────────────────────────────────────────────

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
          leading: Icon(doc.isFolder ? Icons.folder : Icons.article_outlined),
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
            if (!doc.isFolder) {
              ref.read(currentDocumentIdProvider.notifier).state = doc.id;
              ref.read(currentContentProvider.notifier).state = doc.content;
              ref.read(currentTitleProvider.notifier).state = doc.title;
              Navigator.pushNamed(context, '/editor');
            }
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
          Text('共 ${docs.where((d) => !d.isFolder).length} 篇文档',
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

  List<(Document, String?)> _search(String q) {
    final results = <(Document, String?)>[];
    for (final doc in docs) {
      if (doc.isFolder) continue;
      if (doc.title.toLowerCase().contains(q)) {
        results.add((doc, null));
        continue;
      }
      final contentLower = doc.content.toLowerCase();
      final idx = contentLower.indexOf(q);
      if (idx != -1) {
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
