import 'package:app/Classes/SettingsManager.dart';
import 'package:app/Classes/server/message.dart';
import 'package:app/Constants/theme.dart';
import 'package:app/Constants/variables.dart';
import 'package:app/navigation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:window_manager/window_manager.dart';
import 'dart:io' show Directory, Platform;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Directory directory = await path_provider.getTemporaryDirectory();
  Hive.init(directory.path);
  Hive.registerAdapter(MessageAdapter());

  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    WidgetsFlutterBinding.ensureInitialized();
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
        center: true,
        minimumSize: Size(1000, 800),
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.normal,
        title: "Lynk");
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  var _future;
  Future<dynamic> _loadSettings() async {
    if (_future == null) {
      _future = await SettingsManager().readSettingsFile();
      setState(() {
        settingsObj = _future;
      });
    }
    return _future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _loadSettings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'Lynk',
                theme: appTheme,
                home: const Center(
                  child: CircularProgressIndicator(),
                ));
          } else if (snapshot.hasError) {
            return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'Lynk',
                theme: appTheme,
                home: Center(
                  child: Text('Error: ${snapshot.error}'),
                ));
          } else {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Lynk',
              theme: appTheme,
              home: const Navigation(),
            );
          }
        });
  }
}
