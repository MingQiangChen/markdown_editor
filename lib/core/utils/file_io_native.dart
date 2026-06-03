import 'dart:convert';
import 'dart:io';

String readFileAsString(String path) {
  final file = File(path);
  return file.readAsStringSync(encoding: utf8);
}

void writeStringToFile(String path, String content) {
  final file = File(path);
  file.writeAsStringSync(content, encoding: utf8);
}
