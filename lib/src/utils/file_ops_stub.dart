import 'dart:typed_data';

Future<Uint8List> readFileBytes(Object file) {
  throw UnsupportedError(
    'File objects are only supported on native platforms.',
  );
}

Future<Uint8List> readPathBytes(String path) {
  throw UnsupportedError('File paths are only supported on native platforms.');
}

String? filePathFromObject(Object? file) => null;

Future<String?> getDirectory() {
  throw UnsupportedError('Directories are only supported on native platforms.');
}

Future<String> copyFileToDirectory({
  required Object file,
  required String name,
  required String fileExtension,
}) {
  throw UnsupportedError('File copying is only supported on native platforms.');
}

Future<String> writeStreamToTempFile({
  required Stream<List<int>> stream,
  required String extension,
}) {
  throw UnsupportedError(
    'Temporary files are only supported on native platforms.',
  );
}

Future<void> deleteFile(String path) async {}
