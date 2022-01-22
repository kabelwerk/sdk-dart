class User {
  final int id;
  final String key;
  final String name;

  User({required this.id, required this.key, required this.name});

  User.fromPayload(Map payload)
      : id = payload['id'],
        key = payload['key'],
        name = payload['name'];
}

class InboxItem {
  final InboxItemRoom room;
  final Message? message;
  final bool isNew;

  InboxItem.fromPayload(Map payload, User user)
      : room = InboxItemRoom.fromPayload(payload['room']),
        message = payload['message'] == null
            ? null
            : Message.fromPayload(payload['message']),
        isNew = !payload['marked_by'].contains(user.id);
}

class InboxItemRoom {
  final int id;
  final int hubId;

  InboxItemRoom.fromPayload(Map payload)
      : id = payload['id'],
        hubId = payload['hub_id'];
}

class Message {
  final int id;
  final int roomId;

  final String text;
  final String type;

  final DateTime insertedAt;
  final DateTime updatedAt;

  final User? user;

  Message.fromPayload(Map payload)
      : id = payload['id'],
        roomId = payload['room_id'],
        text = payload['text'],
        type = payload['type'],
        insertedAt = DateTime.parse(payload['inserted_at']),
        updatedAt = DateTime.parse(payload['updated_at']),
        user =
            payload['user'] == null ? null : User.fromPayload(payload['user']);
}
