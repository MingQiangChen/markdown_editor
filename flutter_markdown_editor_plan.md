# Flutter 跨平台 Markdown 编辑器 — 开发计划

> **项目状态**: v0.1.0 开发中。MVP 已完成，P1/P2 功能大部分已实现。
> 
> **技术栈**: Flutter 3.38 + Dart 3.10 + Riverpod + Hive + re_editor

---

## 已完成里程碑

| 里程碑 | 内容 | 状态 |
|--------|------|------|
| M1 — MVP | 编辑/预览/保存/主题/双栏 | ✅ |
| M2 — 1.0 核心 | 语法高亮/行号/自动保存/导出/查找替换/快捷键 | ✅ |
| M3 — 增强 | 文件夹/标签/数学公式/Mermaid/版本历史 | ✅ |
| M4 — 编辑体验 | 多标签页/大纲面板/代码高亮/文件管理器/GFM任务列表 | ✅ |

## 待开发

| 优先级 | 功能 |
|--------|------|
| 高 | 图片粘贴、标签页会话恢复、全文搜索、文件关联 |
| 中 | 脚注、专注模式、嵌套文件夹、表格编辑器、最近文件 |
| 低 | 云端同步、协作编辑、插件系统、PWA |

## 技术决策记录

| 决策 | 日期 | 方案 | 原因 |
|------|------|------|------|
| 跨平台框架 | — | Flutter | 一套代码覆盖 7 个平台 |
| 编辑器 | — | re_editor | 虚拟滚动 + 语法高亮 + 行号，替代 TextField |
| 状态管理 | — | Riverpod | 编译时安全，比 Provider 更现代的 API |
| 本地存储 | — | Hive | 纯 Dart 实现，跨平台一致，无需原生配置 |
| 预览渲染 | — | flutter_markdown | 原生 Flutter Widget，无需 WebView |
| Preview 语法高亮 | 2026-06 | re_highlight TextSpanRenderer | 复用编辑器已有的 re_highlight，无需新增依赖 |

## 历史 (2024-2025)

初期探索了 Vue + Electron 方案（见 `markdown_editor_comparison.md` 和旧版 `markdown_editor_checklist.md`），后因跨平台需求全面转向 Flutter。
