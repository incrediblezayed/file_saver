class GeneratedTestFile {
  const GeneratedTestFile({required this.path, required this.sizeMb});

  final String path;
  final int sizeMb;
}

const bool supportsFilePathTests = false;
const String filePathUnsupportedMessage =
    'Browser web apps cannot read a real local file path. Use bytes/link tests on web, or run Android/iOS/macOS/Windows/Linux for filePath tests.';

Future<String?> pickFilePath() async {
  throw UnsupportedError(filePathUnsupportedMessage);
}

Future<GeneratedTestFile> createLargeTestFile({required int sizeMb}) async {
  throw UnsupportedError(filePathUnsupportedMessage);
}
