import 'dart:io';
import 'package:path/path.dart' as p;

import 'package:app/Classes/server/address.dart';
import 'package:app/Classes/server/client.dart';
import 'package:app/Constants/functions.dart';
import 'package:app/Constants/theme.dart';
import 'package:app/Constants/variables.dart';
import 'package:app/Widgets/alert.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Global variables
String _ipInputClient = "";
String _portInputClient = "";
Icon _connectBtnIcon = const Icon(Icons.link);
Color _connectBtnColor = darkGreen;
Address? _serverAddr;
Client? _client;
List<Widget> _files = [];

class ClientDashboard extends StatefulWidget {
  const ClientDashboard({super.key});

  @override
  State<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends State<ClientDashboard> {
  var ipTxtContr = TextEditingController(
    text: _ipInputClient.isNotEmpty ? _ipInputClient : "",
  );

  var portTxtContr = TextEditingController(
      text: _portInputClient.isNotEmpty ? _portInputClient : "");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(right: 20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 650),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 50),
              decoration: BoxDecoration(
                  color: background,
                  border: Border.all(color: flatBlack),
                  borderRadius: const BorderRadius.all(Radius.circular(20))),
              child: Column(
                children: [
                  TextField(
                    controller: ipTxtContr,
                    maxLength: 15,
                    decoration:
                        const InputDecoration(labelText: "IP", counterText: ""),
                    onChanged: (value) {
                      setState(() {
                        _ipInputClient = value;
                      });
                    },
                  ),
                  TextField(
                    controller: portTxtContr,
                    maxLength: 5,
                    decoration: const InputDecoration(
                        labelText: "Port", counterText: ""),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly
                    ],
                    onChanged: (value) {
                      setState(() {
                        _portInputClient = value;
                      });
                    },
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  IconButton(
                    icon: _connectBtnIcon,
                    color: _connectBtnColor,
                    onPressed: () => _connect(),
                  ),
                ],
              ),
            ),
          ),
          Visibility(
            visible: clientConnected,
            child: Container(
              height: 200,
              width: 650,
              margin: const EdgeInsets.only(top: 20, right: 15),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  border: Border.all(color: flatBlack),
                  borderRadius: const BorderRadius.all(Radius.circular(20))),
              child: Column(
                children: [
                  IconButton(
                      onPressed: () => selectFile(),
                      icon: const Icon(Icons.add)),
                  Expanded(
                      child: _files.isNotEmpty
                          ? ListView.builder(
                              itemCount: _files.length,
                              itemBuilder: (context, index) => _files[index])
                          : const Text("No Files Added")),
                ],
              ),
            ),
          )
        ],
      ),
    ));
  }

  void _connect() {
    if (!clientConnected &&
        (_ipInputClient.isNotEmpty) &&
        (_portInputClient.isNotEmpty)) {
      if ((validateIP(_ipInputClient)) && validatePort(_portInputClient)) {
        setState(() {
          _serverAddr = Address(_ipInputClient, int.parse(_portInputClient));
          _client = Client(_serverAddr!, idGenerator());
          _client!.connect();
          clientConnected = !clientConnected;
          _connectBtnIcon = const Icon(Icons.link_off);
          _connectBtnColor = Colors.red;
        });
      } else {
        createDialogPopUp(context, "Error", "Invalid ip or port format");
      }
    } else if (clientConnected && _client != null) {
      // Do some error checking - kind of looks gross...
      setState(() {
        clientConnected = false;
      });
      setState(() {
        _client!.disconnect();
        _client = null;
        _connectBtnIcon = const Icon(Icons.link);
        _connectBtnColor = darkGreen;
        _files.clear();
      });
    } else {
      createDialogPopUp(context, "Error", "Please enter both an ip and port");
    }
  }

  Future<void> selectFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      File file = File(result.files.single.path!);
      Uint8List bytes = file.readAsBytesSync();
      Widget tmp = ListTile(
        leading: const Icon(Icons.file_present),
        title: Text(file.path),
        trailing: IconButton(
            onPressed: () {
              _client!.sendMessage(p.basename(file.path), bytes.toString().replaceAll(RegExp(r'[\[\],]'), ''));
              createDialogPopUp(context, "Sent", "File sent to server!");
            },
            icon: const Icon(Icons.send)),
      );
      setState(() {
        _files.add(tmp);
      });
    }
  }
}
