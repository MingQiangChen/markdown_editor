# Markdown Editor

跨平台 Markdown 编辑器，对标 Obsidian 的双栏编辑体验。

**技术栈**: Flutter 3.38 + Dart 3.10 + Riverpod + Hive + re_editor

## 功能

### 编辑器
- 双栏/仅编辑/仅预览 三种编辑模式
- Markdown 语法高亮 (re_highlight)
- 行号显示、代码折叠
- 格式化工具栏 (标题、加粗、斜体、链接、列表等 16 个按钮)
- 撤销/重做
- 查找/替换 (支持全部替换)
- 字体缩放 (Ctrl+滚轮 / 设置)
- 多标签页 (Ctrl+Tab 切换、Ctrl+W 关闭、中键关闭、右键菜单)

### 预览
- 实时 Markdown 渲染 (flutter_markdown)
- 代码块语法高亮 (~190 种语言，支持深色/浅色主题)
- LaTeX 数学公式 (块级 ```math + 行内 $...$)
- Mermaid 流程图 (flowchart、sequence、pie、gantt 等)
- GFM 任务列表 (- [ ] / - [x])
- 预览缩放 (触控板捏合 0.5x-3.0x)
- 文档大纲面板 (点击标题跳转)

### 文档管理
- 文件夹管理 + 标签系统
- 文档搜索 (标题 + 正文)
- 文件导入/导出 (.md)
- 批量操作 (选择/删除/导出)
- 排序 (名称/日期/大小)
- 版本历史 (自动快照，最多 50 个版本)

### 导出
- HTML (复制 / 下载)
- PDF (系统打印)
- 另存为 .md 文件

### 体验
- 深色/浅色/跟随系统主题
- 自动保存 (可配置间隔)
- 键盘快捷键
- 响应式布局 (桌面双栏 / 移动端单栏)
- 字数统计和阅读时间

## 快速开始

```bash
# 安装依赖
flutter pub get

# 生成 Hive Adapter
flutter pub run build_runner build

# 运行 (Linux 桌面)
flutter run -d linux

# 运行 (Web)
flutter run -d chrome --web-port=4321
```

### Linux 构建依赖

```bash
sudo apt install cmake clang ninja-build pkg-config libgtk-3-dev libstdc++-14-dev lld
```

## 平台支持

| 平台 | 状态 |
|------|------|
| Linux | ✓ 完整测试 |
| macOS | ✓ 构建通过 |
| Windows | ✓ 构建通过 |
| Web | ✓ 完整测试 |
| Android | ✓ 构建通过 |
| iOS | ✓ 构建通过 |

## 快捷键

| 快捷键 | 功能 |
|--------|------|
| Ctrl+B | 加粗 |
| Ctrl+I | 斜体 |
| Ctrl+K | 插入链接 |
| Ctrl+S | 保存 |
| Ctrl+F | 查找 |
| Ctrl+H | 替换 |
| Ctrl+Z | 撤销 |
| Ctrl+Y | 重做 |
| Ctrl+Tab | 下一标签 |
| Ctrl+Shift+Tab | 上一标签 |
| Ctrl+W | 关闭标签 |
| Ctrl+滚轮 | 缩放字体 |

## 项目结构

```
lib/
├── main.dart                      # 入口
├── app.dart                       # MaterialApp 配置
├── core/                          # 基础设施
│   ├── constants/app_constants.dart
│   ├── theme/app_theme.dart
│   └── utils/                     # 导出/文件IO/下载
├── data/                          # 数据层
│   ├── models/document.dart       # Hive 数据模型
│   └── providers/app_providers.dart
├── editor/                        # 编辑器模块
│   ├── editor_screen.dart
│   ├── editor_controller.dart
│   └── widgets/
│       ├── source_code_editor.dart
│       ├── markdown_preview.dart
│       ├── toolbar.dart
│       ├── find_replace_bar.dart
│       ├── outline_panel.dart
│       ├── editor_tab_bar.dart
├── features/
│   ├── home/home_screen.dart
│   ├── settings/settings_screen.dart
│   └── file_manager/file_manager_screen.dart
└── storage/local_storage.dart
```

## 技术栈

| Package | 用途 |
|---------|------|
| re_editor + re_highlight | 代码编辑器 + 语法高亮 |
| flutter_markdown | Markdown 渲染 |
| flutter_math_fork | LaTeX 数学公式 |
| flutter_mermaid | Mermaid 图表 |
| flutter_riverpod | 状态管理 |
| hive | 本地数据库 |
| file_picker | 文件选择 |
| printing | PDF 导出 |

## 许可

MIT
