import 'dart:async';

import 'package:app/Classes/server/init.dart';

Future<void> main() async {
  int numOfClients = 5;
  Address addr = Address("127.0.0.1", 9090);

  for (int i = 0; i < numOfClients; i++) {
    Client client = Client(addr, "test_client_$i");
    await client.connect();
    client.sendMessage("test $i");
  }
}
