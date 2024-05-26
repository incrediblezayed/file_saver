import 'dart:developer';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class SaveWithFileProxy extends StatefulWidget {
  const SaveWithFileProxy({Key? key}) : super(key: key);

  @override
  State<SaveWithFileProxy> createState() => _SaveWithFileProxyState();
}

class _SaveWithFileProxyState extends State<SaveWithFileProxy> {
  TextEditingController nameController = TextEditingController();
  TextEditingController originalFileController = TextEditingController();
  TextEditingController destinationFileController = TextEditingController();
  TextEditingController extController = TextEditingController();

  MimeType type = MimeType.jpeg;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Name",
                    hintText: "Something",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: originalFileController,
                  decoration: InputDecoration(
                    labelText: "Original file",
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () async {
                        FilePickerResult? result =
                            await FilePicker.platform.pickFiles();

                        final resultPath = result?.files.single.path;

                        if (resultPath != null) {
                          File file = File(resultPath);
                          originalFileController.text = file.path;
                        } else {
                          // User canceled the picker
                        }
                      },
                      icon: const Icon(Icons.folder),
                    ),
                  ),
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
            Padding(
              padding: const EdgeInsets.all(8),
              child: ElevatedButton(
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

                  String path = await FileSaver.instance.saveFile(
                    name: nameController.text == ""
                        ? "File"
                        : nameController.text,
                    //link:  linkController.text,
                    // bytes: Uint8List.fromList(excel.encode()!),
                    file: File(originalFileController.text),
                    ext: extController.text,

                    ///extController.text,
                    mimeType: MimeType.microsoftExcel,
                  );
                  log(path);
                },
                child: const Text('Save file'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
