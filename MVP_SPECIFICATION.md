# MVP 功能规格说明书

## 产品定位

对标 **Obsidian** 的双栏 Markdown 编辑器。核心理念：本地优先 + 纯文本 + 双栏编辑预览。

---

## 一、功能优先级矩阵

| 优先级 | 定义 | 时间 |
|--------|------|------|
| P0 | 核心基础，无此功能产品不可用 | 第 1-3 周 |
| P1 | 1.0 版本必备，显著提升体验 | 第 3-5 周 |
| P2 | 锦上添花，可后续迭代 | 1.0 之后 |

---

## 二、P0 功能清单（MVP 核心）

### P0-1 文本编辑

| 项 | 详情 |
|----|------|
| 描述 | 支持多行 Markdown 文本输入，中文输入法兼容 |
| 技术方案 | `TextField(maxLines: null, expands: true)` + `TextEditingController` |
| 验收标准 | 输入延迟 <16ms；支持 IME 组合输入；10MB 文件滚动不卡顿 |
| 依赖 | `flutter` SDK |
| 风险 | **大文件性能** — 10MB+ 纯文本时 TextField 无虚拟滚动会严重卡顿 |
| 应对 | P0 先约束 <1MB，P2 阶段替换为 `re_editor` (有虚拟滚动) 或自研 canvas 渲染 |

**技术备注**：

```dart
// 当前方案：TextField (简单，适合 MVP)
// 缺点：无虚拟滚动、无语法高亮、无行号
// 升级路径：re_editor.CodeEditor (支持虚拟滚动 + 语法高亮 + 行号)

// 升级时机：文件大小超过 500KB 时考虑切换
// 切换成本：1-2 天（接口兼容层已设计好）
```

### P0-2 实时预览

| 项 | 详情 |
|----|------|
| 描述 | 右侧面板实时渲染 Markdown，滚动同步 |
| 技术方案 | `flutter_markdown` package，自动跟随 `currentContentProvider` 更新 |
| 验收标准 | 输入到渲染延迟 <200ms；支持 GFM 标准语法 |
| 依赖 | `flutter_markdown: ^0.6.18` |

**支持的 GFM 语法**：
- [x] 标题 (H1-H6)
- [x] 加粗 / 斜体 / 删除线
- [x] 链接 / 图片
- [x] 无序列表 / 有序列表
- [x] 引用块
- [x] 行内代码 / 代码块 (围栏)
- [x] 分割线
- [x] 表格
- [ ] 任务列表 (P1)
- [ ] 脚注 (P2)
- [ ] 数学公式 (P2)

### P0-3 工具栏

| 项 | 详情 |
|----|------|
| 描述 | 顶部工具栏，提供 Markdown 格式化的快捷按钮 |
| 技术方案 | 自定义 `EditorToolbar` Widget，通过 `EditorController` 操作文本 |
| 验收标准 | 所有按钮正确地在光标处插入/包裹对应 Markdown 语法 |
| 依赖 | `EditorController` |

**工具栏按钮列表**：

```
[撤销] [重做] | [H1] [H2] [H3] | [B] [I] [S] | [链接] [图片] [代码] |
[无序列表] [有序列表] [引用] [代码块] | [分割线] [表格]
```

**技术备注**：
- 每个按钮调用 `EditorController.wrapSelection()` 或 `insertBlockPrefix()` 或 `insertAtCursor()`
- 注意光标位置维护：插入后光标应移到合理位置（包裹文本时移到中间，块级插入时移到前缀后）

### P0-4 文件打开/保存

| 项 | 详情 |
|----|------|
| 描述 | 从本地文件系统打开 .md 文件，保存到本地文件系统 |
| 技术方案 | `file_picker` 选择文件 → `dart:io File` 读写 → `path_provider` 获取路径 |
| 验收标准 | 打开/保存对话框正确弹出；UTF-8 编码正确处理中英文 |
| 依赖 | `file_picker: ^6.1.1`, `path_provider: ^2.1.1` |

**不支持**：
- 自动保存（P1）
- 文件关联（P2）
- 最近文件列表（P1）

### P0-5 文档管理（本地 Hive 存储）

| 项 | 详情 |
|----|------|
| 描述 | 新建/删除/重命名文档，文档列表页面 |
| 技术方案 | `Hive` 作为本地数据库，存储文档元数据和内容 |
| 验收标准 | CRUD 操作正确；应用重启后数据不丢失 |
| 依赖 | `hive: ^2.2.3`, `hive_flutter: ^1.1.0` |

**数据模型**：

```dart
Document {
  id: String          // 唯一 ID (时间戳生成)
  title: String       // 文档标题
  content: String     // Markdown 内容
  createdAt: DateTime
  updatedAt: DateTime
  parentId: String?   // 文件夹 ID (P1)
  tags: List<String>  // 标签 (P2)
}
```

### P0-6 双栏/单栏切换

