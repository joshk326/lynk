import 'dart:io';
import 'dart:typed_data';

import 'package:app/Classes/server/address.dart';
import 'package:app/Classes/server/message.dart';

class Client {
  late String _name;
  late Address _host;
  late Socket _socket;
  late bool _connected;
  final List<Message> _messages = [];
  Client(Address host, String name) {
    _host = host;
    _name = name;
    _connected = false;
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

  Future<void> connect() async {
    _socket = await Socket.connect(_host.ip(), _host.port());
    _connected = true;
    print("Connected to ${_socket.remoteAddress}:${_socket.remotePort}");

    // Sender client name back to server
    _socket.write(_name);

    _socket.listen(
      (Uint8List data) {
        final serverResponse = String.fromCharCodes(data);
        var asObj = _decodeMsg(serverResponse);
        if (asObj != Null) {
          _messages.add(asObj);
          print(serverResponse);
        }
      },
      onError: (error) {
        print("Client: $error");
        _socket.destroy();
      },
      onDone: () {
        print('Client: Server closed');
        _socket.destroy();
      },
    );
  }

  void disconnect() {
    _socket.destroy();
    _connected = false;
  }

  bool isConnected() {
    return _connected;
  }

  void sendMessage(String message, String content) {
    if (_socket != Null) {
      _socket.write(
          "${DateTime.now()} - From: $_name, Message: '$message', Content: '$content'");
    }
  }
}
