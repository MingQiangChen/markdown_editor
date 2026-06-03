# Markdown编辑器技术选型对比

## 1. CodeMirror 6

### 优点
- 性能优秀（虚拟滚动）
- 高度可定制
- 语法高亮强大
- 支持多种语言

### 缺点
- 学习曲线较陡
- 需要自己实现Markdown工具栏

### 适用场景
- 需要高度定制化的编辑器
- 对性能有高要求

### GitHub
https://github.com/codemirror/dev

---

## 2. Toast UI Editor

### 优点
- 功能开箱即用
- 支持WYSIWYG模式
- 中文文档友好
- 工具栏完善

### 缺点
- 打包体积较大
- 性能不如CodeMirror

### 适用场景
- 快速开发
- 需要所见即所得模式

### GitHub
https://github.com/nhn/tui.editor

---

## 3. Milkdown

### 优点
- 现代化架构
- 插件化设计
- 基于ProseMirror
- TypeScript友好

### 缺点
- 相对较新，生态不够成熟
- 文档不够完善

### 适用场景
- 现代化项目
- 需要插件化扩展

### GitHub
https://github.com/Milkdown/milkdown

---

## 4. Vditor

### 优点
- 国产开源
- 功能完善
- 支持数学公式、流程图、甘特图
- 中文文档友好

### 缺点
- 社区相对较小

### 适用场景
- 中文用户为主的项目
- 需要丰富的图表支持

### GitHub
https://github.com/Vanessa219/vditor

---

## 5. ByteMD

### 优点
- 字节跳动开源
- 插件化架构
- 轻量（~50KB）
- TypeScript友好

### 缺点
- 插件生态较少

### 适用场景
- 轻量级编辑器
- 需要插件化扩展

### GitHub
https://github.com/bytedance/bytemd

---

## 推荐方案

### 快速开发 → Toast UI Editor / Vditor
### 高度定制 → CodeMirror 6 / Milkdown
### 轻量级 → ByteMD

## 我的建议

如果你是第一次开发Markdown编辑器，推荐：
- **Vditor**（功能完善，中文友好）
- 或 **Toast UI Editor**（功能丰富，开箱即用）

如果对性能和定制性有高要求：
- **CodeMirror 6**（性能最强，可定制性最高）
