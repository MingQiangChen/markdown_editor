import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/document.dart';
import '../../data/providers/app_providers.dart';

class EditorTabBar extends ConsumerWidget {
  final VoidCallback onAllTabsClosed;

  const EditorTabBar({super.key, required this.onAllTabsClosed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = ref.watch(openTabsProvider);
    final activeId = ref.watch(currentDocumentIdProvider);
    final box = ref.watch(documentBoxProvider);
    final cs = Theme.of(context).colorScheme;

    if (tabs.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tabs.length,
              itemBuilder: (context, index) {
                final docId = tabs[index];
                final doc = box.get(docId);
                final title = doc?.title ?? '—';
                final isActive = docId == activeId;

                return Listener(
                  onPointerDown: (event) {
                    if (event.buttons == kMiddleMouseButton) {
                      _closeTab(ref, docId, context);
                    }
                  },
                  child: GestureDetector(
                    onTap: () => _switchTab(ref, docId),
                    onSecondaryTapDown: (details) =>
                        _showTabContextMenu(ref, docId, context, details),
                    child: Container(
                    constraints: const BoxConstraints(maxWidth: 180),
                    padding: const EdgeInsets.only(left: 12, right: 4),
                    decoration: BoxDecoration(
                      color: isActive ? cs.surface : Colors.transparent,
                      border: Border(
                        bottom: BorderSide(
                          color: isActive ? cs.primary : Colors.transparent,
                          width: 2,
                        ),
                        right: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                            color: isActive ? cs.onSurface : cs.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(width: 2),
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _closeTab(ref, docId, context),
                              borderRadius: BorderRadius.circular(3),
                              child: Icon(
                                Icons.close,
                                size: 14,
                                color: cs.onSurface.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
              },
            ),
          ),
          SizedBox(
            width: 32,
            height: 34,
            child: IconButton(
              icon: Icon(Icons.add, size: 16, color: cs.onSurface.withValues(alpha: 0.5)),
              onPressed: () => _newTab(ref),
              tooltip: '新建标签',
              padding: EdgeInsets.zero,
              splashRadius: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _switchTab(WidgetRef ref, String docId) {
    final currentId = ref.read(currentDocumentIdProvider);
    if (currentId == docId) return;

    // Save current content
    if (currentId != null) {
      final content = ref.read(currentContentProvider);
      final box = ref.read(documentBoxProvider);
      final doc = box.get(currentId);
      if (doc != null && doc.content != content) {
        doc.update(content);
        box.put(currentId, doc);
      }
    }

    // Switch
    final box = ref.read(documentBoxProvider);
    final doc = box.get(docId);
    if (doc != null) {
      ref.read(currentDocumentIdProvider.notifier).state = docId;
      ref.read(currentContentProvider.notifier).state = doc.content;
      ref.read(currentTitleProvider.notifier).state = doc.title;
    }
  }

  void _closeTab(WidgetRef ref, String docId, BuildContext context) {
    final currentId = ref.read(currentDocumentIdProvider);
    final tabs = ref.read(openTabsProvider).toList();
    final idx = tabs.indexOf(docId);
    if (idx == -1) return;

    // Save before closing
    if (currentId == docId) {
      final content = ref.read(currentContentProvider);
      final box = ref.read(documentBoxProvider);
      final doc = box.get(docId);
      if (doc != null && doc.content != content) {
        doc.update(content);
        box.put(docId, doc);
      }
    }

    tabs.removeAt(idx);
    ref.read(openTabsProvider.notifier).state = tabs;

    if (currentId == docId) {
      if (tabs.isEmpty) {
        onAllTabsClosed();
      } else {
        final newIdx = idx.clamp(0, tabs.length - 1);
        _switchTab(ref, tabs[newIdx]);
      }
    }
  }

  void _newTab(WidgetRef ref) {
    final doc = Document(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '未命名文档',
    );
    final box = ref.read(documentBoxProvider);
    box.put(doc.id, doc);

    final tabs = ref.read(openTabsProvider).toList();
    ref.read(openTabsProvider.notifier).state = [...tabs, doc.id];

    ref.read(currentDocumentIdProvider.notifier).state = doc.id;
    ref.read(currentContentProvider.notifier).state = '';
    ref.read(currentTitleProvider.notifier).state = doc.title;
  }

  void _showTabContextMenu(
      WidgetRef ref, String docId, BuildContext context, TapDownDetails details) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx + 1,
        details.globalPosition.dy + 1,
      ),
      items: const [
        PopupMenuItem(
          value: 'close',
          child: Text('关闭'),
        ),
        PopupMenuItem(
          value: 'close_others',
          child: Text('关闭其他'),
        ),
        PopupMenuItem(
          value: 'close_all',
          child: Text('关闭全部'),
        ),
      ],
    ).then((value) {
      if (!context.mounted) return;
      switch (value) {
        case 'close':
          _closeTab(ref, docId, context);
        case 'close_others':
          _closeOtherTabs(ref, docId);
        case 'close_all':
          _closeAllTabs(ref);
      }
    });
  }

  void _closeOtherTabs(WidgetRef ref, String keepId) {
    final currentId = ref.read(currentDocumentIdProvider);

    // Switch to keepId if needed
    if (currentId != keepId) {
      _switchTab(ref, keepId);
    }

    ref.read(openTabsProvider.notifier).state = [keepId];
  }

  void _closeAllTabs(WidgetRef ref) {
    ref.read(openTabsProvider.notifier).state = [];
    onAllTabsClosed();
  }
}
