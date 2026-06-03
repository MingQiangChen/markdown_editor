# Flutter跨平台Markdown编辑器开发计划

## 🎯 项目概述

**项目名称**：（待定）
**目标平台**：Windows / macOS / Linux / iOS / Android / HarmonyOS / Web
**核心功能**：Markdown编辑 + 云端同步 + 多设备协作

---

## 📋 开发阶段规划

### 阶段一：环境搭建（3-5天）

#### 1.1 开发工具安装

```bash
# 安装Flutter SDK（Stable分支）
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# 或使用官方安装包
# 下载地址：https://docs.flutter.dev/get-started/install

# 检查环境
flutter doctor
```

#### 1.2 IDE选择

**推荐**：
- **Android Studio**（全功能，推荐新手）
- **VS Code** + Flutter插件（轻量）
- **IntelliJ IDEA** + Flutter插件

#### 1.3 设备准备

| 平台 | 模拟器/真机 | 备注 |
|------|-------------|------|
| Android | Android Studio AVD / 真机 | 开启USB调试 |
| iOS | Xcode Simulator / 真机 | 需要Mac |
| HarmonyOS | DevEco Studio / 真机 | 华为开发者 |
| Windows | 直接运行 | Flutter桌面支持 |
| macOS | Xcode | 需要Mac |
| Linux | 直接运行 | Flutter桌面支持 |

#### 1.4 启用桌面支持

```bash
# Windows
flutter config --enable-windows-desktop

# macOS
flutter config --enable-macos-desktop

# Linux
flutter config --enable-linux-desktop
```

---

### 阶段二：项目初始化（2-3天）

#### 2.1 创建项目

```bash
# 创建项目
flutter create --org com.yourcompany --project-name markdown_editor markdown_editor

# 进入目录
cd markdown_editor

# 获取依赖
flutter pub get
```

#### 2.2 配置依赖（pubspec.yaml）

```yaml
dependencies:
  flutter:
    sdk: flutter

  # 编辑器核心
  flutter_markdown: ^0.6.18         # Markdown渲染
  markdown: ^7.1.1                   # Markdown解析
  
  # 编辑功能
  re_editor: ^0.6.1                 # 代码编辑器
  re_highlight: ^0.2.0              # 语法高亮
  
  # UI组件
  flex_color_scheme: ^7.0.0        # 主题
  google_fonts: ^6.1.0              # 字体
  
  # 状态管理
  flutter_riverpod: ^2.4.9          # 状态管理（推荐）
  riverpod_annotation: ^2.3.3
  
  # 本地存储
  hive: ^2.2.3                      # 轻量数据库
  hive_flutter: ^1.1.0
  path_provider: ^2.1.1             # 文件路径
  
  # 网络同步
  dio: ^5.3.3                       # HTTP客户端
  web_socket_channel: ^2.4.0        # WebSocket（实时同步）
  
  # 工具
  uuid: ^4.2.1                      # 生成唯一ID
  intl: ^0.18.1                     # 国际化
  share_plus: ^7.2.1               # 分享功能
  file_picker: ^6.1.1               # 文件选择
  
  # 平台适配
  flutter_localizations:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  build_runner: ^2.4.7
  hive_generator: ^2.0.1
  riverpod_generator: ^2.3.9
```

#### 2.3 项目结构

