# Markdown Editor — 技术架构文档

## 项目概述

跨平台 Markdown 编辑器，对标 Obsidian 的双栏编辑体验。支持桌面 (Linux/Windows/macOS)、移动端 (Android/iOS/HarmonyOS) 和 Web 平台。

**技术栈**: Flutter 3.38 + Dart 3.10 + Riverpod + Hive + re_editor

---

## 架构分层

```
lib/
├── main.dart                    # 入口：Hive 初始化 + ProviderScope
├── app.dart                     # MaterialApp 配置 (路由/主题)
│
├── core/                        # 全局基础设施
│   ├── constants/               # 常量、枚举 (EditorMode, SyncStatus)
│   ├── theme/                   # 浅色/深色主题定义 (flex_color_scheme)
│   └── utils/                   # 工具：HTML导出、文件下载(条件导入)
│
├── data/                        # 数据层
│   ├── models/                  # Hive 数据模型 (Document, 含 HiveTypeAdapter)
│   └── providers/               # Riverpod Provider 定义 (全局状态)
│
├── editor/                      # 编辑器模块 (核心)
│   ├── editor_screen.dart       # 编辑器页面：Shortcuts/Actions/PopScope/Scaffold
│   ├── editor_controller.dart   # 文本操作控制器 (insert/wrap/undo/redo)
│   └── widgets/
│       ├── source_code_editor.dart  # 代码编辑区 (re_editor.CodeEditor)
│       ├── markdown_preview.dart    # 预览区 (flutter_markdown + 数学公式)
│       ├── toolbar.dart             # 格式化工具栏
│       └── find_replace_bar.dart    # 查找/替换栏
│
├── features/                    # 功能页面
│   ├── home/                    # 首页（文档列表 + 文件夹 + 标签筛选）
│   ├── settings/                # 设置页面
│   └── file_manager/            # 文件管理 (预留)
│
└── storage/                     # 存储模块
    └── local_storage.dart       # Hive 存储服务封装
```

---

## 数据流架构

```
用户输入 CodeEditor
      │ onChanged
      ▼
currentContentProvider (Riverpod StateProvider<String>)
      │
      ├──→ SourceCodeEditor (编辑区回显)
      │     └── 外部同步: if (cc.text != content) cc.text = content
      │
      ├──→ MarkdownPreview (flutter_markdown 渲染)
      │     └── 扩展: _MathCodeBuilder (flutter_math_fork)
      │
      ├──→ StatusBar (行数/字数统计)
      │
      └──→ EditorController (工具栏操作)
                │
                ├── insertAtCursor(text)
                ├── wrapSelection(prefix, suffix)
                ├── insertBlockPrefix(prefix)
                ├── undo() / redo() → codeController.undo()/redo()
                │
                └──→ codeController.text 更新
                          │
                          ▼
                   onChanged 回调触发
                          │
                          ▼
              currentContentProvider 更新 → 所有监听者 rebuild
```

**关键设计原则**:
1. **单一数据源**: `currentContentProvider` 是编辑内容的唯一权威来源
2. **双向同步**: CodeEditor ↔ Provider 之间通过 `cc.text != content` 检测和 `onChanged` 回调保持同步
3. **Controller 模式**: 所有文本修改通过 `EditorController` 统一处理，保证光标位置正确

---

## Provider 依赖图

```
documentBoxProvider ────→ documentListProvider
settingsBoxProvider ────→ loadSettings()
versionBoxProvider ─────→ _createVersion()

editorModeProvider ─────→ EditorScreen._buildEditorLayout()
showPreviewProvider ────→ (P2: 废弃，改用 editorMode)
editorFontSizeProvider ─→ SourceCodeEditor
autoSaveProvider ───────→ EditorScreen._setupAutoSaveTimer()
themeModeProvider ──────→ MaterialApp.themeMode

currentDocumentIdProvider ─→ _saveDocument() / _openDocument()
currentContentProvider ────→ 编辑区 + 预览区 + 状态栏
currentTitleProvider ──────→ AppBar.title
```

---

## 关键设计决策

### 1. 编辑器选择: TextField → re_editor

| 阶段 | 方案 | 原因 |
|------|------|------|
| P0 | `TextField` | 快速原型，简单够用 |
| P1 | `re_editor.CodeEditor` | 行号、语法高亮、虚拟滚动、撤销重做 |

迁移要点:
- `TextEditingController` → `CodeLineEditingController`
- 光标操作: 平铺索引 → `CodeLinePosition(index, offset)`
- 选区操作: `CodeLineSelection(baseIndex, baseOffset, extentIndex, extentOffset)`
- 行号: `DefaultCodeLineNumber` widget

### 2. 持久化: Hive

- 3 个 Box: `documents` (Document), `settings` (动态类型), `document_versions` (String)
- HiveType + TypeAdapter 自动生成 (build_runner)
- 向后兼容: 新增字段使用默认值 (如 `isFolder` 默认为 false)

### 3. 响应式布局

- 断点: 600px (`AppConstants.compactWidthBreakpoint`)
- 窄屏: 强制单栏 + 底部编辑/预览切换条
- 宽屏: 支持双栏/单栏/纯预览三种模式

### 4. 条件导入 (跨平台文件下载)

```dart
import 'download_stub.dart'              // 非 Web 平台 (no-op)
    if (dart.library.html) 'download_web.dart';  // Web (dart:html Blob)
```

---

## 依赖版本

| Package | 版本 | 用途 |
|---------|------|------|
| Flutter SDK | 3.38.6 | 框架 |
| re_editor | 0.9.0 | 代码编辑器 |
| re_highlight | 0.0.3 | 语法高亮引擎 |
| flutter_markdown | 0.6.23 | Markdown 渲染 |
| flutter_math_fork | 0.7.4 | LaTeX 数学公式渲染 |
| flutter_mermaid | 0.1.0 | Mermaid 流程图渲染 (纯 Dart) |
| flutter_riverpod | 2.6.1 | 状态管理 |
| hive / hive_flutter | 2.2.3 / 1.1.0 | 本地数据库 |
| file_picker | 6.2.1 | 文件选择 |
| path_provider | 2.1.1 | 文件路径 |
| share_plus | 7.2.1 | 系统分享 |
| printing | 5.14.3 | PDF 导出 (系统打印) |
| markdown | 7.1.1 | Markdown 解析 (HTML 导出) |

---

## 构建与部署

```bash
# Web (开发)
flutter run -d chrome --web-port=4321

# Web (构建)
flutter build web --no-web-resources-cdn

# Linux 桌面
flutter run -d linux
flutter build linux

# 全平台
flutter build apk      # Android
flutter build ios      # iOS
flutter build macos    # macOS
flutter build windows  # Windows
```

### Linux 桌面构建依赖

```bash
sudo apt install cmake clang ninja-build pkg-config libgtk-3-dev libstdc++-14-dev lld
```
