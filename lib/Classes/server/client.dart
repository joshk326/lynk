import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:app/Classes/server/address.dart';
import 'package:app/Constants/functions.dart';

class Client {
  late String name;
  late Socket socket;
  late Address _host;
  late bool _connected;
  Client(Address host) {
    _host = host;
    name = idGenerator();
    _connected = false;
  }

  Future<void> connect() async {
    try {
      socket = await Socket.connect(_host.ip(), _host.port());
    } catch (ex) {
      return;
    }
    _connected = true;

    // Sender client name back to server
    await sendMessage(createJsonMessage(metadata: name));
  }

  void disconnect() {
    socket.destroy();
    _connected = false;
  }

  bool isConnected() {
    return _connected;
  }

  Future<void> sendMessage(String jsonString) async {
    List<int> jsonBytes = utf8.encode(jsonString);
    int length = jsonBytes.length;
    ByteData lengthBytes = ByteData(4)..setUint32(0, length, Endian.big);

    socket.add(lengthBytes.buffer.asUint8List());
    socket.add(jsonBytes);
    await socket.flush();
  }
}
