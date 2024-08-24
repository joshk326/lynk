import 'package:app/navigation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io' show Platform;

void main() async {
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    WidgetsFlutterBinding.ensureInitialized();
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      center: true,
      minimumSize: Size(900, 800),
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'App',
      home: Navigation(),
    );
  }
}
