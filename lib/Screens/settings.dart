import 'package:app/Constants/variables.dart';
import 'package:flutter/material.dart';

class Settings extends StatefulWidget {
  final State nav;

  const Settings({super.key, required this.nav});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Padding(
      padding: const EdgeInsets.all(50.0),
      child: Column(
        spacing: 10,
        mainAxisSize: MainAxisSize.max,
        children: [
          const Text(
            "Settings",
            style: TextStyle(fontSize: 30),
          ),
          const Divider(),
          ListTile(
            leading: const Text("Show Navigation Labels",
                style: TextStyle(fontSize: 15)),
            trailing: Switch(value: showNavLabels, onChanged: toggleNavLabels),
          ),
        ],
      ),
    ));
  }

  void toggleNavLabels(bool value) {
    widget.nav.setState(() {
      showNavLabels = value;
    });
  }
}
