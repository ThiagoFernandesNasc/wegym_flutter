import 'dart:convert';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';

class ProfileDataExport {
  @visibleForTesting
  static Future<String?> Function(String name, Uint8List bytes)? saveHandler;

  static Future<String?> saveJson(Object? data) async {
    final bytes = Uint8List.fromList(
      utf8.encode(const JsonEncoder.withIndent('  ').convert(data)),
    );
    final handler = saveHandler;
    if (handler != null) return handler('dados-pessoais', bytes);
    return FileSaver.instance.saveAs(
      name: 'dados-pessoais',
      bytes: bytes,
      fileExtension: 'json',
      mimeType: MimeType.json,
    );
  }
}
