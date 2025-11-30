import 'package:hive/hive.dart';

bool serverRunning = false;
bool clientConnected = false;
Map<String, dynamic> settingsObj = {
  "showNavLabels": true,
  "saveReceivedFiles": false,
};
late Box box;
