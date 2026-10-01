import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'progress_repository.dart';

class JsonProgressLocalStore implements ProgressLocalStore {
  JsonProgressLocalStore({
    Future<Directory> Function()? directoryProvider,
    this.fileName = 'helping_hand_progress.json',
  }) : _directoryProvider = directoryProvider ?? getApplicationSupportDirectory;

  factory JsonProgressLocalStore.forUser(String uid) {
    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(uid)) {
      throw ArgumentError.value(uid, 'uid', 'Invalid Firebase user ID.');
    }
    return JsonProgressLocalStore(fileName: 'helping_hand_progress_$uid.json');
  }

  final Future<Directory> Function() _directoryProvider;
  final String fileName;

  static Future<void> migrateLegacyProgress(String uid) async {
    final legacy = JsonProgressLocalStore();
    final legacyFile = await legacy._file();
    final migratedFile = File('${legacyFile.path}.migrated');
    if (!await legacyFile.exists() || await migratedFile.exists()) return;

    final accountStore = JsonProgressLocalStore.forUser(uid);
    if (await accountStore.read() == null) {
      await accountStore.write(await legacyFile.readAsString());
    }
    await legacyFile.rename(migratedFile.path);
  }

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