```
lib/
├── main.dart                      # 入口文件
├── app.dart                       # App配置
├── 
│   core/                          # 核心模块
│   │   ├── constants/             # 常量
│   │   ├── theme/                 # 主题
│   │   ├── utils/                 # 工具类
│   │   └── extensions/            # 扩展
│   │
│   ├── data/                      # 数据层
│   │   ├── models/                # 数据模型
│   │   ├── repositories/          # 仓库
│   │   ├── providers/             # Riverpod Providers
│   │   └── services/              # 服务
│   │
│   ├── domain/                    # 业务逻辑层
│   │   ├── entities/              # 实体
│   │   └── usecases/              # 用例
│   │
│   └── presentation/              # 展示层
│       ├── screens/               # 页面
│       ├── widgets/               # 组件
│       └── controllers/           # 控制器
│
├── editor/                        # 编辑器模块
│   ├── editor_screen.dart         # 编辑器页面
│   ├── editor_controller.dart     # 编辑器控制器
│   ├── widgets/
│   │   ├── markdown_editor.dart   # 编辑器组件
│   │   ├── markdown_preview.dart   # 预览组件
│   │   ├── toolbar.dart           # 工具栏
│   │   └── line_numbers.dart     # 行号
│   └── syntax/
│       └── markdown_syntax.dart   # Markdown语法
│
├── sync/                          # 同步模块
│   ├── sync_service.dart          # 同步服务
│   ├── conflict_resolver.dart     # 冲突解决
│   └── websocket_client.dart      # WebSocket客户端
│
├── storage/                       # 存储模块
│   ├── local_storage.dart         # 本地存储
│   ├── file_storage.dart          # 文件存储
│   └── database.dart              # 数据库
│
└── features/                      # 功能模块
    ├── home/                      # 首页
    ├── file_manager/              # 文件管理
    ├── settings/                  # 设置
    ├── account/                   # 账户
    └── export/                    # 导出
```

---

### 阶段三：核心功能开发（2-3周）

#### 3.1 Markdown编辑器核心

**功能列表**：
- [ ] 文本编辑（支持大文件）
- [ ] 语法高亮
- [ ] 自动补全
- [ ] 快捷键支持
- [ ] 撤销/重做
- [ ] 查找/替换

**关键组件**：

```dart
// lib/editor/widgets/markdown_editor.dart
import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class MarkdownEditor extends StatefulWidget {
  final String initialText;
  final ValueChanged<String> onChanged;
  final bool showPreview;
  
  const MarkdownEditor({
    super.key,
    this.initialText = '',
    required this.onChanged,
    this.showPreview = true,
  });
  
  @override
  State<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor> {
  late CodeLineEditingController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = CodeLineEditingController.fromText(widget.initialText);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 编辑器
        Expanded(
          child: CodeEditor(
            controller: _controller,
            style: _editorStyle(),
            indicatorBuilder: (context, editingController, chunkController, notifier) {
              return Row(
                children: [
                  LineNumber(
                    controller: editingController,
                    notifier: notifier,
                  ),
                ],
              );
            },
          ),
        ),
        
        // 预览
        if (widget.showPreview) ...[
          const VerticalDivider(width: 1),
          Expanded(
            child: Markdown(
              data: _controller.text,
              selectable: true,
            ),
          ),
        ],
      ],
    );
  }
  
  CodeEditorStyle _editorStyle() {
    return CodeEditorStyle(
      fontSize: 14,
      fontFamily: 'JetBrains Mono', // 或使用 google_fonts
      codeTheme: CodeHighlightTheme(
        languages: {
          'markdown': CodeHighlightThemeMode(mode: 'markdown'),
        },
        theme: CodeHighlightThemeCodexTheme(),
      ),
    );
  }
}
```

#### 3.2 工具栏

**功能列表**：
- [ ] 标题（1-6级）
- [ ] 加粗、斜体、删除线
- [ ] 插入链接、图片
- [ ] 代码块、行内代码
- [ ] 列表（有序、无序）
- [ ] 引用块
- [ ] 表格
- [ ] 分割线
- [ ] 撤销/重做

