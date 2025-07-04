import 'package:app/Constants/functions.dart';

class Message {
  late DateTime date;
  late String sender;
  late String message;
  late String content;
  late String fileSize;
  Message({required this.date, required this.sender, required this.message, required this.content})
      : fileSize = getFileSize(content);
  @override
  String toString() {
    return "$date - From: $sender, Message: '$message', Content: '$content'";
  }
}
