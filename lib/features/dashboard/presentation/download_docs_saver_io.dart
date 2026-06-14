import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Future<String> savePdfBytesToDevice(Uint8List bytes, String filename) async {
  if (Platform.isAndroid) {
    await Permission.storage.request();
  }

  final baseDirectory =
      await getDownloadsDirectory() ??
      await getExternalStorageDirectory() ??
      await getApplicationDocumentsDirectory();
  final labInDirectory = Directory(
    '${baseDirectory.path}${Platform.pathSeparator}LabIn',
  );
  await labInDirectory.create(recursive: true);
  final file = File('${labInDirectory.path}${Platform.pathSeparator}$filename');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
