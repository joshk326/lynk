import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:app/Classes/server/address.dart';
import 'package:app/Classes/server/message.dart';
import 'package:app/Constants/functions.dart';

class Client {
  late String name;
  late Address _host;
  late Socket _socket;
  late bool _connected;
  final List<Message> _messages = [];
  Client(Address host) {
    _host = host;
    name = idGenerator();
    _connected = false;
  }

  _decodeMsg(String data) {
    if (data.isNotEmpty) {
      Map tmp = decodeJsonMessage(data);
      return Message(
          DateTime.parse(tmp["message"]["date"]),
          tmp["metadata"]["message"],
          tmp["message"]["file_name"],
          tmp["message"]["contents"]);
    } else {
      return Null;
    }
  }

  Future<void> connect() async {
    try {
      _socket = await Socket.connect(_host.ip(), _host.port());
    } catch (ex) {
      return;
    }
    _connected = true;

    // Sender client name back to server
    await sendMessage(createJsonMessage(metadata: name));

    _socket.listen(
      (Uint8List data) {
        final serverResponse = String.fromCharCodes(data);
        var asObj = _decodeMsg(serverResponse);
        if (asObj != Null) {
          _messages.add(asObj);
        }
      },
      onError: (error) {
        _socket.destroy();
      },
      onDone: () {
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

  Future<void> sendMessage(String jsonString) async {
    List<int> jsonBytes = utf8.encode(jsonString);
    int length = jsonBytes.length;
    ByteData lengthBytes = ByteData(4)..setUint32(0, length, Endian.big);

    _socket.add(lengthBytes.buffer.asUint8List());
    _socket.add(jsonBytes);
    await _socket.flush();
  }
}
