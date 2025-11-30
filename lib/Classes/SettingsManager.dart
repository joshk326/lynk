import 'dart:convert';
import 'dart:io';

import 'package:app/Constants/variables.dart';
import 'package:path_provider/path_provider.dart';

class SettingsManager {
  static final SettingsManager _instance = SettingsManager._internal();

  factory SettingsManager() => _instance;

  SettingsManager._internal();

  Future<String> get _directory async {
    Directory directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _settingsFile async {
    final path = await _directory;
    return File('$path/lynk_settings.json');
  }

  Future<Map<String, dynamic>> readSettingsFile() async {
    String fileContent = "";

    File file = await _settingsFile;

    if (await file.exists()) {
      try {
        fileContent = await file.readAsString();
        return jsonDecode(fileContent);
      } catch (e) {
        print(e);
      }
    }

    // If the file doesnt exist create it with default variable
    await writeSettingsFile();

    return settingsObj;
  }

  Future<void> writeSettingsFile() async {
    File file = await _settingsFile;
    await file.writeAsString(jsonEncode(settingsObj));
  }
}
