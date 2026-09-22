import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/messages.g.dart',
    kotlinOut:
        'android/src/main/kotlin/com/incrediblezayed/file_saver/Messages.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.incrediblezayed.file_saver'),
    // Copied to macos/file_saver/Sources/file_saver/ by tool/pigeon.sh.
    swiftOut: 'ios/file_saver/Sources/file_saver/Messages.g.swift',
    cppHeaderOut: 'windows/messages.g.h',
    cppSourceOut: 'windows/messages.g.cpp',
    cppOptions: CppOptions(namespace: 'file_saver'),
  ),
)
/// Everything a native save needs. `bytes` or `sourcePath` is set, not both.
class SaveRequest {
  SaveRequest({
    required this.name,
    this.bytes,
    this.sourcePath,
    required this.fileExtension,
    required this.includeExtension,
    required this.mimeType,
    this.initialDirectory,
    this.dialogTitle,
    this.folder,
  });

  String name;
  Uint8List? bytes;
  String? sourcePath;
  String fileExtension;
  bool includeExtension;
  String mimeType;
  String? initialDirectory;
  String? dialogTitle;

  /// Album for saveToGallery, subfolder for saveToDownloads.
  String? folder;
}

class DownloadRequest {
  DownloadRequest({required this.url, this.name, this.headers});

  String url;
  String? name;
  Map<String, String>? headers;
}

@HostApi()
abstract class FileSaverHostApi {
  /// Writes to app storage without a dialog. Android only.
  @async
  String? saveFile(SaveRequest request);

  /// Shows the platform save dialog; null when the user cancels.
  @async
  String? saveAs(SaveRequest request);

  /// Adds an image or video to the photo library. Android and iOS only.
  @async
  String? saveToGallery(SaveRequest request);

  /// Writes into the shared Downloads folder without a dialog. Android only;
  /// the other platforms handle it in Dart.
  @async
  String? saveToDownloads(SaveRequest request);

  /// Hands a URL to the system downloader. Android only.
  String downloadLink(DownloadRequest request);
}
