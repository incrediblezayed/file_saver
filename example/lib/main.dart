import 'dart:convert';

import 'package:excel/excel.dart' as excel;
import 'package:file_saver/file_saver.dart';
import 'package:file_saver_example/platform_file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const FileSaverExampleApp());
}

class FileSaverExampleApp extends StatelessWidget {
  const FileSaverExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'File Saver Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const FileSaverTestPage(),
    );
  }
}

class FileSaverTestPage extends StatefulWidget {
  const FileSaverTestPage({super.key});

  @override
  State<FileSaverTestPage> createState() => _FileSaverTestPageState();
}

class _FileSaverTestPageState extends State<FileSaverTestPage> {
  final _nameController = TextEditingController(text: 'file_saver_test');
  final _extensionController = TextEditingController(text: 'xlsx');
  final _linkController = TextEditingController(
    text:
        'https://raw.githubusercontent.com/incrediblezayed/file_saver/main/README.md',
  );
  final _customMimeController = TextEditingController(
    text: 'application/octet-stream',
  );
  final _headersController = TextEditingController();
  final _largeFileSizeController = TextEditingController(text: '64');

  final List<_RunLog> _logs = <_RunLog>[];
  MimeType _mimeType = MimeType.microsoftExcel;
  bool _includeExtension = true;
  bool _isRunning = false;
  String? _pickedFilePath;

  bool get _supportsDirectDownload =>
      kIsWeb || defaultTargetPlatform == TargetPlatform.android;

