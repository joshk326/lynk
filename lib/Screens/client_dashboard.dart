import 'dart:async';
import 'package:app/Classes/server/server.dart';
import 'package:flutter/foundation.dart';

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
late Timer _heartBeatTimer;
bool sending = false;

class ClientDashboard extends StatefulWidget {
  const ClientDashboard({super.key});

  @override
  State<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends State<ClientDashboard> {
  var ipTxtContr = TextEditingController(
    text: _ipInputClient.isNotEmpty ? _ipInputClient : "",
  );

  var portTxtContr = TextEditingController(text: _portInputClient.isNotEmpty ? _portInputClient : "");

  @override
  void initState() {
    _heartBeatTimer = Timer(Duration.zero, () {});
    super.initState();
  }

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
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 50),
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
                      decoration: const InputDecoration(labelText: "Server IP", counterText: ""),
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
                      decoration: const InputDecoration(labelText: "Server Port", counterText: ""),
                      inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
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
                      tooltip: !clientConnected ? "Connect to Server" : "Disconnect from Server",
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
                    border: Border.all(color: flatBlack), borderRadius: const BorderRadius.all(Radius.circular(20))),
                child: Column(
                  children: [
                    IconButton(onPressed: () => _selectFile(), icon: const Icon(Icons.add)),
                    Expanded(
                        child: _fileData.isNotEmpty
                            ? AbsorbPointer(
                                absorbing: sending,
                                child: ListView.builder(
                                    itemCount: _fileData.length,
                                    itemBuilder: (context, index) {
                                      String fileName = _fileData.keys.elementAt(index);
                                      return ListTile(
                                        enabled: !sending,
                                        leading: const Icon(Icons.file_present),
                                        title: Text(fileName),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              onPressed: () => _sendFile(fileName),
                                              icon: sending ? const Icon(Icons.hourglass_full) : const Icon(Icons.send),
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
                                    }),
                              )
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
    if (!clientConnected && (_ipInputClient.isNotEmpty) && (_portInputClient.isNotEmpty)) {
      if ((validateIP(_ipInputClient)) && validatePort(_portInputClient)) {
        setState(() {
          _serverAddr = Address(_ipInputClient.trim(), int.parse(_portInputClient.trim()));
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
          createDialogPopUp(context.mounted ? context : null, "Error", "Connection failed");
        }
      } else {
        createDialogPopUp(context, "Error", "Invalid ip or port format");
      }
    } else if ((clientConnected && _client != null)) {
      setState(() {
        clientConnected = false;
      });
      _resetClient();
    } else {
      createDialogPopUp(context, "Error", "Please enter both an ip and port");
    }
  }

  void _startConnectionCheck() {
    _heartBeatTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      // Send heartbeat message
      if (!_client!.isConnected() || _client == null) {
        _resetClient();
        createDialogPopUp(context, "Disconnected", "The server conenction has closed.");
      } else {
        await _client!.sendMessage(createJsonMessage(metadata: heartBeat));
      }
    });
  }

  void _stopConnectionCheck() {
    if (_heartBeatTimer.isActive) {
      _heartBeatTimer.cancel();
    }
  }

  void _resetClient() {
    if (_client != null) {
      _client!.disconnect();
    }

    setState(() {
      clientConnected = false;
      _client = null;
      _connectBtnIcon = const Icon(Icons.link);
      _connectBtnColor = darkGreen;
      _fileData.clear();
    });
    _stopConnectionCheck();
  }

  Future<void> _selectFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      String filePath = result.files.single.path!;

      Map<String, String> processedFile = await compute(processFile, filePath);

      setState(() {
        _fileData[processedFile['fileName']!] = processedFile['fileData']!;
      });
    }
  }

  Future<void> _sendFile(String fileName) async {
    setState(() {
      sending = true;
    });

    // Stop the heartbeat check to ensure the stream is cleared
    _stopConnectionCheck();

    await Future.delayed(const Duration(milliseconds: 100));

    String fileData = _fileData[fileName]!;
    await _client!.sendMessage(createJsonMessage(
      metadata: _client!.name,
      fileName: fileName,
      fileContent: fileData,
    ));

    createDialogPopUp(context.mounted ? context : null, "Sent", "$fileName sent to server!");

    setState(() {
      sending = false;
    });
    //Start the heartbeat check
    _startConnectionCheck();
  }

  void _deleteFile(String fileName) {
    createConfirmDeleteDialogPopUp(context, () {
      setState(() {
        _fileData.remove(fileName);
      });
    });
  }
}
