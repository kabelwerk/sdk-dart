//
// public models
//

/// A Kabelwerk hub.
class Hub {
  /// The hub's unique integer ID.
  final int id;

  /// The user-friendly name of the hub.
  final String name;

  /// Your unique ID for this hub.
  final String slug;

  /// Creates a hub.
  ///
  /// The payload may be:
  ///
  /// - part of an inbox item payload.
  Hub.fromPayload(Map<String, dynamic> data)
      : id = data['id'],
        name = data['name'],
        slug = data['slug'];
}

/// A Kabelwerk user.
class User {
  /// The user's unique integer ID.
  final int id;

  /// Your unique ID for this user.
  final String key;

  /// The user's name.
  final String name;

  /// Creates a user.
  ///
  /// The payload may be:
  ///
  /// - an update_user response;
  /// - a user_updated event;
  /// - part of a message payload.
  User.fromPayload(Map<String, dynamic> data)
      : id = data['id'],
        key = data['key'],
        name = data['name'];
}

/// The currently connected device.
class Device {
  /// The device's unique integer ID.
  final int id;

  /// The [Firebase registration
  /// token](https://firebase.google.com/docs/cloud-messaging) for this device.
  final String pushNotificationsToken;

  /// Whether to send push notifications to this device.
  final bool pushNotificationsEnabled;

  /// Creates a device.
  ///
  /// The payload may be:
  ///
  /// - an update_device response.
  Device.fromPayload(Map<String, dynamic> data)
      : id = data['id'],
        pushNotificationsToken = data['push_notifications_token'],
        pushNotificationsEnabled = data['push_notifications_enabled'];
}

/// The possible chat message types.
enum MessageType {
  text,
  image,
  attachment,
}

/// A chat message.
class Message {
  /// The content of the message in HTML format.
  ///
  /// This is wrapped in `<p>` tags, with newlines within paragraphs converted
  /// to `<br>` tags, and with markdown syntax already processed. HTML special
  /// characters in the original user input are escaped. You should use this
  /// field when rendering chat room messages.
  final String html;

  /// The message's unique integer ID.
  final int id;

  /// Server-side timestamp of when the message was first stored in the
  /// database.
  final DateTime insertedAt;

  /// The ID of the room to which the message belongs.
  final int roomId;

  /// The content of the message in plaintext format.
  ///
  /// This is the original user input with HTML entities escaped. You may want
  /// to use this field when rendering inbox items or notifications.
  final String text;

  /// The type of the message.
  final MessageType type;

  /// Server-side timestamp of when the message was last modified.
  ///
  /// If the message has not been edited, this will be the same as the
  /// [insertedAt] timestamp.
  final DateTime updatedAt;

  /// The associated upload if the message [type] is `image` or `attachment`.
  final Upload? upload;

  /// The user who posted the message.
  final User user;

  /// Creates a message.
  ///
  /// The payload may be:
  ///
  /// - a post_message response;
  /// - a message_posted event;
  /// - a delete_message response;
  /// - a message_deleted event;
  /// - part of an inbox item payload.
  Message.fromPayload(Map<String, dynamic> data)
      : html = data['html'],
        id = data['id'],
        insertedAt = DateTime.parse(data['inserted_at']),
        roomId = data['room_id'],
        text = data['text'],
        type = MessageType.values.byName(data['type']),
        updatedAt = DateTime.parse(data['updated_at']),
        upload = data['upload'],
        user = User.fromPayload(data['user']);
}

/// An upload.
class Upload {}

/// A marker.
///
/// A user in a non-empty chat room may also have a marker marking the message
/// last seen by them. A marker's position is expected to be updated by the
/// client (e.g. whenever the user opens a chat room with unseen messages); the
/// position is also updated automatically whenever the user posts a new
/// message in the chat room.
///
/// A user has access to up to 2 markers in a chat room: their own marker and
/// the latest hub-side marker.
///
/// Using the markers feature is optional: if you choose not to update a user's
/// markers, then you cannot take advantage of the [InboxItem.isNew] flag — the
/// flag will always be set to `true` unless the last message in the respective
/// chat room is posted by the user (markers will still be updated
/// automatically with posted messages) — but no other functionality depends on
/// this feature.
class Marker {
  /// The ID of the message which is being marked.
  final int messageId;

  /// The timestamp of when the marker was last moved.
  final DateTime updatedAt;

  /// The ID of the user who moved the marker.
  final int userId;

  /// Creates a marker.
  ///
  /// The payload may be:
  ///
  /// - a move_marker response;
  /// - a marker_moved event.
  Marker.fromPayload(Map<String, dynamic> data)
      : messageId = data['message_id'],
        updatedAt = DateTime.parse(data['updated_at']),
        userId = data['user_id'];
}

/// An inbox item.
class InboxItem {
  /// The hub to which the room belongs.
  final Hub hub;

  /// Whether the room contains at least one message which is new to the
  /// connected user.
  ///
  /// Determining whether a message is new relies on the connected user's room
  /// marker — so if you do not move markers the value will always be true
  /// unless the latest message posted in the room is authored by the user.
  final bool isNew;

  /// The latest message posted in the room. Null if the room is empty.
  final Message? message;

  /// The ID of the respective room.
  final int roomId;

  /// Creates an inbox item.
  ///
  /// The payload may be:
  ///
  /// - an inbox_updated event;
  /// - an item in a list_rooms response.
  InboxItem.fromPayload(Map<String, dynamic> data, int userId)
      : hub = Hub.fromPayload(data['room']['hub']),
        isNew = data['marked_by'].indexOf(userId) == -1,
        message = data['message'] == null
            ? null
            : Message.fromPayload(data['message']),
        roomId = data['room']['id'];
}

//
// private models
//

/// The response of a successful join of a room channel.
class RoomJoin {
  /// The room's custom attributes.
  final Map<String, dynamic> attributes;

  /// The room's ID.
  final int id;

  /// The room's markers.
  final List<Marker> markers;

  /// A list of the room's most recent messages (up to 100).
  final List<Message> messages;

  /// The room's end user.
  final User user;

  /// Creates a room join.
  RoomJoin.fromPayload(Map<String, dynamic> data)
      : attributes = data['attributes'],
        id = data['id'],
        markers = List.unmodifiable(
            data['markers'].map((item) => Marker.fromPayload(item))),
        messages = List.unmodifiable(
            data['messages'].map((item) => Message.fromPayload(item))),
        user = User.fromPayload(data['user']);
}
