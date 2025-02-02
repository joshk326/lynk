import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:app/Classes/server/address.dart';
import 'package:app/Classes/server/message.dart';

final Map<String, String> ServerErrors = {
  'CONN_ERR': 'Failed to bind to given address and port'
};

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
      _writeConsole(ServerErrors['CONN_ERR']!);
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

  _decodeMsg(String data) {
    RegExp regExp = RegExp(
        r"(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{6}) - From: (\w+), Message: '(.*?)', Content: '(.*?)'");

    // Matching the pattern in the log string
    RegExpMatch? match = regExp.firstMatch(data);

    if (match != null) {
      String datetime = match.group(1)!;
      String fromName = match.group(2)!;
      String message = match.group(3)!;
      String content = match.group(4)!;

      return Message(DateTime.parse(datetime), fromName, message, content);
    } else {
      return Null;
    }
  }

  void _broadcastMessage(Socket sender, String message,
      [bool toSender = false]) {
    Message broadcast;
    if (!toSender) {
      for (Socket c in _clients.keys) {
        if (c != sender && message != _clients[sender]) {
          broadcast = Message(DateTime.now(), _clients[sender]!, message, "");
          c.add(utf8.encode(broadcast.asString()));
          _messages.add(broadcast);
        }
      }
    } else {
      broadcast = Message(DateTime.now(), "Server", message, "");
      sender.add(utf8.encode(broadcast.asString()));
    }
  }

  void _handleConnection(Socket client) {
    _writeConsole(
        "${DateTime.now()} - Server: Connection from ${client.address}:${client.remotePort}");
    client.listen(
      (Uint8List data) async {
        final message = String.fromCharCodes(data);
        if (!_checkClientExists(client)) {
          _clients[client] = message;
          _broadcastMessage(client, "You are logged in as: $message", true);
        }
        var tmp = _decodeMsg(message);
        if (tmp != Null) {
          _messages.add(tmp);
          _writeConsole("Received: $tmp");
        }
        // Enable if you want to send messages back out to all other clients
        // _broadcastMessage(client, message);
      },
      onDone: () {
        _writeConsole("${client.address}:${client.remotePort} disconnected");
        _clients.remove(client);
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
