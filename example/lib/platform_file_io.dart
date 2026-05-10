import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

class GeneratedTestFile {
  const GeneratedTestFile({required this.path, required this.sizeMb});

  final String path;
  final int sizeMb;
}

const bool supportsFilePathTests = true;
const String filePathUnsupportedMessage = '';

Future<String?> pickFilePath() async {
  final result = await FilePicker.platform.pickFiles(withData: false);
  return result?.files.single.path;
}

Future<GeneratedTestFile> createLargeTestFile({required int sizeMb}) async {
  final safeSizeMb = sizeMb.clamp(1, 512);
  final file = File(
    '${Directory.systemTemp.path}/file_saver_large_${DateTime.now().millisecondsSinceEpoch}.bin',
  );
  final sink = file.openWrite();
  final chunk = Uint8List(1024 * 1024);
  for (var i = 0; i < chunk.length; i++) {
    chunk[i] = i % 251;
  }
  for (var i = 0; i < safeSizeMb; i++) {
    sink.add(chunk);
  }
  await sink.close();
  return GeneratedTestFile(path: file.path, sizeMb: safeSizeMb);
}
