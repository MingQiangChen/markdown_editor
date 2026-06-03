import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../data/providers/app_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final editorMode = ref.watch(editorModeProvider);
    final showPreview = ref.watch(showPreviewProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          // ─── 外观 ─────────────────────────────
          _SectionHeader(title: '外观'),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('主题'),
            subtitle: Text(_themeLabel(themeMode)),
            trailing: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.light, label: Text('浅色')),
                ButtonSegment(value: ThemeMode.dark, label: Text('深色')),
                ButtonSegment(value: ThemeMode.system, label: Text('系统')),
              ],
              selected: {themeMode},
              onSelectionChanged: (mode) =>
                  ref.read(themeModeProvider.notifier).state = mode.first,
            ),
          ),

          // ─── 编辑器 ───────────────────────────
          _SectionHeader(title: '编辑器'),
          SwitchListTile(
            secondary: const Icon(Icons.preview),
            title: const Text('显示预览'),
            value: showPreview,
            onChanged: (v) =>
                ref.read(showPreviewProvider.notifier).state = v,
          ),
          ListTile(
            leading: const Icon(Icons.view_agenda),
            title: const Text('默认编辑模式'),
            subtitle: Text(_editorModeLabel(editorMode)),
            trailing: DropdownButton<EditorMode>(
              value: editorMode,
              onChanged: (mode) {
                if (mode != null) {
                  ref.read(editorModeProvider.notifier).state = mode;
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

          // ─── 关于 ─────────────────────────────
          _SectionHeader(title: '关于'),
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('版本'),
            subtitle: Text(AppConstants.appVersion),
          ),
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
