class AppConstants {
  AppConstants._();

  static const String appName = 'Markdown Editor';
  static const String appVersion = '0.1.0';

  // 编辑器默认值
  static const double defaultFontSize = 14.0;
  static const double minFontSize = 10.0;
  static const double maxFontSize = 24.0;
  static const String defaultFontFamily = 'JetBrains Mono';

  // 文件
  static const int maxFileSizeBytes = 50 * 1024 * 1024; // 50MB
  static const List<String> supportedExtensions = ['md', 'markdown', 'txt'];

  // 存储 key
  static const String recentFilesKey = 'recent_files';
  static const String themeModeKey = 'theme_mode';
  static const String editorFontSizeKey = 'editor_font_size';
  static const String showPreviewKey = 'show_preview';

  // 响应式断点
  static const double compactWidthBreakpoint = 600;
}

/// 编辑器模式
enum EditorMode {
  editOnly,    // 纯编辑
  previewOnly, // 纯预览
  split,       // 双栏 (Obsidian 模式)
}

/// 同步状态
enum SyncStatus {
  synced,       // 已同步
  syncing,      // 同步中
  localOnly,    // 仅本地
  conflict,     // 冲突
  error,        // 错误
}
