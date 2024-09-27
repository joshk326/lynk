import 'dart:io';
import 'dart:typed_data';
import 'package:app/Classes/server/address.dart';
import 'package:app/Classes/server/message.dart';

class Server {
  late Address address;
  late ServerSocket _server;
  final Map<Socket, String> _clients = {};
  final List<Message> _messages = [];
  late bool _running;

  Server(this.address);

  Future<void> _createSocket() async {
    _server = await ServerSocket.bind(address.ip(), address.port());
    print("Server is running on: ${address.ip()}:${address.port()}");
    _server.listen((Socket client) {
      _handleConnection(client);
    });
  }

  bool _checkClientExists(Socket client) {
    for (Socket item in _clients.keys) {
      if (item == client) {
        return true;
      }
    }
    return false;
  }

  void _broadcastMessage(Socket sender, String message) {
    for (Socket item in _clients.keys) {
      if (item != sender && message != _clients[sender]) {
        Message broadcast = Message(DateTime.now(), _clients[sender]!, message);
        item.write(
            "${broadcast.date} - From: ${broadcast.sender}, Message: '${broadcast.message}'");
        _messages.add(broadcast);
      }
    }
  }

  void _handleConnection(Socket client) {
    print("Server: Connection from ${client.address}:${client.remotePort}");
    client.listen(
      (Uint8List data) async {
        final message = String.fromCharCodes(data);

        if (!_checkClientExists(client)) {
          _clients[client] = message;
          client.write("Server: You are logged in as: $message");
        }

        _broadcastMessage(client, message);
      },
      onDone: () {
        print("${client.address}:${client.remotePort} disconnected");
        _clients.remove(client);
      },
    );
  }

  List<Message> getMessages() {
    return _messages;
  }

  void start() {
    _running = true;
    _createSocket();
  }

  void stop() {
    if (_running) {
      _server.close();
    }
  }
}
