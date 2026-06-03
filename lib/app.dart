import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'data/providers/app_providers.dart';
import 'features/home/home_screen.dart';
import 'editor/editor_screen.dart';

class MarkdownEditorApp extends ConsumerWidget {
  const MarkdownEditorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Markdown Editor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const HomeScreen(),
      routes: {
        '/editor': (_) => const EditorScreen(),
      },
    );
  }
}
