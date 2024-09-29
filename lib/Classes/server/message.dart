class Message {
  late DateTime date;
  late String sender;
  late String message;
  Message(this.date, this.sender, this.message);
  String asString() {
    return "$date - From: $sender, Message: '$message'";
  }
}
