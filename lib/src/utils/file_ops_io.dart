import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart' as path_provider;

Future<Uint8List> readFileBytes(Object file) async {
  if (file is String) {
    return readPathBytes(file);
  }
  if (file is File) {
    return file.readAsBytes();
  }
  throw ArgumentError('Expected dart:io File or file path.');
}

Future<Uint8List> readPathBytes(String path) async {
  return File(path).readAsBytes();
}

String? filePathFromObject(Object? file) {
  if (file is File) {
    return file.path;
  }
  if (file is String) {
    return file;
  }
  return null;
}

Future<String?> getDirectory() async {
  if (Platform.isIOS || Platform.isAndroid) {
    return (await path_provider.getApplicationDocumentsDirectory()).path;
  }
  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    return (await path_provider.getDownloadsDirectory())?.path;
  }
  return null;
}

Future<String> copyFileToDirectory({
  required Object file,
  required String name,
  required String fileExtension,
}) async {
  final source = file is String ? File(file) : file;
  if (source is! File) {
    throw ArgumentError('Expected dart:io File or file path.');
  }
  final directory = await getDirectory();
  if (directory == null) {
    throw StateError('Downloads directory is unavailable.');
  }
  return (await source.copy('$directory/$name$fileExtension')).path;
}

Future<String> writeStreamToTempFile({
  required Stream<List<int>> stream,
  required String extension,
}) async {
  final file = File(
    '${Directory.systemTemp.path}/file_saver_${DateTime.now().microsecondsSinceEpoch}$extension',
  );
  await stream.pipe(file.openWrite());
  return file.path;
}

Future<void> deleteFile(String path) async {
  final file = File(path);
  if (await file.exists()) {
    await file.delete();
  }
}
