import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:app/Classes/server/address.dart';
import 'package:app/Classes/server/message.dart';
import 'package:app/Constants/functions.dart';

class Client {
  late String name;
  late Socket socket;
  late Address _host;
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
