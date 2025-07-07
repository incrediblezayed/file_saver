import 'package:collection/collection.dart';

///[MimeType] is an enum for adding filetype for HTML Blob
enum MimeType {
  ///[aac] for .aac extension
  aac(
    name: 'AAC',
    type: 'audio/aac',
  ),

  ///[apng] for .apng extension
  apng(name: 'APNG', type: 'image/apng'),

  ///[asice] for .asice
  asice(name: 'ASICE', type: 'application/vnd.etsi.asic-e+zip'),

  ///[asics] for .asice
  asics(
    name: 'ASICS',
    type: 'application/vnd.etsi.asic-s+zip',
  ),

  ///[avi] for .avi extension
  avi(name: 'AVI', type: 'video/x-msvideo'),

  ///[avif] for .avif extension
  avif(name: 'AVIF', type: 'image/avif'),

  ///[bDoc] for .asice
  bDoc(
    name: 'BDoc',
    type: 'application/vnd.etsi.asic-e+zip',
  ),

  ///[bmp] for .bmp extension
  bmp(name: 'Bitmap', type: 'image/bmp'),

  ///[csv] for .csv extension
  csv(
    name: 'CSV',
    type: 'text/csv',
  ),

  ///[epub] for .epub extention
  epub(name: 'Epub', type: 'application/epub+zip'),

  ///[gif] for .gif extension
  gif(name: 'GIF', type: 'image/gif'),

  ///[heic] for .heic extension
  heic(name: 'HEIC', type: 'image/heic'),

  ///[heif] for .heif extension
  heif(name: 'HEIF', type: 'image/heif'),

  ///[jpeg] for .jpeg extension
  jpeg(name: 'JPEG', type: 'image/jpeg'),

  ///[json] for .json extension
  json(name: 'JSON', type: 'application/json'),

  ///[markdown] for .md extension
  markdown(name: 'Markdown', type: 'text/markdown'),

  ///[microsoftExcel] for .xlsx extension
  microsoftExcel(
    name: 'Microsoft Excel',
    type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  ),

  ///[microsoftPresentation] for .pptx extension
  microsoftPresentation(
      name: 'Microsoft Presentation',
      type:
          'application/vnd.openxmlformats-officedocument.presentationml.presentation'),

  ///[microsoftWord] for .docx extension
  microsoftWord(
      name: 'Microsoft Word',
      type:
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document'),

  ///[mp3] for .mp3 extension
  mp3(name: 'MP3', type: 'audio/mpeg'),

  /// [mp4Audio] for .mp4 extension for audio files
  mp4Audio(name: 'MP4 Audio', type: 'audio/mp4'),

  /// [mp4Object] for .mp4 extension for other media files with mp4 extension
  mp4Object(name: 'MP4 Object', type: 'application/mp4'),

  /// [mp4Video] for .mp4 extension for video files
  mp4Video(name: 'MP4 Video', type: 'video/mp4'),

  ///[mpeg] for .mpeg extension
  mpeg(name: 'MPEG', type: 'video/mpeg'),

  ///[openDocPresentation] for .odp extension
  openDocPresentation(
    name: 'Open Document Presentation',
    type: 'application/vnd.oasis.opendocument.presentation',
  ),

  ///[openDocSheets] for .ods extension
  openDocSheets(
    name: 'Open Document Sheets',
    type: 'application/vnd.oasis.opendocument.spreadsheet',
  ),

  ///[openDocText] for .odt extension
  openDocText(
      name: 'Open Document Text',
      type: 'application/vnd.oasis.opendocument.text'),

  ///[otf] for .otf extension
  otf(name: 'OTF', type: 'font/otf'),

  ///[other] for other extension
  other(name: 'Other', type: 'application/octet-stream'),

  ///[pdf] for .pdf extension
  pdf(
    name: 'PDF',
    type: 'application/pdf',
  ),

  ///[png] for .png extension
  png(name: 'PNG', type: 'image/png'),

  ///[rar] for .rar extension
  rar(
    name: 'RAR',
    type: 'application/x-rar-compressed',
  ),

  ///[sql] for .sql extension
  sql(name: 'SQL', type: 'application/sql'),

  ///[svg] for .svg extension
  svg(name: 'SVG', type: 'image/svg+xml'),

  ///[text] for .txt extension
  text(name: 'Text', type: 'text/plain'),

  ///[ttf] for .ttf extension
  ttf(name: 'TTF', type: 'font/ttf'),

  ///[webm] for .webm extension
  webm(name: 'WebM', type: 'video/webm'),

  ///[webp] for .webp extension
  webp(name: 'WebP', type: 'image/webp'),

  ///[xml] for .xml extension
  xml(name: 'XML', type: 'application/xml'),

  ///[yaml] for .yaml extension
  yaml(name: 'YAML', type: 'application/x-yaml'),

  ///[zip] for .zip extension
  zip(
    name: 'ZIP',
    type: 'application/zip',
  ),

  ///Custom mimeType which is not yet added in the enum
  custom(name: 'Custom', type: '');

  final String name;
  final String type;
  const MimeType({required this.name, required this.type});

  static MimeType? get(String? name) {
    return MimeType.values.firstWhereOrNull((e) => e.name == name);
  }
}
