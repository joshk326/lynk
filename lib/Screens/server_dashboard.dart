import 'dart:async';
import 'dart:convert';
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
String _serverIP = "";
String _portInputServer = "";
Address? _serverAddr;
Server? _server;
String _consoleOutput = "";
Icon _serverBtnIcon = const Icon(Icons.play_arrow);
Color _serverBtnColor = darkGreen;
bool _showConsole = false;
bool _clientsShown = false;
bool _messagesShown = false;
String _clientCount = "0";
String _fileCount = "0";
Map<Socket, String> _clients = {};
List<Message> _serverMessages = [];
late Timer _countsTimer;

class ServerDashboard extends StatefulWidget {
  const ServerDashboard({super.key});

  @override
  State<ServerDashboard> createState() => _ServerDashboardState();
}

class _ServerDashboardState extends State<ServerDashboard> {
  var portTxtContr = TextEditingController(
      text: _portInputServer.isNotEmpty ? _portInputServer : "");

  @override
  void initState() {
    _countsTimer = Timer(Duration.zero, () {});
    super.initState();
  }

  @override
  void dispose() {
    _stopCountCheck();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: serverRunning
          ? AppBar(
              title: Text(
                  "Server running on IP: $_serverIP, Port: $_portInputServer"),
              centerTitle: true,
              elevation: 1,
            )
          : null,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            alignment: AlignmentDirectional.center,
            children: [
              SingleChildScrollView(
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
                            enabled: !serverRunning,
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
                                            padding: const EdgeInsets.only(
                                                right: 20),
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
                                            title: Text(_clients.values
                                                .elementAt(index)),
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
                                            borderRadius:
                                                const BorderRadius.all(
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
                                        constraints: const BoxConstraints(
                                            maxHeight: 300),
                                        decoration: BoxDecoration(
                                            color: background,
                                            borderRadius:
                                                const BorderRadius.all(
                                                    Radius.circular(20))),
                                        child: ListView.builder(
                                          itemCount: _serverMessages.length,
                                          itemBuilder: (context, index) {
                                            final message = _serverMessages
                                                .elementAt(index);
                                            return ListTile(
                                              leading: const Icon(
                                                  Icons.file_present),
                                              subtitle: Text(
                                                  "From: ${message.sender}, Size: ${getFileSize(base64Decode(message.content))}"),
                                              title: Text(message.message),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                      onPressed: () async {
                                                        String? outputFile = await FilePicker
                                                            .platform
                                                            .saveFile(
                                                                dialogTitle:
                                                                    'Please select an output file:',
                                                                fileName: message
                                                                    .message,
                                                                bytes: base64Decode(
                                                                    message
                                                                        .content));
                                                        if (outputFile !=
                                                            null) {
                                                          File(outputFile)
                                                              .writeAsBytes(
                                                                  base64Decode(
                                                                      message
                                                                          .content));
                                                          createDialogPopUp(
                                                              context.mounted
                                                                  ? context
                                                                  : null,
                                                              "Saved",
                                                              "File saved to $outputFile");
                                                        }
                                                      },
                                                      icon: const Icon(
                                                          Icons.download)),
                                                  IconButton(
                                                    onPressed: () {
                                                      createConfirmDeleteDialogPopUp(
                                                          context, () {
                                                        setState(() {
                                                          _serverMessages
                                                              .removeAt(index);
                                                        });
                                                      });
                                                    },
                                                    icon: const Icon(
                                                        Icons.delete),
                                                  ),
                                                ],
                                              ),
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
                    alignment: (Platform.isWindows || Platform.isMacOS)
                        ? Alignment.bottomRight
                        : Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Stack(
                        children: [
                          FloatingActionButton(
                            backgroundColor: !_clientsShown
                                ? Theme.of(context)
                                    .floatingActionButtonTheme
                                    .backgroundColor
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
                          ),
                          Positioned(
                              right: 9,
                              top: 1,
                              child: !_clientsShown
                                  ? Text(
                                      _clientCount,
                                      style: TextStyle(color: background),
                                    )
                                  : const Text(""))
                        ],
                      ),
                    ),
                  )),
              Visibility(
                visible: serverRunning,
                child: Align(
                    alignment: (Platform.isWindows || Platform.isMacOS)
                        ? Alignment.bottomLeft
                        : Alignment.topLeft,
                    child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Stack(
                          children: [
                            FloatingActionButton(
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
                            ),
                            Positioned(
                                right: 9,
                                top: 1,
                                child: !_messagesShown
                                    ? Text(
                                        _fileCount,
                                        style: TextStyle(color: background),
                                      )
                                    : const Text(""))
                          ],
                        ))),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _runServer() async {
    _serverIP = await getLocalIPV4();
    if (!serverRunning &&
        (_serverIP.isNotEmpty) &&
        (_portInputServer.isNotEmpty)) {
      if ((validateIP(_serverIP)) && validatePort(_portInputServer)) {
        setState(() {
          _serverAddr = Address(_serverIP, int.parse(_portInputServer));
          _server = Server(_serverAddr!);
          _server!.start();
          serverRunning = _server!.isRunning();
          _serverBtnIcon = const Icon(Icons.stop);
          _serverBtnColor = Colors.red;
        });
        _countChecks();
      } else {
        createDialogPopUp(context.mounted ? context : null, "Error",
            "Invalid ip or port format");
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
        await _server!.stop();
        setState(() {});
      }
    } else {
      createDialogPopUp(
          context.mounted ? context : null,
          "Error",
          (_serverIP.isEmpty ? "Could not obtain local IP address.\n" : "") +
              (_portInputServer.isEmpty ? "Please input a valid port." : ""));
    }
  }

  bool _checkConsoleError() {
    if (_consoleOutput.contains(serverErrors["CONN_ERR"]!)) {
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
      setState(() {
        _clients = _server!.getClients();
        _clientCount = _clients.length.toString();
      });
    }
  }

  Future<void> _getServerMessages() async {
    if (serverRunning) {
      setState(() {
        _serverMessages = _server!.getMessages();
        _fileCount = _serverMessages.length.toString();
      });
    }
  }

  void _countChecks() {
    _countsTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (serverRunning) {
        _getClients();
        _getServerMessages();
      }
    });
  }

  void _stopCountCheck() {
    if (_countsTimer.isActive) {
      _countsTimer.cancel();
    }
  }
}
