import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:app/Classes/server/address.dart';
import 'package:app/Classes/server/message.dart';
import 'package:app/Constants/functions.dart';
import 'package:optional/optional.dart';

final Map<String, String> serverErrors = {
  'CONN_ERR': 'Failed to bind to given address and port'
};

class _ClientBuffer {
  List<int> buffer = [];
  int? expectedLength;
}

final Map<Socket, _ClientBuffer> _buffers = {};

class Server {
  late Address address;
  late ServerSocket _server;
  final List<String> _consoleOutput = [];
  final Map<Socket, String> _clients = {};
  final List<Message> _messages = [];
  late bool _running;

  Server(this.address);

  Future<void> _createSocket() async {
    try {
      _server = await ServerSocket.bind(address.ip(), address.port());
    } on SocketException {
      _writeConsole(serverErrors['CONN_ERR']!);
      _running = false;
      return;
    }

    _writeConsole(
        "${DateTime.now()} - Server is running on: ${address.ip()}:${address.port()}");
    _server.listen((Socket client) {
      _handleConnection(client);
    });
  }

  void _writeConsole(String msg) {
    if (msg.isNotEmpty) {
      print(msg);
      _consoleOutput.add(msg);
    }
  }

  bool _checkClientExists(Socket client) {
    for (Socket item in _clients.keys) {
      if (item == client) {
        return true;
      }
    }
    return false;
  }

  Optional<Message> _decodeMsg(String data) {
    if (data.isNotEmpty) {
      Map tmp = decodeJsonMessage(data);
      return Optional.of(Message(
          DateTime.parse(tmp["message"]["date"]),
          tmp["metadata"]["message"],
          tmp["message"]["file_name"],
          tmp["message"]["contents"]));
    } else {
      return const Optional.empty();
    }
  }

  void _broadcastMessage(Socket sender, String message,
      [bool toSender = false]) {
    Message broadcast;
    if (!toSender) {
      for (Socket c in _clients.keys) {
        if (c != sender && message != _clients[sender]) {
          broadcast = Message(DateTime.now(), _clients[sender]!, message, "");
          c.write(createJsonMessage(metadata: broadcast.toString()));
          _messages.add(broadcast);
        }
      }
    } else {
      broadcast = Message(DateTime.now(), "Server", message, "");
      sender.write(createJsonMessage(metadata: broadcast.toString()));
    }
  }

  void _handleConnection(Socket client) {
    _writeConsole(
        "${DateTime.now()} - Server: Connection from ${client.address}:${client.remotePort}");

    _buffers[client] = _ClientBuffer();

    client.listen(
      (Uint8List data) async {
        final buf = _buffers[client]!;
        buf.buffer.addAll(data);

        while (true) {
          if (buf.expectedLength == null && buf.buffer.length >= 4) {
            final lengthBytes = buf.buffer.sublist(0, 4);
            buf.expectedLength =
                ByteData.sublistView(Uint8List.fromList(lengthBytes))
                    .getUint32(0, Endian.big);
            buf.buffer.removeRange(0, 4);
          }

          if (buf.expectedLength != null &&
              buf.buffer.length >= buf.expectedLength!) {
            final messageBytes = buf.buffer.sublist(0, buf.expectedLength!);
            final message = utf8.decode(messageBytes);

            buf.buffer.removeRange(0, buf.expectedLength!);
            buf.expectedLength = null;

            if (!_checkClientExists(client)) {
              _clients[client] =
                  decodeJsonMessage(message)["metadata"]["message"];
              _broadcastMessage(client, "You are logged in as: $message", true);
            } else {
              Optional<Message> tmp = _decodeMsg(message);
              if (tmp.isPresent) {
                _messages.add(tmp.value);
                String fileName = tmp.value.message;
                _writeConsole("Received: $fileName");
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

  List<Message> getMessages() {
    return _messages;
  }

  List<String> getConsoleOutput() {
    return _consoleOutput;
  }

  Map<Socket, String> getClients() {
    return _clients;
  }

  void start() {
    _running = true;
    _createSocket();
  }

  Future<void> stop() async {
    if (_running) {
      _running = false;
      await _server.close();
      _writeConsole("${DateTime.now()} - Server: Closed connection");
    }
  }

  bool isRunning() {
    return _running;
  }
}
