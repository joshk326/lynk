import 'dart:async';

import 'package:app/Classes/server/init.dart';

Future<void> main() async {
  Address addr = Address("127.0.0.1", 9090);
  Client client = Client(addr, "test_client2");
  client.connect();
}
