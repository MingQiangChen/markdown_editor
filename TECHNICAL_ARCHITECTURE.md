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
│   ├── editor_screen.dart       # 编辑器页面：标签栏/工具栏/布局/快捷键/大纲/状态栏
│   ├── editor_controller.dart   # 文本操作控制器 (insert/wrap/undo/redo)
│   └── widgets/
│       ├── source_code_editor.dart  # 代码编辑区 (re_editor.CodeEditor + 语法高亮)
│       ├── markdown_preview.dart    # 预览区 (Markdown + 代码高亮 + LaTeX + Mermaid + 行内数学 + 任务列表)
│       ├── toolbar.dart             # 格式化工具栏 (16 个按钮)
│       ├── find_replace_bar.dart    # 查找/替换栏
│       ├── outline_panel.dart       # 文档大纲面板 (标题层级 + 点击跳转)
│       └── editor_tab_bar.dart      # 多标签页栏 (切换/关闭/右键菜单/中键关闭)
│
├── features/                    # 功能页面
│   ├── home/                    # 首页（文档列表 + 文件夹 + 标签筛选 + 搜索）
│   ├── settings/                # 设置页面 (主题/编辑器/快捷键/数据管理)
│   └── file_manager/            # 文件管理 (排序/导入/批量操作/导出)
│
└── storage/                     # 存储模块
    └── local_storage.dart       # Hive 存储服务封装
```

---

## 数据流架构

```
用户输入 / 工具栏操作
      │
      ▼
CodeLineEditingController.text 更新
      │
      ├── onChanged 回调 → currentContentProvider 更新
      │
      ├──→ SourceCodeEditor (编辑区回显)
      │     └── 外部同步: if (cc.text != content) cc.text = content
      │
      ├──→ MarkdownPreview (flutter_markdown 渲染)
      │     └── _CodeBlockBuilder 分派:
      │         - math/latex → flutter_math_fork
      │         - mermaid → flutter_mermaid
      │         - 其他语言 → re_highlight TextSpanRenderer (语法高亮)
      │     └── InlineMathSyntax ($...$) → flutter_math_fork
      │     └── checkboxBuilder → GFM 任务列表图标
      │     └── InteractiveViewer (缩放 0.5x-3.0x)
      │
      ├──→ OutlinePanel (标题解析 + 层级渲染)
      │     └── 点击 → EditorController.selection → 编辑器滚动
      │
      ├──→ StatusBar (行数/词数/字符数/阅读时间)
      │
      └──→ EditorTabBar (标签切换)
            └── _switchTab: 保存当前 → 切换 currentDocumentId → 新 EditorController 创建
```

**关键设计原则**:
1. **单一数据源**: `currentContentProvider` 是编辑内容的唯一权威来源
2. **Controller 生命周期**: `editorControllerProvider` 使用 `autoDispose` + `ref.watch(currentDocumentIdProvider)` 实现文档切换时自动重建
3. **双向同步**: CodeEditor ↔ Provider 通过 `cc.text != content` 检测和 `onChanged` 回调保持同步
4. **标签隔离**: 切换标签时保存当前内容到 Hive，新标签的 EditorController 从 Hive 读取内容初始化

---

## Provider 依赖图

```
documentBoxProvider ────→ documentListProvider / allDocumentsProvider
settingsBoxProvider ────→ loadSettings()
versionBoxProvider ─────→ _createVersion()

editorModeProvider ─────→ EditorScreen._buildEditorLayout()
editorFontSizeProvider ─→ SourceCodeEditor
autoSaveProvider ───────→ EditorScreen._setupAutoSaveTimer()
themeModeProvider ──────→ MaterialApp.themeMode

currentDocumentIdProvider ─→ editorControllerProvider (watched for autoDispose)
                           ─→ _saveDocument() / EditorTabBar
currentContentProvider ────→ 编辑区 + 预览区 + 状态栏 + 大纲面板
currentTitleProvider ──────→ AppBar.title + EditorTabBar
openTabsProvider ──────────→ EditorTabBar + _addToTabs / _closeTab

fileSortFieldProvider ─────→ allDocumentsProvider (排序)
fileSortAscendingProvider ─→ allDocumentsProvider
```

---

## 关键设计决策

### 1. 编辑器: re_editor + 自定义 Controller

- `CodeLineEditingController`: 文本编辑、选区管理、行号
- `CodeFindController`: 查找/替换
- `CodeHighlightTheme`: re_highlight 语法定义 + 主题
- `EditorController`: 自定义封装，提供 insertAtCursor / wrapSelection / insertBlockPrefix / undo / redo
- Provider 使用 `autoDispose` + `ref.watch(currentDocumentIdProvider)` 实现文档切换时自动重建

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
