import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../data/providers/app_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final editorMode = ref.watch(editorModeProvider);
    final showPreview = ref.watch(showPreviewProvider);
    final fontSize = ref.watch(editorFontSizeProvider);
    final autoSave = ref.watch(autoSaveProvider);
    final box = ref.read(settingsBoxProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          // ─── 外观 ─────────────────────────────
          const _SectionHeader(title: '外观'),
          _settingTile(
            icon: Icons.palette,
            title: '主题',
            subtitle: _themeLabel(themeMode),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.light, label: Text('浅色')),
                ButtonSegment(value: ThemeMode.dark, label: Text('深色')),
                ButtonSegment(value: ThemeMode.system, label: Text('系统')),
              ],
              selected: {themeMode},
              onSelectionChanged: (mode) {
                ref.read(themeModeProvider.notifier).state = mode.first;
                box.put(AppConstants.themeModeKey, mode.first.index);
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                textStyle: WidgetStateProperty.all(
                    const TextStyle(fontSize: 12)),
              ),
            ),
          ),

          // ─── 编辑器 ───────────────────────────
          const _SectionHeader(title: '编辑器'),
          SwitchListTile(
            secondary: const Icon(Icons.preview),
            title: const Text('显示预览'),
            subtitle: const Text('关闭后进入纯编辑模式'),
            value: showPreview,
            onChanged: (v) {
              ref.read(showPreviewProvider.notifier).state = v;
              box.put(AppConstants.showPreviewKey, v);
            },
          ),
          ListTile(
            leading: const Icon(Icons.view_agenda),
            title: const Text('默认编辑模式'),
            subtitle: Text(_editorModeLabel(editorMode)),
            trailing: DropdownButton<EditorMode>(
              value: editorMode,
              isDense: true,
              underline: const SizedBox.shrink(),
              onChanged: (mode) {
                if (mode != null) {
                  ref.read(editorModeProvider.notifier).state = mode;
                  box.put('editor_mode', mode.index);
                }
              },
              items: const [
                DropdownMenuItem(
                    value: EditorMode.split, child: Text('双栏')),
                DropdownMenuItem(
                    value: EditorMode.editOnly, child: Text('仅编辑')),
                DropdownMenuItem(
                    value: EditorMode.previewOnly, child: Text('仅预览')),
              ],
            ),
          ),
          _settingTile(
            icon: Icons.format_size,
            title: '字体大小',
            subtitle: '${fontSize.round()} px',
            child: SizedBox(
              width: 200,
              child: Slider(
                value: fontSize,
                min: AppConstants.minFontSize,
                max: AppConstants.maxFontSize,
                divisions: ((AppConstants.maxFontSize - AppConstants.minFontSize) / 1).round(),
                label: '${fontSize.round()}',
                onChanged: (v) {
                  ref.read(editorFontSizeProvider.notifier).state = v;
                  box.put(AppConstants.editorFontSizeKey, v);
                },
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.auto_mode),
            title: const Text('自动保存'),
            subtitle: Text(_autoSaveLabel(autoSave)),
            onTap: () => _showAutoSaveSheet(context, ref, box, autoSave),
          ),

          // ─── 快捷键参考 ──────────────────────
          const _SectionHeader(title: '快捷键'),
          ListTile(
            leading: const Icon(Icons.keyboard),
            title: const Text('查看快捷键'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showShortcutsSheet(context),
          ),

          // ─── 数据 ─────────────────────────────
          const _SectionHeader(title: '数据'),
          const ListTile(
            leading: Icon(Icons.storage),
            title: Text('存储信息'),
            subtitle: Text('本地 Hive 数据库 (浏览器 IndexedDB)'),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('清除所有数据',
                style: TextStyle(color: Colors.red)),
            subtitle: const Text('删除所有本地文档和设置'),
            onTap: () => _showClearDataDialog(context, ref),
          ),

          // ─── 关于 ─────────────────────────────
          const _SectionHeader(title: '关于'),
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('版本'),
            subtitle: Text(AppConstants.appVersion),
          ),
          const ListTile(
            leading: Icon(Icons.code),
            title: Text('技术栈'),
            subtitle: Text('Flutter • Riverpod • Hive'),
          ),
          const ListTile(
            leading: Icon(Icons.check_circle_outline),
            title: Text('平台目标'),
            subtitle: Text('Windows / macOS / Linux / iOS / Android / HarmonyOS / Web'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _themeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.light => '浅色',
        ThemeMode.dark => '深色',
        ThemeMode.system => '跟随系统',
      };

  String _editorModeLabel(EditorMode mode) => switch (mode) {
        EditorMode.split => '双栏 (编辑 + 预览)',
        EditorMode.editOnly => '仅编辑',
        EditorMode.previewOnly => '仅预览',
      };

  String _autoSaveLabel(int seconds) => switch (seconds) {
        0 => '关闭',
        5 => '每 5 秒',
        15 => '每 15 秒',
        30 => '每 30 秒',
        _ => '每 $seconds 秒',
      };

  void _showAutoSaveSheet(BuildContext context, WidgetRef ref, Box box,
      int current) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('自动保存间隔',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ...([
              (0, '关闭', Icons.block),
              (5, '每 5 秒', Icons.timer),
              (15, '每 15 秒', Icons.timer),
              (30, '每 30 秒', Icons.timer),
              (60, '每 60 秒', Icons.timer),
            ]).map((opt) {
              final (secs, label, icon) = opt;
              final isSelected = secs == current;
              return ListTile(
                leading: Icon(icon),
                title: Text(label),
                trailing: isSelected
                    ? Icon(Icons.check,
                        color: Theme.of(ctx).colorScheme.primary)
                    : null,
                onTap: () {
                  ref.read(autoSaveProvider.notifier).state = secs;
                  box.put('auto_save', secs);
                  Navigator.pop(ctx);
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showShortcutsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('快捷键参考',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ..._shortcuts.map((s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(s.key,
                              style: const TextStyle(
                                  fontFamily: 'JetBrains Mono', fontSize: 12)),
                        ),
                        const SizedBox(width: 16),
                        Text(s.action),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清除所有数据'),
        content: const Text('将删除所有本地文档和设置，此操作不可恢复。确定继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final docBox = ref.read(documentBoxProvider);
              final settingsBox = ref.read(settingsBoxProvider);
              await docBox.clear();
              await settingsBox.clear();
              ref.read(currentDocumentIdProvider.notifier).state = null;
              ref.read(currentContentProvider.notifier).state = '';
              if (context.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已清除所有数据')),
                );
              }
            },
            child: const Text('确定清除'),
          ),
        ],
      ),
    );
  }

  static const _shortcuts = [
    (key: 'Ctrl+B', action: '加粗'),
    (key: 'Ctrl+I', action: '斜体'),
    (key: 'Ctrl+K', action: '插入链接'),
    (key: 'Ctrl+S', action: '保存'),
    (key: 'Ctrl+F', action: '查找'),
    (key: 'Ctrl+Z', action: '撤销'),
    (key: 'Ctrl+Y', action: '重做'),
  ];
}

/// 通用设置行：图标 + 标题 + 副标题 + 右侧控件
Widget _settingTile({
  required IconData icon,
  required String title,
  required String subtitle,
  required Widget child,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      children: [
        Icon(icon, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14)),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ),
        child,
      ],
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