| 项 | 详情 |
|----|------|
| 描述 | 支持三种编辑模式：双栏 (编辑+预览)、仅编辑、仅预览 |
| 技术方案 | `EditorMode` 枚举 + `editorModeProvider` 状态管理 |
| 验收标准 | 三种模式切换无闪烁；移动端默认仅编辑模式 |

### P0-7 深色/浅色主题

| 项 | 详情 |
|----|------|
| 描述 | 支持浅色、深色、跟随系统三种主题模式 |
| 技术方案 | `flex_color_scheme` + `ThemeMode` + Riverpod |
| 验收标准 | 切换即时生效；编辑器配色跟随主题 |

---

## 三、P1 功能清单（1.0 版本必备）

| 编号 | 功能 | 技术方案 | 工作量 |
|------|------|----------|--------|
| P1-1 | **语法高亮** | `re_highlight` + CodeMirror 语法定义 | 3 天 |
| P1-2 | **行号** | `re_editor.CodeEditor` 内置行号组件 | 1 天 |
| P1-3 | **自动保存** | 监听 `currentContentProvider` 变化，debounce 2s 后写入 Hive | 1 天 |
| P1-4 | **最近文件列表** | Hive 存储最近打开记录，首页展示 | 1 天 |
| P1-5 | **导出 HTML/PDF** | `flutter_markdown` 转 HTML → `printing` package 导出 PDF | 2 天 |
| P1-6 | **查找/替换** | TextEditingController 文本搜索 + 手动定位 | 3 天 |
| P1-7 | **字体大小调节** | `editorFontSizeProvider` + Ctrl+滚轮/设置页 | 1 天 |
| P1-8 | **撤销/重做** | `UndoHistoryController` 基于 ChangeRecord 栈 | 3 天 |
| P1-9 | **移动端适配** | 底部 toolbar + Drawer 文件列表 + 单栏优先 | 5 天 |
| P1-10 | **快捷键** | `Shortcuts` + `Actions` widget 全局绑定 | 2 天 |

**P1 快捷键绑定表**：

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
| Ctrl+滚轮 | 缩放字体 |

---

## 四、P2 功能清单（1.0 之后）

| 编号 | 功能 | 备注 |
|------|------|------|
| P2-1 | 云端同步 (WebSocket) | 需自建后端，复杂度高 |
| P2-2 | 多人协作编辑 | OT/CRDT 算法 |
| P2-3 | 文件夹管理 | 树状结构 + 拖拽排序 |
| P2-4 | 标签系统 | 文档加标签 + 标签筛选 |
| P2-5 | 搜索全文 | 全文索引 + 模糊匹配 |
| P2-6 | 图片上传 (图床) | 集成阿里云 OSS / S3 |
| P2-7 | 数学公式 (KaTeX) | `flutter_math_fork` |
| P2-8 | Mermaid 流程图 | `flutter_mermaid` |
| P2-9 | 版本历史 + Diff | 存储版本快照，对比差异 |
| P2-10 | 插件系统 | 参考 Obsidian 插件架构 |
| P2-11 | 移动端触控优化 | 双指缩放预览、长按菜单、浮动工具栏 |
| P2-12 | 文件关联 (.md 默认打开) | 各平台注册文件类型 |
| P2-13 | 应用市场分发 | Google Play / App Store / 华为应用市场 |

---

## 五、项目结构手册

```
markdown_editor/
├── pubspec.yaml                  # 依赖配置
├── analysis_options.yaml         # Lint 规则
├── MVP_SPECIFICATION.md          # 本文件
│
├── lib/
│   ├── main.dart                 # 入口 → 初始化 Hive → runApp
│   ├── app.dart                  # MaterialApp 配置 (路由/主题)
│   │
│   ├── core/                     # 全局基础设施
│   │   ├── constants/
│   │   │   └── app_constants.dart  # 常量、枚举
│   │   ├── theme/
│   │   │   └── app_theme.dart      # 浅色/深色主题定义
│   │   ├── utils/                  # 工具函数 (预留)
│   │   └── extensions/             # 扩展方法 (预留)
│   │
│   ├── data/                     # 数据层
│   │   ├── models/
│   │   │   ├── document.dart       # 文档数据模型 (HiveType)
│   │   │   └── document.g.dart     # Hive Adapter (build_runner 生成)
│   │   └── providers/
│   │       └── app_providers.dart  # 全局 Riverpod Provider 定义
│   │
│   ├── editor/                   # 编辑器模块 (核心)
│   │   ├── editor_screen.dart      # 编辑器页面 (路由: /editor)
│   │   ├── editor_controller.dart  # 编辑器控制器 (文本操作)
│   │   └── widgets/
│   │       ├── source_code_editor.dart  # 编辑区 (TextField)
│   │       ├── markdown_preview.dart    # 预览区 (flutter_markdown)
│   │       └── toolbar.dart             # 工具栏 (格式化按钮)
│   │
│   ├── storage/                  # 存储模块
│   │   └── local_storage.dart      # 本地存储服务 (Hive + 文件)
│   │
│   └── features/                 # 功能页面
│       ├── home/
│       │   └── home_screen.dart     # 首页 (文档列表)
│       ├── file_manager/
│       │   └── file_manager_screen.dart  # 文件管理
│       └── settings/
│           └── settings_screen.dart      # 设置页面
│
├── test/                         # 单元测试 (待添加)
└── assets/
    └── icons/                    # 图标资源 (预留)
```

