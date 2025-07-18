import 'package:app/Constants/functions.dart';
import 'package:hive/hive.dart';
part 'message.g.dart';

@HiveType(typeId: 0)
class Message extends HiveObject{
  @HiveField(0)
  late DateTime date;
  @HiveField(1)
  late String sender;
  @HiveField(2)
  late String message;
  @HiveField(3)
  late String content;
  @HiveField(4)
  late String fileSize;
  Message({required this.date, required this.sender, required this.message, required this.content})
      : fileSize = getFileSize(content);
  @override
  String toString() {
    return "$date - From: $sender, Message: '$message', Content: '$content'";
  }
}
