import 'dart:async';
import 'dart:convert';
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
Map<String, String> _fileData = {};

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
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Wrap(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 19),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 650),
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 50),
                decoration: BoxDecoration(
                    color: background,
                    border: Border.all(color: flatBlack),
                    borderRadius: const BorderRadius.all(Radius.circular(20))),
                child: Column(
                  children: [
                    TextField(
                      controller: ipTxtContr,
                      enabled: !clientConnected,
                      maxLength: 15,
                      decoration: const InputDecoration(
                          labelText: "Server IP", counterText: ""),
                      onChanged: (value) {
                        setState(() {
                          _ipInputClient = value;
                        });
                      },
                    ),
                    TextField(
                      controller: portTxtContr,
                      enabled: !clientConnected,
                      maxLength: 5,
                      decoration: const InputDecoration(
                          labelText: "Server Port", counterText: ""),
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
                        onPressed: () => _selectFile(),
                        icon: const Icon(Icons.add)),
                    Expanded(
                        child: _fileData.isNotEmpty
                            ? ListView.builder(
                                itemCount: _fileData.length,
                                itemBuilder: (context, index) {
                                  String fileName =
                                      _fileData.keys.elementAt(index);
                                  return ListTile(
                                    leading: const Icon(Icons.file_present),
                                    title: Text(fileName),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          onPressed: () async {
                                            String fileData =
                                                _fileData[fileName]!;
                                            await _client!
                                                .sendMessage(createJsonMessage(
                                              metadata: _client!.name,
                                              fileName: fileName,
                                              fileContent: fileData,
                                            ));
                                            createDialogPopUp(
                                                context.mounted
                                                    ? context
                                                    : null,
                                                "Sent",
                                                "File sent to server!");
                                          },
                                          icon: const Icon(Icons.send),
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            _deleteFile(fileName);
                                          },
                                          icon: const Icon(Icons.delete),
                                        ),
                                      ],
                                    ),
                                  );
                                })
                            : const Text("No Files Added")),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    ));
  }

  @override
  void dispose() {
    _stopConnectionCheck();
    super.dispose();
  }

  Future<void> _connect() async {
    if (!clientConnected &&
        (_ipInputClient.isNotEmpty) &&
        (_portInputClient.isNotEmpty)) {
      if ((validateIP(_ipInputClient)) && validatePort(_portInputClient)) {
        setState(() {
          _serverAddr = Address(_ipInputClient, int.parse(_portInputClient));
          _client = Client(_serverAddr!);
        });
        try {
          await _client!.connect();

          _startConnectionCheck();

          setState(() {
            clientConnected = !clientConnected;
            _connectBtnIcon = const Icon(Icons.link_off);
            _connectBtnColor = Colors.red;
          });
        } catch (e) {
          createDialogPopUp(context.mounted ? context : null, "Error",
              "Connection failed: $e");
        }
      } else {
        createDialogPopUp(context, "Error", "Invalid ip or port format");
      }
    } else if (clientConnected && _client != null) {
      setState(() {
        clientConnected = false;
      });
      _resetClient();
    } else {
      createDialogPopUp(context, "Error", "Please enter both an ip and port");
    }
  }

  void _startConnectionCheck() {
    // _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
    //   if (_client != null && !_client!.isConnected()) {
    //     createDialogPopUp(
    //         context, "Disconnected", "The server conenction has closed.");
    //     setState(() {
    //       clientConnected = false;
    //     });
    //     _resetClient();
    //   }
    // });
  }

  void _stopConnectionCheck() {
    // if (_timer.isActive) {
    //   _timer.cancel();
    // }
  }

  void _resetClient() {
    setState(() {
      _client!.disconnect();
      _client = null;
      _connectBtnIcon = const Icon(Icons.link);
      _connectBtnColor = darkGreen;
      _fileData.clear();
    });
  }

  Future<void> _selectFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      File file = File(result.files.single.path!);
      Uint8List bytes = file.readAsBytesSync();
      String fileData = base64Encode(bytes);
      String fileName = p.basename(file.path);
      setState(() {
        _fileData[fileName] = fileData;
      });
    }
  }

  void _deleteFile(String fileName) {
    createConfirmDeleteDialogPopUp(context, () {
      setState(() {
        _fileData.remove(fileName);
      });
    });
  }
}
