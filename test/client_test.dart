import 'dart:async';
import 'dart:io';

import 'package:app/Classes/server/init.dart';
import 'package:app/Constants/functions.dart';
import 'package:flutter/foundation.dart';

Future<void> main() async {
  Address addr = Address("127.0.0.1", 9090);
  Client client = Client(addr);
  try {
    await client.connect();
  } on SocketException {
    if (kDebugMode) {
      print("failed to connect");
    }
    return;
  }

  sleep(const Duration(seconds: 2));
  client.sendMessage(createJsonMessage(metadata: "Hello Bish"));
}
