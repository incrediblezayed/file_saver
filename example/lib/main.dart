import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
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
                  decoration: InputDecoration(
                      labelText: "Name",
                      hintText: "Something",
                      border: OutlineInputBorder()),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Excel execl = Excel.createExcel();
                for (int i = 0; i < 10; i++)
                  execl.insertRowIterables("Sheet1", ['a', i], i);
                List<int> sheets = await execl.encode();
                Uint8List data = Uint8List.fromList(sheets);
                MimeType type = MimeType.MICROSOFTEXCEL;
       /*          if (!kIsWeb) {
                  if (Platform.isIOS || Platform.isAndroid) {
                    bool status = await Permission.storage.isGranted;
                    print(status);
                    if (!status) await Permission.storage.request();
                  }
                } */
                await FileSaver.instance.saveAs(
                  textEditingController?.text == ""
                      ? "File"
                      : textEditingController.text,
                  "xlsx",
                  data,
                  type
                );
              },
              child: Text("Generate Excel And Download"),
            )
          ],
        ),
      ),
    );
  }
}
