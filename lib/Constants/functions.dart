bool validateIP(var input) {
  List<String> octets = input.split('.');

  if (octets.length != 4) {
    return false;
  }

  for (String octet in octets) {
    if (!isNumeric(octet)) {
      return false;
    }

    int num = int.parse(octet);
    if (num < 0 || num > 255) {
      return false;
    }

    if (octet.length > 1 && octet[0] == '0') {
      return false;
    }
  }

  return true;
}

bool validatePort(var input) {
  if (!isNumeric(input)) {
    return false;
  }

  int num = int.parse(input);
  if (num < 0 || num > 65535) {
    return false;
  }

  return true;
}

bool isNumeric(String s) {
  return double.tryParse(s) != null;
}
