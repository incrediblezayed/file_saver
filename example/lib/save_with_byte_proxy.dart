import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:developer';
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:permission_handler/permission_handler.dart';



class SaveWithByteProxy extends StatefulWidget {
  const SaveWithByteProxy({Key? key}) : super(key: key);

  @override
  State<SaveWithByteProxy> createState() => _SaveWithByteProxyState();
}

class _SaveWithByteProxyState extends State<SaveWithByteProxy> {
  TextEditingController textEditingController = TextEditingController();
  TextEditingController linkController = TextEditingController(
      text:
          "https://i.pinimg.com/564x/80/d4/90/80d490f65d5e6132b2a6e3b5883785f3.jpg");
  TextEditingController extController = TextEditingController(text: "jpg");

  @override
  void initState() {
    super.initState();
  }

  List<int>? getExcel() {
    final Excel excel = Excel.createExcel();
    final Sheet sheetObject = excel['Sheet1'];
    sheetObject.insertColumn(0);
    for (int i = 1; i < 10; i++) {
      sheetObject.appendRow([i]);
    }
    List<int>? sheets = excel.encode();
    return sheets;
  }

  MimeType type = MimeType.jpeg;
  @override
  Widget build(BuildContext context) {
    return Column(
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
        Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: linkController,
              decoration: const InputDecoration(
                  labelText: "Link",
                  hintText:
                      "https://i.pinimg.com/564x/80/d4/90/80d490f65d5e6132b2a6e3b5883785f3.jpg",
                  border: OutlineInputBorder()),
            ),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: extController,
              decoration: const InputDecoration(
                  labelText: "Extension",
                  hintText: "jpg",
                  border: OutlineInputBorder()),
            ),
          ),
        ),
        DropdownButton(
          value: type,
          items: MimeType.values
              .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
              .toList(),
          onChanged: (value) {
            setState(() {
              type = value as MimeType;
            });
          },
        ),
        ElevatedButton(
            onPressed: () async {
              if (!kIsWeb) {
                if (Platform.isIOS || Platform.isAndroid) {
                  bool status = await Permission.storage.isGranted;

                  if (!status) await Permission.storage.request();
                }
              }
              if (type != MimeType.other && extController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Extension is required")));
              }

              if (linkController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Link is required")));
              }

              //!Code for testing bytes
              Excel excel = Excel.createExcel();
              Sheet sheetObject = excel['Sheet1'];
              sheetObject.insertColumn(0);
              for (int i = 1; i < 10; i++) {
                sheetObject.appendRow([i]);
              }

              String path = await FileSaver.instance.saveFile(
                  name: textEditingController.text == ""
                      ? "File"
                      : textEditingController.text,
                  //link:  linkController.text,
                  bytes: Uint8List.fromList(excel.encode()!),
                  ext: 'xlsx',

                  ///extController.text,
                  mimeType: MimeType.microsoftExcel);
              log(path);
            },
            child: const Text("Save File")),
        /* if (!kIsWeb)
              if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) */
        ElevatedButton(
          onPressed: () async {
            if (type != MimeType.other && extController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Extension is required")));
            }

            if (linkController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Link is required")));
            }
            /*    if (Platform.isAndroid || Platform.isIOS) {
                  var permission = await Permission.storage.request();
                  if (permission == PermissionStatus.granted) {
                  } else {
                    log("Permission Denied");
                  }
                } */

            //!Code for testing bytes
            Excel excel = Excel.createExcel();
            Sheet sheetObject = excel['Sheet1'];
            sheetObject.insertColumn(0);
            for (int i = 1; i < 10; i++) {
              sheetObject.appendRow([i]);
            }
            String? path = await FileSaver.instance.saveAs(
                name: textEditingController.text == ""
                    ? "File"
                    : textEditingController.text,
                //link:  linkController.text,
                bytes: Uint8List.fromList(excel.encode()!),
                ext: 'xlsx',

                ///extController.text,
                mimeType: MimeType.microsoftExcel);
            log(path.toString());
          },
          child: const Text("Open File Manager"),
        )
      ],
    );
  }
}
