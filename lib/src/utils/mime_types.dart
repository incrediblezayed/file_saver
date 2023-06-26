///[MimeType] is an enum for adding filetype for HTML Blob
enum MimeType {
  ///[avi] for .avi extension
  avi(name: 'AVI', type: 'video/x-msvideo'),

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

  ///[json] for .json extension
  json(name: 'JSON', type: 'application/json'),

  ///[jpeg] for .jpeg extension
  jpeg(name: 'JPEG', type: 'image/jpeg'),

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

  ///[mpeg] for .mpeg extension
  mpeg(name: 'MPEG', type: 'video/mpeg'),

  ///[mp3] for .mp3 extension
  mp3(name: 'MP3', type: 'audio/mpeg'),

  ///[other] for other extension
  other(name: 'Other', type: 'application/octet-stream'),

  ///[otf] for .otf extension
  otf(name: 'OTF', type: 'font/otf'),

  ///[openDocSheets] for .ods extension
  openDocSheets(
    name: 'Open Document Sheets',
    type: 'application/vnd.oasis.opendocument.spreadsheet',
  ),

  ///[openDocPresentation] for .odp extension
  openDocPresentation(
    name: 'Open Document Presentation',
    type: 'application/vnd.oasis.opendocument.presentation',
  ),

  ///[openDocText] for .odt extension
  openDocText(
      name: 'Open Document Text',
      type: 'application/vnd.oasis.opendocument.text'),

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

  ///[text] for .txt extension
  text(name: 'Text', type: 'text/plain'),

  ///[ttf] for .ttf extension
  ttf(name: 'TTF', type: 'font/ttf'),

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
}
