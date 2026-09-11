import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'progress_repository.dart';

class JsonProgressLocalStore implements ProgressLocalStore {
  JsonProgressLocalStore({
    Future<Directory> Function()? directoryProvider,
    this.fileName = 'helping_hand_progress.json',
  }) : _directoryProvider = directoryProvider ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _directoryProvider;
  final String fileName;

  Future<File> _file() async {
    final directory = await _directoryProvider();
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return File('${directory.path}${Platform.pathSeparator}$fileName');
  }

  @override
  Future<String?> read() async {
    final file = await _file();
    if (!await file.exists()) return null;
    return file.readAsString();
  }

  @override
  Future<void> write(String value) async {
    final file = await _file();
    await file.writeAsString(value, flush: true);
  }
}
