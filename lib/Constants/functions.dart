import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

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

String idGenerator() {
  final now = DateTime.now();
  return now.microsecondsSinceEpoch.toString();
}

String createJsonMessage({String metadata = "", String fileName = "", String fileContent = "", String message = ""}) {
  var tmp = {
    "message": {"date": DateTime.now().toString(), "file_name": fileName, "contents": fileContent},
    "metadata": {"message": metadata}
  };
  return jsonEncode(tmp);
}

Map decodeJsonMessage(String jsonString) {
  var tmp = jsonDecode(jsonString);
  return tmp;
}

Future<String> getLocalIPV4() async {
  try {
    List<NetworkInterface> interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);

    for (var interface in interfaces) {
      for (var address in interface.addresses) {
        if (!address.isLoopback) {
          return address.address;
        }
      }
    }
    return "";
  } catch (e) {
    if (kDebugMode) {
      print("Error: $e");
    }
    return "";
  }
}

String getFileSize(String source) {
  Uint8List bytes = base64Decode(source);
  int bytesLength = bytes.lengthInBytes;

  if (bytesLength < 1024) {
    return '$bytesLength B';
  } else if (bytesLength < 1024 * 1024) {
    double kbSize = bytesLength / 1024;
    return '${kbSize.toStringAsFixed(2)} KB';
  } else if (bytesLength < 1024 * 1024 * 1024) {
    double mbSize = bytesLength / (1024 * 1024);
    return '${mbSize.toStringAsFixed(2)} MB';
  } else {
    double gbSize = bytesLength / (1024 * 1024 * 1024);
    return '${gbSize.toStringAsFixed(2)} GB';
  }
}

Map<String, String> processFile(String filePath) {
  File file = File(filePath);
  Uint8List bytes = file.readAsBytesSync();
  String fileData = base64Encode(bytes);
  String fileName = p.basename(file.path);

  return {'fileName': fileName, 'fileData': fileData};
}
