import 'dart:async';
import 'dart:io';

import 'package:app/Classes/server/init.dart';

Future<void> main() async {
  Address addr = Address("127.0.0.1", 9090);
  Client client = Client(addr, "test_client");
  try {
    await client.connect();
  } on SocketException {
    print("failed to connect");
    return;
  }

  sleep(const Duration(seconds: 2));
  client.sendMessage("Hello Bish");
}