## 六、数据流架构

```
用户输入 TextField
      │
      ▼
onChanged → currentContentProvider (Riverpod StateProvider)
      │
      ├──→ SourceCodeEditor (编辑区回显)
      │
      ├──→ MarkdownPreview (flutter_markdown 渲染)
      │
      ├──→ StatusBar (行数/字数统计)
      │
      └──→ EditorController (工具栏操作)
                │
                ├── wrapSelection()     → 更新 TextEditingController
                ├── insertBlockPrefix() → 更新 TextEditingController
                └── insertAtCursor()    → 更新 TextEditingController
                          │
                          ▼
                   currentContentProvider 更新
                          │
                          ▼
                    所有监听者重新 build
```

**关键设计原则**：

1. **单一数据源**：`currentContentProvider` 是编辑内容的唯一权威来源
2. **双向同步**：TextField ↔ Provider 之间保持同步（见 `source_code_editor.dart` 中的 `if (tc.text != content)` 同步逻辑）
3. **编辑器操作通过 Controller**：所有文本修改（工具栏按钮）通过 `EditorController` 统一处理，保证光标位置正确维护

## 七、依赖版本说明

| Package | 版本 | 用途 | 风险等级 |
|---------|------|------|----------|
| `flutter_markdown` | ^0.6.18 | Markdown 渲染 | 低 — 成熟稳定 |
| `hive` / `hive_flutter` | ^2.2.3 / ^1.1.0 | 本地数据库 | 低 — 成熟稳定 |
| `flutter_riverpod` | ^2.4.9 | 状态管理 | 低 — 成熟稳定 |
| `flex_color_scheme` | ^7.0.0 | 主题配色 | 低 |
| `re_editor` | ^0.6.1 | 代码编辑器 (P1 启用) | 中 — 更新频繁 |
| `file_picker` | ^6.1.1 | 文件选择对话框 | 中 — 平台差异 |

## 八、开发环境搭建手册

### 前置条件

```bash
# 1. 安装 Flutter SDK (Stable)
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# 2. 验证环境
flutter doctor
# 确保以下勾选：
#   [✓] Flutter
#   [✓] Android toolchain
#   [✓] Chrome (Web 调试用)
#   [✓] Linux desktop (开发阶段最方便)
#   [ ] Android Studio / VS Code (至少一个)

# 3. 启用桌面支持
flutter config --enable-linux-desktop
flutter config --enable-windows-desktop
flutter config --enable-macos-desktop  # 仅 macOS

# 4. 获取依赖
cd markdown_editor
flutter pub get

# 5. 生成 Hive Adapter
flutter pub run build_runner build

# 6. 运行 (桌面端最快，开发阶段推荐)
flutter run -d linux
```

### 推荐 IDE 配置

| IDE | 插件 | 适用场景 |
|-----|------|----------|
| VS Code | Flutter, Dart,  | 轻量开发 |
| Android Studio | Flutter (自带) | 全功能，Android/iOS 调试 |

### 开发工作流

```
1. 修改代码
2. flutter run -d linux (hot reload 自动生效)
3. 按 r 热重载 / 按 R 热重启
4. flutter test 运行单元测试
```

---

## 九、开发阶段与里程碑

```
Week 1 ─── P0-1~3  ─── 编辑器可输入、预览、toolbar 可用
Week 2 ─── P0-4~7  ─── 文件读写、文档管理、主题切换
Week 3 ─── 整合测试 ─── P0 全功能联调 + Bug 修复
           🎯 Milestone 1: MVP 可跑 (纯编辑+预览+保存)
---
Week 4 ─── P1-1~4  ─── 语法高亮、行号、自动保存、最近文件
Week 5 ─── P1-5~8  ─── 导出、查找替换、字体缩放、撤销重做
Week 6 ─── P1-9~10 ─── 移动端适配、快捷键
           🎯 Milestone 2: 1.0 版本 (可用产品)
---
Beyond ── P2 系列  ─── 云端同步、协作、插件系统...
```

---

## 十、代码规范

### 命名约定

| 类型 | 风格 | 示例 |
|------|------|------|
| 文件名 | snake_case | `source_code_editor.dart` |
| 类名 | PascalCase | `SourceCodeEditor` |
| 变量/方法 | camelCase | `insertBlockPrefix()` |
| 常量 | camelCase | `maxFileSizeBytes` |
| Provider | camelCase + Provider 后缀 | `editorModeProvider` |
| 私有成员 | _前缀 | `_findLineStart()` |

### Widget 规范

- 优先 `const` 构造
- `ConsumerWidget`：不需要 state → 直接读 ref
- `ConsumerStatefulWidget`：需要 initState/dispose → 用 ref.read/watch
- 无状态的显示组件抽取为独立 Widget 类