```dart
// lib/editor/widgets/editor_toolbar.dart
class EditorToolbar extends StatelessWidget {
  final CodeLineEditingController controller;
  final VoidCallback? onInsertText;
  
  const EditorToolbar({
    super.key,
    required this.controller,
    this.onInsertText,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Wrap(
        spacing: 4,
        children: [
          _ToolbarButton(
            icon: Icons.format_bold,
            tooltip: '加粗 (Ctrl+B)',
            onPressed: () => _insertMarkdown('**', '**'),
          ),
          _ToolbarButton(
            icon: Icons.format_italic,
            tooltip: '斜体 (Ctrl+I)',
            onPressed: () => _insertMarkdown('*', '*'),
          ),
          _ToolbarButton(
            icon: Icons.link,
            tooltip: '链接 (Ctrl+K)',
            onPressed: () => _insertMarkdown('[', '](url)'),
          ),
          // ... 更多按钮
        ],
      ),
    );
  }
  
  void _insertMarkdown(String prefix, String suffix) {
    final selection = controller.selection;
    final text = controller.text;
    final selectedText = text.substring(selection.start, selection.end);
    
    final newText = '$prefix$selectedText$suffix';
    controller.replaceText(
      selection.start,
      selection.end - selection.start,
      newText,
    );
    
    onInsertText?.call();
  }
}
```

#### 3.3 文件管理

**功能列表**：
- [ ] 新建文件
- [ ] 打开文件（.md）
- [ ] 保存文件
- [ ] 文件夹管理
- [ ] 最近文件
- [ ] 收藏夹
- [ ] 搜索文件

#### 3.4 本地存储

**使用Hive数据库**：

```dart
// lib/storage/database.dart
import 'package:hive_flutter/hive_flutter.dart';

class DocumentDatabase {
  static const String _boxName = 'documents';
  
  late Box<Map> _box;
  
  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<Map>(_boxName);
  }
  
  // 保存文档
  Future<void> saveDocument(Document doc) async {
    await _box.put(doc.id, doc.toJson());
  }
  
  // 获取文档
  Document? getDocument(String id) {
    final data = _box.get(id);
    return data != null ? Document.fromJson(Map<String, dynamic>.from(data)) : null;
  }
  
  // 获取所有文档
  List<Document> getAllDocuments() {
    return _box.values
        .map((data) => Document.fromJson(Map<String, dynamic>.from(data)))
        .toList();
  }
  
  // 删除文档
  Future<void> deleteDocument(String id) async {
    await _box.delete(id);
  }
}
```

---

### 阶段四：云端同步（2-3周）

#### 4.1 同步架构

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Flutter   │────▶│  WebSocket  │────▶│   Server    │
│   App       │◀────│   Client    │◀────│   (Node.js) │
└─────────────┘     └─────────────┘     └─────────────┘
                                                │
                                                ▼
                                         ┌─────────────┐
                                         │ PostgreSQL  │
                                         │   (数据库)   │
                                         └─────────────┘
```

#### 4.2 同步协议设计

**文档结构**：

```dart
// lib/data/models/document.dart
class Document {
  final String id;           // 唯一ID
  final String title;         // 标题
  final String content;       // Markdown内容
  final String contentHash;   // 内容哈希（用于冲突检测）
  final DateTime createdAt;   // 创建时间
  final DateTime updatedAt;   // 更新时间
  final int version;          // 版本号
  final String? parentId;     // 父文档ID（文件夹）
  final List<String> tags;    // 标签
  final bool isDeleted;       // 是否删除（软删除）
}
```

**同步消息格式**：

```json
{
  "type": "sync",
  "action": "update",  // create, update, delete
  "documentId": "doc_123",
  "version": 5,
  "content": "# 文档内容",
  "contentHash": "sha256:abc123",
  "timestamp": 1706745600000
}
```

#### 4.3 冲突解决策略

**方案：Last-Write-Wins + 版本历史**

```dart
// lib/sync/conflict_resolver.dart
enum ConflictStrategy {
  lastWriteWins,      // 以最新为准
  keepBoth,           // 保留两个版本
  manual,             // 手动选择
}

class ConflictResolver {
  final ConflictStrategy strategy;
  
