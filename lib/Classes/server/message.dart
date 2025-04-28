class Message {
  late DateTime date;
  late String sender;
  late String message;
  late String content;
  Message(this.date, this.sender, this.message, this.content);
  @override
  String toString() {
    return "$date - From: $sender, Message: '$message', Content: '$content'";
  }
}
