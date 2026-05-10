// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';

class FileModel {
  final String name;
  final Uint8List bytes;
  final String fileExtension;
  final String mimeType;
  final bool includeExtension;
  final String? sourcePath;
  FileModel({
    required this.name,
    required this.bytes,
    required this.fileExtension,
    required this.mimeType,
    required this.includeExtension,
    this.sourcePath,
  });

  FileModel copyWith({
    String? name,
    Uint8List? bytes,
    String? fileExtension,
    String? mimeType,
    bool? includeExtension,
    String? sourcePath,
  }) {
    return FileModel(
      name: name ?? this.name,
      bytes: bytes ?? this.bytes,
      fileExtension: fileExtension ?? this.fileExtension,
      mimeType: mimeType ?? this.mimeType,
      includeExtension: includeExtension ?? this.includeExtension,
      sourcePath: sourcePath ?? this.sourcePath,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'bytes': bytes,
      'fileExtension': fileExtension,
      'mimeType': mimeType,
      'includeExtension': includeExtension,
      'sourcePath': sourcePath,
    };
  }

  factory FileModel.fromMap(Map<String, dynamic> map) {
    return FileModel(
      name: map['name'] as String,
      bytes: Uint8List.fromList(List<int>.from(map['bytes'] as List<dynamic>)),
      fileExtension: map['fileExtension'] as String,
      mimeType: map['mimeType'] as String,
      includeExtension: map['includeExtension'] as bool,
      sourcePath: map['sourcePath'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory FileModel.fromJson(String source) =>
      FileModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
