import 'package:markdown/markdown.dart' as md;

class ExportUtils {
  ExportUtils._();

  /// 将 Markdown 转换为完整的 HTML 文档
  static String markdownToHtmlDocument(String markdown, String title) {
    final bodyHtml = md.markdownToHtml(markdown);
    return '''
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$title</title>
  <style>
    body {
      max-width: 800px;
      margin: 0 auto;
      padding: 2rem;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      font-size: 16px;
      line-height: 1.7;
      color: #333;
      background: #fff;
    }
    @media (prefers-color-scheme: dark) {
      body { color: #ddd; background: #1a1a2e; }
    }
    h1 { font-size: 2em; border-bottom: 2px solid #6C63FF; padding-bottom: 0.3em; }
    h2 { font-size: 1.5em; border-bottom: 1px solid #e0e0e0; padding-bottom: 0.2em; }
    h3 { font-size: 1.25em; }
    code {
      background: #f0f0f0;
      padding: 2px 6px;
      border-radius: 3px;
      font-family: 'JetBrains Mono', monospace;
      font-size: 0.9em;
    }
    pre {
      background: #f5f5f5;
      padding: 1rem;
      border-radius: 6px;
      overflow-x: auto;
    }
    pre code { background: none; padding: 0; }
    blockquote {
      border-left: 4px solid #6C63FF;
      margin: 0;
      padding: 0.5rem 1rem;
      color: #666;
      background: #f9f9ff;
    }
    table { border-collapse: collapse; width: 100%; }
    th, td { border: 1px solid #ddd; padding: 8px 12px; text-align: left; }
    th { background: #f5f5f5; }
    img { max-width: 100%; }
    hr { border: none; border-top: 2px solid #e0e0e0; margin: 2rem 0; }
    a { color: #6C63FF; }
  </style>
</head>
<body>
$bodyHtml
</body>
</html>''';
  }
}