  bool get _isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  @override
  void dispose() {
    _nameController.dispose();
    _extensionController.dispose();
    _linkController.dispose();
    _customMimeController.dispose();
    _headersController.dispose();
    _largeFileSizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tests = <_ExampleAction>[
      _ExampleAction(
        icon: Icons.save_alt,
        title: 'saveFile from bytes',
        detail: 'Writes a generated Excel file to the platform default path.',
        onRun: () => _run(
          'saveFile bytes',
          () => FileSaver.instance.saveFile(
            name: _fileName('bytes'),
            bytes: _excelBytes(),
            fileExtension: _extension('xlsx'),
            includeExtension: _includeExtension,
            mimeType: MimeType.microsoftExcel,
          ),
        ),
      ),
      _ExampleAction(
        icon: Icons.drive_folder_upload,
        title: 'saveAs from bytes',
        detail: 'Opens the platform picker where supported, web downloads.',
        onRun: () => _run(
          'saveAs bytes',
          () => FileSaver.instance.saveAs(
            name: _fileName('save_as_bytes'),
            bytes: _excelBytes(),
            fileExtension: _extension('xlsx'),
            includeExtension: _includeExtension,
            mimeType: MimeType.microsoftExcel,
          ),
        ),
      ),
      _ExampleAction(
        icon: Icons.hide_source,
        title: 'saveAs without extension',
        detail: 'Covers the optional fileExtension/includeExtension path.',
        onRun: () => _run(
          'saveAs no extension',
          () => FileSaver.instance.saveAs(
            name: _fileName('no_extension'),
            bytes: Uint8List.fromList('Saved without extension'.codeUnits),
            includeExtension: false,
            mimeType: MimeType.text,
          ),
        ),
      ),
      _ExampleAction(
        icon: Icons.link,
        title: 'saveFile from link',
        detail: 'Fetches URL bytes in app memory, then saves them.',
        onRun: () => _run(
          'saveFile link',
          () => FileSaver.instance.saveFile(
            name: _fileName('downloaded'),
            link: LinkDetails(link: _linkController.text.trim()),
            fileExtension: _extension('txt'),
            includeExtension: _includeExtension,
            mimeType: _mimeType,
            customMimeType: _customMimeType,
          ),
        ),
      ),
      _ExampleAction(
        icon: Icons.download,
        title: 'downloadLink direct',
        detail: _supportsDirectDownload
            ? 'Uses browser handoff on web and DownloadManager on Android.'
            : 'Direct URL handoff is currently web/Android only.',
        enabled: _supportsDirectDownload,
        onRun: () => _run(
          'downloadLink direct',
          () => FileSaver.instance.downloadLink(
            link: LinkDetails(link: _linkController.text.trim()),
            name: _fileName('direct_download'),
          ),
        ),
      ),
      _ExampleAction(
        icon: Icons.security,
        title: 'saveLinkAsStream headers',
        detail: kIsWeb
            ? 'Uses fetch headers/cookies plus File System Access API.'
            : 'Streams a URL with headers to temp storage, then saves.',
        onRun: () => _run(
          'saveLinkAsStream',
          () => FileSaver.instance.saveLinkAsStream(
            name: _fileName('streamed_link'),
            link: LinkDetails(
              link: _linkController.text.trim(),
              headers: _headers(),
            ),
            fileExtension: _extension('bin'),
            includeExtension: _includeExtension,
            mimeType: _mimeType,
            customMimeType: _customMimeType,
          ),
        ),
      ),
      _ExampleAction(
        icon: Icons.folder_open,
        title: 'Pick file path',
        detail: supportsFilePathTests
            ? 'Selects a local file for filePath save tests.'
            : filePathUnsupportedMessage,
        enabled: supportsFilePathTests,
        onRun: () => _run('pick file', () async {
          final path = await pickFilePath();
          setState(() => _pickedFilePath = path);
          return path;
        }),
      ),
      _ExampleAction(
        icon: Icons.copy,
        title: 'saveFile from filePath',
        detail: supportsFilePathTests
            ? 'Copies the picked file using the Dart filePath argument.'
            : filePathUnsupportedMessage,
        enabled: supportsFilePathTests,
        onRun: () => _runWithPickedFile(
          'saveFile filePath',
          (path) => FileSaver.instance.saveFile(
            name: _fileName('copied_file'),
            filePath: path,
            fileExtension: _extension('bin'),
            includeExtension: _includeExtension,
            mimeType: _mimeType,
            customMimeType: _customMimeType,
          ),
        ),
      ),
      _ExampleAction(
        icon: Icons.file_present,
        title: 'saveAs from filePath',
        detail: supportsFilePathTests
            ? 'Uses native streaming on Android for file/filePath input.'
            : filePathUnsupportedMessage,
        enabled: supportsFilePathTests,
        onRun: () => _runWithPickedFile(
          'saveAs filePath',
          (path) => FileSaver.instance.saveAs(
            name: _fileName('save_as_file'),
            filePath: path,
            fileExtension: _extension('bin'),
            includeExtension: _includeExtension,
            mimeType: _mimeType,
            customMimeType: _customMimeType,
          ),
        ),
      ),
      _ExampleAction(
        icon: Icons.data_array,
        title: 'Generate large file and saveAs',
        detail: supportsFilePathTests
            ? 'Creates a temp file and saves it through filePath.'
            : filePathUnsupportedMessage,
        enabled: supportsFilePathTests,
        onRun: () => _run('large file saveAs', () async {
          final generated = await createLargeTestFile(sizeMb: _largeFileSizeMb);
          setState(() => _pickedFilePath = generated.path);
          return FileSaver.instance.saveAs(
            name: _fileName('large_${generated.sizeMb}mb'),
            filePath: generated.path,
            fileExtension: 'bin',
            mimeType: MimeType.other,
          );
        }),
      ),
      _ExampleAction(
        icon: Icons.stream,
        title: 'saveAs from generated stream',
        detail: kIsWeb
            ? 'Chrome/Edge stream to disk. Firefox/Safari should report unsupported.'
            : 'Writes a stream to temp storage, then saves from filePath.',
        onRun: () => _run(
          'saveAs stream',
          () => FileSaver.instance.saveAsStream(
            name: _fileName('stream_${_largeFileSizeMb}mb'),
            stream: _generatedBytesStream(_largeFileSizeMb),
            fileExtension: 'bin',
            mimeType: MimeType.other,
          ),
        ),
      ),
      _ExampleAction(
        icon: Icons.warning_amber,
        title: 'Invalid Windows name',
        detail: _isWindows
            ? 'Verifies Windows returns an explicit invalid-name error.'
            : 'Windows-only test. Other platforms may allow this filename.',
        enabled: _isWindows,
        onRun: () => _run(
          'invalid Windows name',
          () => FileSaver.instance.saveAs(
            name: 'bad:name',
            bytes: Uint8List.fromList('invalid name test'.codeUnits),
            fileExtension: 'txt',
            mimeType: MimeType.text,
          ),
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('File Saver Example'),
        actions: [
          IconButton(
            tooltip: 'Clear log',
            icon: const Icon(Icons.clear_all),
            onPressed: _logs.isEmpty ? null : () => setState(_logs.clear),
          ),
          IconButton(
            tooltip: 'Copy debug log',
            icon: const Icon(Icons.copy_all),
            onPressed: _logs.isEmpty ? null : _copyAllLogs,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SettingsPanel(
                nameController: _nameController,
                extensionController: _extensionController,
                linkController: _linkController,
                customMimeController: _customMimeController,
                headersController: _headersController,
                largeFileSizeController: _largeFileSizeController,
                includeExtension: _includeExtension,
                mimeType: _mimeType,
                onIncludeExtensionChanged: (value) {
                  setState(() => _includeExtension = value);
                },
                onMimeTypeChanged: (value) {
                  if (value == null) return;
                  setState(() => _mimeType = value);
                },
                pickedFilePath: _pickedFilePath,
              ),
              const SizedBox(height: 16),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _ActionList(tests: tests)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _LogPanel(logs: _logs, onCopyLog: _copyLog),
                    ),
                  ],
                )
              else ...[
                _ActionList(tests: tests),
                const SizedBox(height: 16),
                _LogPanel(logs: _logs, onCopyLog: _copyLog),
              ],
            ],
          );
        },
      ),
      bottomNavigationBar: _isRunning
          ? const LinearProgressIndicator(minHeight: 3)
          : const SizedBox(height: 3),
    );
  }

  int get _largeFileSizeMb {
    final parsed = int.tryParse(_largeFileSizeController.text.trim()) ?? 64;
    return parsed.clamp(1, 512);
  }

  String? get _customMimeType {
    if (_mimeType != MimeType.custom) return null;
    final value = _customMimeController.text.trim();
    return value.isEmpty ? 'application/octet-stream' : value;
  }

  Map<String, String>? _headers() {
    final value = _headersController.text.trim();
    if (value.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(value);
    if (decoded is! Map) {
      throw const FormatException('Headers JSON must be an object.');
    }
    return decoded.map(
      (key, headerValue) => MapEntry(key.toString(), headerValue.toString()),
    );
  }

  String _fileName(String fallback) {
    final name = _nameController.text.trim();
    return name.isEmpty ? fallback : name;
  }

  String _extension(String fallback) {
    final extension = _extensionController.text.trim();
    return extension.isEmpty ? fallback : extension;
  }

  Uint8List _excelBytes() {
    final workbook = excel.Excel.createExcel();
    final sheet = workbook['ManualTest'];
    sheet.appendRow([
      excel.TextCellValue('created_at'),
      excel.TextCellValue(DateTime.now().toIso8601String()),
    ]);
    sheet.appendRow([
      excel.TextCellValue('platform'),
      excel.TextCellValue(kIsWeb ? 'web' : defaultTargetPlatform.name),
    ]);
    return Uint8List.fromList(workbook.encode()!);
  }

  Stream<List<int>> _generatedBytesStream(int sizeMb) async* {
    final safeSizeMb = sizeMb.clamp(1, 512);
    final chunk = Uint8List(1024 * 1024);
    for (var i = 0; i < chunk.length; i++) {
      chunk[i] = i % 251;
    }
    for (var i = 0; i < safeSizeMb; i++) {
      yield chunk;
    }
  }

  Future<void> _runWithPickedFile(
    String label,
    Future<String?> Function(String path) action,
  ) async {
    if (!supportsFilePathTests) {
      await _run(label, () async {
        throw UnsupportedError(filePathUnsupportedMessage);
      });
      return;
    }
    final path = _pickedFilePath;
    if (path == null || path.isEmpty) {
      await _run(label, () async {
        final pickedPath = await pickFilePath();
        if (pickedPath == null || pickedPath.isEmpty) {
          return null;
        }
        setState(() => _pickedFilePath = pickedPath);
        return action(pickedPath);
      });
      return;
    }
    await _run(label, () => action(path));
  }

  Future<void> _run(String label, Future<String?> Function() action) async {
    if (_isRunning) return;
    setState(() => _isRunning = true);
    final startedAt = DateTime.now();
    try {
      final result = await action();
      _addLog(
        _RunLog.success(
          label,
          result == null || result.isEmpty
              ? 'Completed with null result'
              : result,
          DateTime.now().difference(startedAt),
        ),
      );
    } catch (error) {
      _addLog(
        _RunLog.failure(
          label,
          error.toString(),
          DateTime.now().difference(startedAt),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isRunning = false);
      }
    }
  }

  void _addLog(_RunLog log) {
    if (!mounted) return;
    debugPrint(log.toDebugText());
    setState(() {
      _logs.insert(0, log);
      if (_logs.length > 12) {
        _logs.removeRange(12, _logs.length);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${log.label}: ${log.success ? 'passed' : 'failed'}'),
        action: SnackBarAction(
          label: 'Copy log',
          onPressed: () => _copyLog(log),
        ),
      ),
    );
  }

  Future<void> _copyLog(_RunLog log) async {
    await Clipboard.setData(ClipboardData(text: log.toDebugText()));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Debug log copied')));
  }

  Future<void> _copyAllLogs() async {
    final debugLog = _logs.map((log) => log.toDebugText()).join('\n\n');
    await Clipboard.setData(ClipboardData(text: debugLog));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('All debug logs copied')));
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({
    required this.nameController,
    required this.extensionController,
    required this.linkController,
    required this.customMimeController,
    required this.headersController,
    required this.largeFileSizeController,
    required this.includeExtension,
    required this.mimeType,
    required this.onIncludeExtensionChanged,
    required this.onMimeTypeChanged,
    required this.pickedFilePath,
  });

  final TextEditingController nameController;
  final TextEditingController extensionController;
  final TextEditingController linkController;
  final TextEditingController customMimeController;
  final TextEditingController headersController;
  final TextEditingController largeFileSizeController;
  final bool includeExtension;
  final MimeType mimeType;
  final ValueChanged<bool> onIncludeExtensionChanged;
  final ValueChanged<MimeType?> onMimeTypeChanged;
  final String? pickedFilePath;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: BoxBorder.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              runSpacing: 12,
              spacing: 12,
              children: [
                SizedBox(
                  width: 240,
                  child: TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: TextField(
                    controller: extensionController,
                    decoration: const InputDecoration(
                      labelText: 'Extension',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: TextField(
                    controller: largeFileSizeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Large MB',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: DropdownButtonFormField<MimeType>(
                    initialValue: mimeType,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'MIME type',
                      border: OutlineInputBorder(),
                    ),
                    items: MimeType.values
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(
                              type.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: onMimeTypeChanged,
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: SwitchListTile(
                    value: includeExtension,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Include extension'),
                    onChanged: onIncludeExtensionChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: linkController,
              decoration: const InputDecoration(
                labelText: 'Link',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: headersController,
              decoration: const InputDecoration(
                labelText: 'Headers JSON',
                hintText: '{"Authorization":"Bearer token"}',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: customMimeController,
              decoration: const InputDecoration(
                labelText: 'Custom MIME',
                border: OutlineInputBorder(),
              ),
            ),
            if (pickedFilePath != null && pickedFilePath!.isNotEmpty) ...[
              const SizedBox(height: 12),
              SelectableText('Picked file: $pickedFilePath'),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionList extends StatelessWidget {
  const _ActionList({required this.tests});

  final List<_ExampleAction> tests;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: tests
          .map(
            (test) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                leading: Icon(test.icon),
                title: Text(test.title),
                subtitle: Text(test.detail),
                trailing: FilledButton(
                  onPressed: test.enabled ? test.onRun : null,
                  child: Text(test.enabled ? 'Run' : 'Unavailable'),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _LogPanel extends StatelessWidget {
  const _LogPanel({required this.logs, required this.onCopyLog});

  final List<_RunLog> logs;
  final ValueChanged<_RunLog> onCopyLog;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: BoxBorder.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Result log', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (!supportsFilePathTests) ...[
              const Text(filePathUnsupportedMessage),
              const SizedBox(height: 8),
            ],
            if (logs.isEmpty)
              const Text('No runs yet.')
            else
              for (final log in logs)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: log.success
                          ? Colors.green.withValues(alpha: 0.08)
                          : Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                log.success ? Icons.check_circle : Icons.error,
                                size: 18,
                                color: log.success ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${log.label} (${log.elapsed.inMilliseconds} ms)',
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Copy this debug log',
                                icon: const Icon(Icons.copy, size: 18),
                                onPressed: () => onCopyLog(log),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          SelectableText(log.message),
                        ],
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _ExampleAction {
  const _ExampleAction({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onRun,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onRun;
  final bool enabled;
}

class _RunLog {
  const _RunLog({
    required this.label,
    required this.message,
    required this.elapsed,
    required this.success,
    required this.createdAt,
  });

  factory _RunLog.success(String label, String message, Duration elapsed) {
    return _RunLog(
      label: label,
      message: message,
      elapsed: elapsed,
      success: true,
      createdAt: DateTime.now(),
    );
  }

  factory _RunLog.failure(String label, String message, Duration elapsed) {
    return _RunLog(
      label: label,
      message: message,
      elapsed: elapsed,
      success: false,
      createdAt: DateTime.now(),
    );
  }

  final String label;
  final String message;
  final Duration elapsed;
  final bool success;
  final DateTime createdAt;

  String toDebugText() {
    return [
      'FileSaver example debug log',
      'time: ${createdAt.toIso8601String()}',
      'platform: ${kIsWeb ? 'web' : defaultTargetPlatform.name}',
      'supportsFilePathTests: $supportsFilePathTests',
      'label: $label',
      'status: ${success ? 'success' : 'failure'}',
      'elapsedMs: ${elapsed.inMilliseconds}',
      'message: $message',
    ].join('\n');
  }
}
