// Stub — dart:io file operations are not supported on web.
String readFileAsString(String path) =>
    throw UnsupportedError('File I/O not available on web');

void writeStringToFile(String path, String content) =>
    throw UnsupportedError('File I/O not available on web');
