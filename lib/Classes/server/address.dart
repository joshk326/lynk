class Address {
  final String _ip;
  final int _port;
  Address(String ip, int port)
      : _ip = ip,
        _port = port;
  String ip() {
    return _ip;
  }

  int port() {
    return _port;
  }
}
