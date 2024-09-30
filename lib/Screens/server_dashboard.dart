import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:app/Classes/server/init.dart';
import 'package:app/Constants/functions.dart';
import 'package:app/Constants/theme.dart';
import 'package:app/Widgets/alert.dart';

// Global variables
String ipInput = "";
String portInput = "";
bool serverRunning = false;
Address? serverAddr;
Server? server;
String consoleOutput = "";
Icon serverBtnIcon = const Icon(Icons.play_arrow);
Color serverBtnColor = darkGreen;
bool showConsole = false;
bool clientsShown = false;
Map<Socket, String> clients = {};

class ServerDashboard extends StatefulWidget {
  const ServerDashboard({super.key});

  @override
  State<ServerDashboard> createState() => _ServerDashboardState();
}

class _ServerDashboardState extends State<ServerDashboard> {
  var ipTxtContr = TextEditingController(
    text: ipInput.isNotEmpty ? ipInput : "",
  );

  var portTxtContr =
      TextEditingController(text: portInput.isNotEmpty ? portInput : "");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Visibility(
          visible: serverRunning,
          child: FloatingActionButton(
            backgroundColor: !clientsShown
                ? Theme.of(context).floatingActionButtonTheme.backgroundColor
                : flatRed,
            onPressed: () {
              setState(() {
                clientsShown = !clientsShown;
              });
            },
            child: !clientsShown
                ? const Icon(Icons.person)
                : const Icon(Icons.close),
          )),
      body: Center(
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  constraints: const BoxConstraints(maxWidth: 650),
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 50),
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
                            ipInput = value;
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
                            portInput = value;
                          });
                        },
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      IconButton(
                        icon: serverBtnIcon,
                        color: serverBtnColor,
                        onPressed: () => runServer(),
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
                          value: showConsole,
                          onChanged: (context) {
                            setState(() {
                              showConsole = !showConsole;
                            });
                          }),
                    ],
                  ),
                ),
                Visibility(
                  visible: showConsole,
                  child: StreamBuilder(
                      stream: Stream.periodic(const Duration(seconds: 1))
                          .asyncMap((i) => getConsoleData()),
                      builder: (context, snapshot) {
                        var data = snapshot.data;
                        if (serverRunning && (data != null)) {
                          for (String item in data) {
                            if (!consoleOutput.contains(item)) {
                              consoleOutput = "$consoleOutput\n$item";
                            }
                          }
                        } else {
                          consoleOutput = "";
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
                                        child: Text(consoleOutput))),
                              ],
                            ));
                      }),
                ),
              ],
            ),
            Visibility(
              visible: clientsShown,
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
                            future: getClients(),
                            builder: (context, snapshot) {
                              if (serverRunning && clients.isNotEmpty) {
                                return Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    constraints: const BoxConstraints(maxHeight: 300),
                                    decoration: BoxDecoration(
                                        color: background,
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(20))),
                                    child: ListView.builder(
                                      itemCount: clients.length,
                                      itemBuilder: (context, index) {
                                        return ListTile(
                                          leading: const Icon(Icons.person),
                                          title: Text(
                                              clients.values.elementAt(index)),
                                          subtitle: Text(
                                              "${clients.keys.elementAt(index).remoteAddress.address}:${clients.keys.elementAt(index).remotePort}"),
                                          trailing: Text(
                                              "${clients.keys.elementAt(index).remoteAddress.type}"),
                                        );
                                        // Text(
                                        //   "Name: ${clients.values.elementAt(index)}, Address: ${clients.keys.elementAt(index).address.address}: ${clients.keys.elementAt(index).port}");
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
            )
          ],
        ),
      ),
    );
  }

  void runServer() {
    if (!serverRunning && (ipInput.isNotEmpty) && (portInput.isNotEmpty)) {
      if ((validateIP(ipInput)) && validatePort(portInput)) {
        setState(() {
          serverAddr = Address(ipInput, int.parse(portInput));
          server = Server(serverAddr!);
          server!.start();
          serverRunning = server!.isRunning();
          serverBtnIcon = const Icon(Icons.stop);
          serverBtnColor = Colors.red;
        });
      } else {
        createDialogPopUp(context, "Error", "Invalid ip or port format");
      }
    } else if (serverRunning && server != null) {
      // Do some error checking - kind of looks gross...
      setState(() {
        serverRunning = false;
      });
      setState(() {
        serverBtnIcon = const Icon(Icons.play_arrow);
        serverBtnColor = darkGreen;
        clients.clear();
      });
      if (!checkConsoleError()) {
        setState(() {
          server!.stop();
        });
      }
    } else {
      createDialogPopUp(context, "Error", "Please enter both an ip and port");
    }
  }

  bool checkConsoleError() {
    if (consoleOutput.contains(ServerErrors["CONN_ERR"]!)) {
      return true;
    }
    return false;
  }

  List<String> getConsoleData() {
    List<String> retVal = [];
    if (serverRunning) {
      retVal = server!.getConsoleOutput();
    } else {
      retVal = [""];
    }
    return retVal;
  }

  Future<void> getClients() async {
    if (serverRunning) {
      clients = server!.getClients();
    }
  }
}