  Document resolve(Document local, Document remote) {
    if (local.version >= remote.version) {
      return local; // 本地更新，保留本地
    }
    
    if (local.contentHash == remote.contentHash) {
      return remote; // 内容相同，保留远程
    }
    
    // 内容冲突
    switch (strategy) {
      case ConflictStrategy.lastWriteWins:
        return remote;
      case ConflictStrategy.keepBoth:
        return _keepBoth(local, remote);
      case ConflictStrategy.manual:
        throw ConflictException(local, remote);
    }
  }
}
```

#### 4.4 后端API设计

**使用NestJS + PostgreSQL**：

```typescript
// server/src/documents/document.entity.ts
@Entity('documents')
export class Document {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  title: string;

  @Column('text')
  content: string;

  @Column()
  contentHash: string;

  @Column({ type: 'timestamp' })
  createdAt: Date;

  @Column({ type: 'timestamp' })
  updatedAt: Date;

  @Column({ default: 1 })
  version: number;

  @Column({ nullable: true })
  parentId: string;

  @Column('simple-array')
  tags: string[];

  @Column({ default: false })
  isDeleted: boolean;
  
  @ManyToOne(() => User)
  @JoinColumn({ name: 'userId' })
  user: User;
}
```

**API端点**：

| 方法 | 端点 | 描述 |
|------|------|------|
| POST | /api/documents | 创建文档 |
| GET | /api/documents | 获取文档列表 |
| GET | /api/documents/:id | 获取单个文档 |
| PUT | /api/documents/:id | 更新文档 |
| DELETE | /api/documents/:id | 删除文档 |
| GET | /api/documents/:id/versions | 获取版本历史 |
| POST | /api/documents/:id/sync | 同步文档 |
| WS | /ws/sync | WebSocket实时同步 |

---

### 阶段五：发布与上架（1-2周）

#### 5.1 各平台打包

```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS (需要Mac)
flutter build ios --release

# HarmonyOS (华为)
flutter build hap --release

# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release

# Web
flutter build web
```

#### 5.2 应用市场上架

| 平台 | 应用市场 | 备注 |
|------|---------|------|
| Android | Google Play / 应用宝 / 华为应用市场 | 需要签名 |
| iOS | App Store | 需要开发者账号（$99/年） |
| HarmonyOS | 华为应用市场 | 需要华为开发者账号 |

---

## 📊 开发时间预估

| 阶段 | 内容 | 时间 |
|------|------|------|
| 环境搭建 | Flutter安装、IDE配置 | 3-5天 |
| 项目初始化 | 项目创建、依赖配置 | 2-3天 |
| 核心功能 | 编辑器、工具栏、文件管理 | 2-3周 |
| 云端同步 | 后端开发、同步功能 | 2-3周 |
| 测试优化 | Bug修复、性能优化 | 1-2周 |
| 发布上架 | 各平台打包、上架 | 1-2周 |

**总计**：约 **6-10周** 可完成MVP版本

---

## 🎓 学习资源

### 官方文档
- Flutter官网：https://flutter.dev/
- Flutter中文网：https://flutter.cn/
- Dart语言：https://dart.dev/

### 状态管理
- Riverpod：https://riverpod.dev/
- Riverpod中文：https://riverpod.cn/

### 编辑器相关
- flutter_markdown：https://pub.dev/packages/flutter_markdown
- re_editor：https://pub.dev/packages/re_editor

### 后端相关
- NestJS：https://nestjs.com/
- PostgreSQL：https://www.postgresql.org/

---

## ⚠️ 注意事项

1. **大文档性能**：Flutter默认编辑器对大文档（>10MB）支持有限，需要做虚拟滚动优化

2. **移动端触控**：移动端编辑体验不如桌面端，考虑添加：
   - 快捷工具栏浮动
   - 双指缩放预览
   - 长按弹出菜单

3. **HarmonyOS兼容性**：Flutter对HarmonyOS的支持还有改进空间，部分插件可能不兼容

4. **iOS审核**：App Store审核较严格，隐私政策、权限说明要完善

---

**下一步建议**：
1. 安装Flutter开发环境
2. 创建项目骨架
3. 实现基础编辑器功能

需要我帮你创建项目脚手架代码吗？🚀
