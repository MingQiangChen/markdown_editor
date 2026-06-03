import 'dart:html' as html;

void downloadFile(String content, String fileName, String mimeType) {
  final blob = html.Blob([content], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.document.createElement('a') as html.AnchorElement;
  anchor.href = url;
  anchor.download = fileName;
  anchor.click();
  html.Url.revokeObjectUrl(url);
}
