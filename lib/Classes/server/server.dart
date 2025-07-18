import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:app/Classes/server/address.dart';
import 'package:app/Classes/server/message.dart';
import 'package:app/Constants/functions.dart';
import 'package:app/Constants/variables.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/services.dart' show rootBundle;
import 'package:optional/optional.dart';

final Map<String, String> serverErrors = {'CONN_ERR': 'Failed to bind to given address and port'};

class _ClientBuffer {
  List<int> buffer = [];
  int? expectedLength;
}

const String heartBeat = "HEARTBEAT";

final Map<Socket, _ClientBuffer> _buffers = {};

class Server {
  late Address address;
  late SecureServerSocket _server;
  final List<String> _consoleOutput = [];
  final Map<SecureSocket, String> _clients = {};
  final List<Message> _messages = [];
  late bool _running;

  Server(this.address);

  Future<void> _createSocket() async {
    final certificateBytes = (await rootBundle.load('assets/security/dev_server_cert.pem')).buffer.asUint8List();
    final keyBytes = (await rootBundle.load('assets/security/dev_server_key.pem')).buffer.asUint8List();

    final SecurityContext serverContext = SecurityContext()
      ..useCertificateChainBytes(certificateBytes)
      ..usePrivateKeyBytes(keyBytes);

    try {
      _server = await SecureServerSocket.bind(address.ip(), address.port(), serverContext);
    } catch (e) {
      _writeConsole(serverErrors['CONN_ERR']!);
      _running = false;
      return;
    }

    _writeConsole("${DateTime.now()} - Server is running on: ${address.ip()}:${address.port()}");
    _server.listen((SecureSocket client) {
      _handleConnection(client);
    });
  }

  void _writeConsole(String msg) {
    if (msg.isNotEmpty) {
      if (kDebugMode) {
        print(msg);
      }
      _consoleOutput.add(msg);
    }
  }

  bool _checkClientExists(SecureSocket client) {
    for (SecureSocket item in _clients.keys) {
      if (item == client) {
        return true;
      }
    }
    return false;
  }

  Optional<Message> _decodeMsg(String data) {
    if (data.isNotEmpty) {
      Map tmp = decodeJsonMessage(data);
      Message tmpMsg = Message(
          date: DateTime.parse(tmp["message"]["date"]),
          sender: tmp["metadata"]["message"],
          message: tmp["message"]["file_name"],
          content: tmp["message"]["contents"]);
      return Optional.of(tmpMsg);
    } else {
      return const Optional.empty();
    }
  }

  void _broadcastMessage(Socket sender, String message, [bool toSender = false]) {
    Message broadcast;
    if (!toSender) {
      for (Socket c in _clients.keys) {
        if (c != sender && message != _clients[sender]) {
          broadcast = Message(date: DateTime.now(), sender: _clients[sender]!, message: message, content: "");
          c.write(createJsonMessage(metadata: broadcast.toString()));
          _messages.add(broadcast);
        }
      }
    } else {
      broadcast = Message(date: DateTime.now(), sender: "Server", message: message, content: "");
      sender.write(createJsonMessage(metadata: broadcast.toString()));
    }
  }

  void _handleConnection(SecureSocket client) {
    _writeConsole("${DateTime.now()} - Server: Connection from ${client.address}:${client.remotePort}");

    _buffers[client] = _ClientBuffer();

    client.listen(
      (Uint8List data) async {
        final buf = _buffers[client]!;
        buf.buffer.addAll(data);

        while (true) {
          if (buf.expectedLength == null && buf.buffer.length >= 4) {
            final lengthBytes = buf.buffer.sublist(0, 4);
            buf.expectedLength = ByteData.sublistView(Uint8List.fromList(lengthBytes)).getUint32(0, Endian.big);
            buf.buffer.removeRange(0, 4);
          }

          if (buf.expectedLength != null && buf.buffer.length >= buf.expectedLength!) {
            final messageBytes = buf.buffer.sublist(0, buf.expectedLength!);
            final message = utf8.decode(messageBytes);

            buf.buffer.removeRange(0, buf.expectedLength!);
            buf.expectedLength = null;

            if (!_checkClientExists(client)) {
              _clients[client] = decodeJsonMessage(message)["metadata"]["message"];
              _broadcastMessage(client, "You are logged in, $heartBeat", true);
            } else {
              Optional<Message> tmp = _decodeMsg(message);

              if (tmp.isPresent) {
                if (!tmp.value.sender.contains(heartBeat)) {
                  await box.add(tmp.value);
                  String fileName = tmp.value.message;
                  _writeConsole("Received: $fileName");
                } else {
                  _broadcastMessage(client, heartBeat, true);
                }
              }
            }
          } else {
            break;
          }
        }
      },
      onDone: () {
        _writeConsole("${client.address}:${client.remotePort} disconnected");
        _clients.remove(client);
        _buffers.remove(client);
      },
    );
  }

  List<String> getConsoleOutput() {
    return _consoleOutput;
  }

  Map<SecureSocket, String> getClients() {
    return _clients;
  }

  void start() {
    _running = true;
    _createSocket();
  }

  Future<void> stop() async {
    if (_running) {
      for (Socket client in _buffers.keys) {
        _broadcastMessage(client, "disconnected", true);
      }
      _running = false;
      await _server.close();
      _writeConsole("${DateTime.now()} - Server: Closed connection");
    }
  }

  bool isRunning() {
    return _running;
  }
}
