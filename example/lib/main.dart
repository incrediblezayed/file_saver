import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key key}) : super(key: key);
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  TextEditingController textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('File Saver'),
        ),
        body: Column(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: textEditingController,
                  decoration: const InputDecoration(
                      labelText: "Name",
                      hintText: "Something",
                      border: OutlineInputBorder()),
                ),
              ),
            ),
            ElevatedButton(
                onPressed: () async {
                  if (!kIsWeb) {
                    if (Platform.isIOS || Platform.isAndroid || Platform.isMacOS) {
                      bool status = await Permission.storage.isGranted;

                      if (!status) await Permission.storage.request();
                    }
                  }
                  Excel excel = Excel.createExcel();
                  for (int i = 0; i < 10; i++) {
                    excel.insertRowIterables("Sheet1", ['a', i], i);
                  }
                  List<int> sheets = await excel.encode();
                  Uint8List data = Uint8List.fromList(sheets);
                  MimeType type = MimeType.MICROSOFTEXCEL;
                  String path = await FileSaver.instance.saveFile(
                      textEditingController.text == ""
                          ? "File"
                          : textEditingController.text,
                      data,
                      "xlsx",
                      mimeType: type);
                  print(path);
                },
                child: const Text("Save File")),
            if (!kIsWeb)
              if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)
                ElevatedButton(
                  onPressed: () async {
                    Excel excel = Excel.createExcel();
                    for (int i = 0; i < 10; i++) {
                      excel.insertRowIterables("Sheet1", ['a', i], i);
                    }
                    List<int> sheets = await excel.encode();
                    Uint8List data = Uint8List.fromList(sheets);
                    MimeType type = MimeType.MICROSOFTEXCEL;
                    String path = await FileSaver.instance.saveAs(
                        textEditingController.text == ""
                            ? "File"
                            : textEditingController.text,
                        data,
                        "xlsx",
                        type);
                    print(path);
                  },
                  child: const Text("Generate Excel and Open Save As Dialog"),
                )
          ],
        ),
      ),
    );
  }
}
