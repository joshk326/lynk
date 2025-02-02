import 'dart:io';

import 'package:app/Constants/variables.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:app/Classes/server/init.dart';
import 'package:app/Constants/functions.dart';
import 'package:app/Constants/theme.dart';
import 'package:app/Widgets/alert.dart';

// Global variables
String _ipInputServer = "";
String _portInputServer = "";
Address? _serverAddr;
Server? _server;
String _consoleOutput = "";
Icon _serverBtnIcon = const Icon(Icons.play_arrow);
Color _serverBtnColor = darkGreen;
bool _showConsole = false;
bool _clientsShown = false;
bool _messagesShown = false;
Map<Socket, String> _clients = {};
List<Message> _serverMessages = [];

class ServerDashboard extends StatefulWidget {
  const ServerDashboard({super.key});

  @override
  State<ServerDashboard> createState() => _ServerDashboardState();
}

class _ServerDashboardState extends State<ServerDashboard> {
  var ipTxtContr = TextEditingController(
    text: _ipInputServer.isNotEmpty ? _ipInputServer : "",
  );

  var portTxtContr = TextEditingController(
      text: _portInputServer.isNotEmpty ? _portInputServer : "");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Visibility(
          visible: serverRunning,
          child: FloatingActionButton(
            backgroundColor: !_clientsShown
                ? Theme.of(context).floatingActionButtonTheme.backgroundColor
                : flatRed,
            onPressed: () {
              setState(() {
                if (_messagesShown) {
                  _messagesShown = !_messagesShown;
                }
                _clientsShown = !_clientsShown;
              });
            },
            child: !_clientsShown
                ? const Icon(Icons.person)
                : const Icon(Icons.close),
          )),
      body: Center(
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(right: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    constraints: const BoxConstraints(maxWidth: 650),
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 50),
                    decoration: BoxDecoration(
                        color: background,
                        border: Border.all(color: flatBlack),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(20))),
                    child: Column(
                      children: [
                        TextField(
                          controller: ipTxtContr,
                          maxLength: 15,
                          decoration: const InputDecoration(
                              labelText: "IP", counterText: ""),
                          onChanged: (value) {
                            setState(() {
                              _ipInputServer = value;
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
                              _portInputServer = value;
                            });
                          },
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        IconButton(
                          icon: _serverBtnIcon,
                          color: _serverBtnColor,
                          onPressed: () => _runServer(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Visibility(
                    visible: serverRunning,
                    child: Wrap(
                      spacing: 5,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: Text("Show Console"),
                        ),
                        Switch(
                            value: _showConsole,
                            onChanged: (context) {
                              setState(() {
                                _showConsole = !_showConsole;
                              });
                            }),
                      ],
                    ),
                  ),
                  Visibility(
                    visible: _showConsole,
                    child: StreamBuilder(
                        stream: Stream.periodic(const Duration(seconds: 1))
                            .asyncMap((i) => _getConsoleData()),
                        builder: (context, snapshot) {
                          var data = snapshot.data;
                          if (serverRunning && (data != null)) {
                            for (String item in data) {
                              if (!_consoleOutput.contains(item)) {
                                _consoleOutput = "$_consoleOutput\n$item";
                              }
                            }
                          } else {
                            _consoleOutput = "";
                          }
                          return Container(
                              height: 200,
                              width: 650,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                  border: Border.all(color: flatBlack),
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(20))),
                              child: Column(
                                children: [
                                  Text(
                                    "Console Output",
                                    style: TextStyle(
                                      color: darkGreen,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Expanded(
                                      child: SingleChildScrollView(
                                          padding:
                                              const EdgeInsets.only(right: 20),
                                          child: Text(_consoleOutput))),
                                ],
                              ));
                        }),
                  ),
                ],
              ),
            ),
            Visibility(
              visible: _clientsShown,
              child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: flatBlack.withAlpha(98),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: FutureBuilder(
                            future: _getClients(),
                            builder: (context, snapshot) {
                              if (serverRunning && _clients.isNotEmpty) {
                                return Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    constraints:
                                        const BoxConstraints(maxHeight: 300),
                                    decoration: BoxDecoration(
                                        color: background,
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(20))),
                                    child: ListView.builder(
                                      itemCount: _clients.length,
                                      itemBuilder: (context, index) {
                                        return ListTile(
                                          leading: const Icon(Icons.person),
                                          title: Text(
                                              _clients.values.elementAt(index)),
                                          subtitle: Text(
                                              "${_clients.keys.elementAt(index).remoteAddress.address}:${_clients.keys.elementAt(index).remotePort}"),
                                          trailing: Text(
                                              "${_clients.keys.elementAt(index).remoteAddress.type}"),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              } else {
                                return Center(
                                  child: Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                          color: background,
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(20))),
                                      child:
                                          const Text("No clients connected")),
                                );
                              }
                            }),
                      ),
                    ],
                  )),
            ),
            Visibility(
                visible: _messagesShown,
                child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: flatBlack.withAlpha(98),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: FutureBuilder(
                              future: _getServerMessages(),
                              builder: (context, snapshot) {
                                if (serverRunning &&
                                    _serverMessages.isNotEmpty) {
                                  return Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      constraints:
                                          const BoxConstraints(maxHeight: 300),
                                      decoration: BoxDecoration(
                                          color: background,
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(20))),
                                      child: ListView.builder(
                                        itemCount: _serverMessages.length,
                                        itemBuilder: (context, index) {
                                          return ListTile(
                                            leading:
                                                const Icon(Icons.file_present),
                                            subtitle: Text(
                                                "From: ${_serverMessages.elementAt(index).sender}"),
                                            title: Text(_serverMessages
                                                .elementAt(index)
                                                .message),
                                            trailing: IconButton(
                                                onPressed: () async {
                                                  String? outputFile = await FilePicker
                                                      .platform
                                                      .saveFile(
                                                          dialogTitle:
                                                              'Please select an output file:',
                                                          fileName:
                                                              _serverMessages
                                                                  .elementAt(
                                                                      index)
                                                                  .message,
                                                          bytes: Uint8List.fromList(
                                                              _serverMessages
                                                                  .elementAt(
                                                                      index)
                                                                  .content
                                                                  .split(" ")
                                                                  .map(
                                                                      int.parse)
                                                                  .toList()));

                                                  if (outputFile == null) {
                                                    // User canceled the picker
                                                  } else {
                                                    createDialogPopUp(
                                                        context,
                                                        "Saved",
                                                        "File saved to $outputFile");
                                                  }
                                                },
                                                icon:
                                                    const Icon(Icons.download)),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                } else {
                                  return Center(
                                    child: Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                            color: background,
                                            borderRadius:
                                                const BorderRadius.all(
                                                    Radius.circular(20))),
                                        child:
                                            const Text("No files receieved")),
                                  );
                                }
                              }),
                        ),
                      ],
                    ))),
            Visibility(
              visible: serverRunning,
              child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: FloatingActionButton(
                        backgroundColor: !_messagesShown
                            ? Theme.of(context)
                                .floatingActionButtonTheme
                                .backgroundColor
                            : flatRed,
                        onPressed: () {
                          setState(() {
                            if (_clientsShown) {
                              _clientsShown = !_clientsShown;
                            }
                            _messagesShown = !_messagesShown;
                          });
                        },
                        child: !_messagesShown
                            ? const Icon(Icons.file_open)
                            : const Icon(Icons.close),
                      ))),
            )
          ],
        ),
      ),
    );
  }

  void _runServer() {
    if (!serverRunning &&
        (_ipInputServer.isNotEmpty) &&
        (_portInputServer.isNotEmpty)) {
      if ((validateIP(_ipInputServer)) && validatePort(_portInputServer)) {
        setState(() {
          _serverAddr = Address(_ipInputServer, int.parse(_portInputServer));
          _server = Server(_serverAddr!);
          _server!.start();
          serverRunning = _server!.isRunning();
          _serverBtnIcon = const Icon(Icons.stop);
          _serverBtnColor = Colors.red;
        });
      } else {
        createDialogPopUp(context, "Error", "Invalid ip or port format");
      }
    } else if (serverRunning && _server != null) {
      // Do some error checking - kind of looks gross...
      setState(() {
        serverRunning = false;
      });
      setState(() {
        _serverBtnIcon = const Icon(Icons.play_arrow);
        _serverBtnColor = darkGreen;
        _clients.clear();
        _serverMessages.clear();
        _showConsole = false;
      });
      if (!_checkConsoleError()) {
        setState(() {
          _server!.stop();
        });
      }
    } else {
      createDialogPopUp(context, "Error", "Please enter both an ip and port");
    }
  }

  bool _checkConsoleError() {
    if (_consoleOutput.contains(ServerErrors["CONN_ERR"]!)) {
      return true;
    }
    return false;
  }

  List<String> _getConsoleData() {
    List<String> retVal = [];
    if (serverRunning) {
      retVal = _server!.getConsoleOutput();
    } else {
      retVal = [""];
    }
    return retVal;
  }

  Future<void> _getClients() async {
    if (serverRunning) {
      _clients = _server!.getClients();
    }
  }

  Future<void> _getServerMessages() async {
    if (serverRunning) {
      _serverMessages = _server!.getMessages();
    }
  }
}
