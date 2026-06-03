import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'data/models/document.dart';
import 'data/providers/app_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(DocumentAdapter());
  final docBox = await Hive.openBox<Document>('documents');
  final settingsBox = await Hive.openBox('settings');

  runApp(
    ProviderScope(
      overrides: [
        documentBoxProvider.overrideWithValue(docBox),
        settingsBoxProvider.overrideWithValue(settingsBox),
      ],
      child: const SettingsLoader(child: MarkdownEditorApp()),
    ),
  );
}

/// 启动时从 Hive 加载持久化设置
class SettingsLoader extends ConsumerWidget {
  final Widget child;
  const SettingsLoader({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 在首次 build 时加载设置
    loadSettings(ref);
    return child;
  }
}
