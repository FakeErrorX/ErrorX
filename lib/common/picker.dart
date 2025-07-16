import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:errorx/common/common.dart';

class Picker {
  Future<PlatformFile?> pickerFile() async {
    final filePickerResult = await FilePicker.platform.pickFiles(
      withData: true,
      allowMultiple: false,
      initialDirectory: await appPath.downloadDirPath,
    );
    return filePickerResult?.files.first;
  }

  Future<String?> saveFile(String fileName, Uint8List bytes) async {
    final path = await FilePicker.platform.saveFile(
      fileName: fileName,
      initialDirectory: await appPath.downloadDirPath,
      bytes: Platform.isAndroid ? bytes : null,
    );
    if (!Platform.isAndroid && path != null) {
      final file = await File(path).create(recursive: true);
      await file.writeAsBytes(bytes);
    }
    return path;
  }
}

final picker = Picker();
