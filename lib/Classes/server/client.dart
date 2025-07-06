import 'dart:convert';
import 'dart:io';

import 'package:app/Classes/server/init.dart';
import 'package:app/Constants/functions.dart';
import 'package:flutter/foundation.dart';

class Client {
  late String name;
  late SecureSocket socket;
  late Address _host;
  late bool _connected;
  Client(Address host) {
    _host = host;
    name = idGenerator();
    _connected = false;
  }

  Future<void> connect() async {
    try {
      socket = await SecureSocket.connect(_host.ip(), _host.port(), onBadCertificate: (X509Certificate certificate) {
        // Accept self signed certificate
        return true;
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error: $e");
      }
      return;
    }

    _connected = true;

    // Sender client name back to server
    await sendMessage(createJsonMessage(metadata: name));

    _handleConnection(socket);
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

    var lengthStream = Stream.value(lengthBytes.buffer.asUint8List());
    var jsonByteStream = Stream.value(jsonBytes);

    await socket.addStream(lengthStream);
    await socket.addStream(jsonByteStream);
    await socket.flush();
  }

  void _handleConnection(SecureSocket client) {
    client.listen(
      (Uint8List data) async {
        String msg = decodeJsonMessage(String.fromCharCodes(data))["metadata"]["message"];

        if (msg.isEmpty || !msg.contains(heartBeat)) {
          disconnect();
        }
      },
      onError: (error) {
        disconnect();
        return;
      },
      onDone: () {
        _connected = false;
      },
    );
  }
}
